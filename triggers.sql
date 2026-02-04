-- ==========================================================
-- 1. FUNCIÓN AUXILIAR: Cálculo de Stock en Tiempo Real
-- ==========================================================
-- Esta función hace la cuenta: (Suma Ingresos Proveedor) - (Suma Ventas Confirmadas)
-- También considera los componentes de los combos vendidos.

CREATE OR REPLACE FUNCTION fn_obtener_stock_real(p_variante_id VARCHAR) 
RETURNS INT AS $$
DECLARE
    v_ingresos INT;
    v_egresos_directos INT;
    v_egresos_combos INT;
BEGIN
    -- 1. Total ingresado por proveedores
    SELECT COALESCE(SUM(cantidad), 0) INTO v_ingresos 
    FROM compra_proveedor 
    WHERE producto_variante_id = p_variante_id;

    -- 2. Total vendido como producto individual (Ventas confirmadas)
    SELECT COALESCE(SUM(lc.cantidad), 0) INTO v_egresos_directos
    FROM linea_de_compra lc
    JOIN compra c ON lc.compra_id = c.id
    WHERE lc.producto_variante_id = p_variante_id 
    AND c.estado_pago = 'confirmado';

    -- 3. Total vendido dentro de COMBOS (Ventas confirmadas)
    -- Buscamos si la variante de la línea de compra pertenece a un combo
    SELECT COALESCE(SUM(lc.cantidad * ci.cantidad), 0) INTO v_egresos_combos
    FROM linea_de_compra lc
    JOIN compra c ON lc.compra_id = c.id
    -- Unimos la línea de compra con la tabla combo a través de la variante representante
    JOIN combo co ON lc.producto_variante_id = co.producto_variante_id
    -- Unimos con los ítems del combo para saber qué componentes tiene
    JOIN combo_item ci ON co.id = ci.combo_id
    WHERE ci.producto_variante_id = p_variante_id
    AND c.estado_pago = 'confirmado';

    RETURN v_ingresos - v_egresos_directos - v_egresos_combos;
END;
$$ LANGUAGE plpgsql;

-- ==========================================================
-- 2. TRIGGER: Validación de Stock antes de agregar al Carrito
-- ==========================================================
-- Bloquea la inserción si el cálculo de la función anterior es insuficiente.

CREATE OR REPLACE FUNCTION fn_trg_validar_disponibilidad() 
RETURNS TRIGGER AS $$
DECLARE
    v_stock_actual INT;
    v_item_combo RECORD;
    v_combo_id VARCHAR;
BEGIN
    -- Buscamos si la variante que se intenta agregar es un COMBO
    SELECT id INTO v_combo_id FROM combo WHERE producto_variante_id = NEW.producto_variante_id;

    -- CASO A: Es un Combo (v_combo_id no es nulo)
    IF v_combo_id IS NOT NULL THEN
        FOR v_item_combo IN (SELECT producto_variante_id, cantidad FROM combo_item WHERE combo_id = v_combo_id) LOOP
            v_stock_actual := fn_obtener_stock_real(v_item_combo.producto_variante_id);
            IF v_stock_actual < (v_item_combo.cantidad * NEW.cantidad) THEN
                RAISE EXCEPTION 'Stock insuficiente en componentes del combo. La variante % solo tiene % unidades.', 
                                v_item_combo.producto_variante_id, v_stock_actual;
            END IF;
        END LOOP;

    -- CASO B: Es un producto individual
    ELSE
        v_stock_actual := fn_obtener_stock_real(NEW.producto_variante_id);
        IF v_stock_actual < NEW.cantidad THEN
            RAISE EXCEPTION 'No hay stock suficiente para el producto %. Disponible: %', 
                            NEW.producto_variante_id, v_stock_actual;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_carrito_item_valida_stock
BEFORE INSERT OR UPDATE ON carrito_item
FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_disponibilidad();

-- ==========================================================
-- TRIGGER: trg_validar_stock_antes_de_confirmar
-- ==========================================================
-- Reemplaza la reducción física de stock. 
-- Valida que al momento de confirmar el pago, todavía exista mercadería.

CREATE OR REPLACE FUNCTION fn_trg_validar_confirmacion_pago() 
RETURNS TRIGGER AS $$
DECLARE
    v_linea RECORD;
    v_stock_actual INT;
    v_comp RECORD;
    v_combo_id VARCHAR;
BEGIN
    IF NEW.estado_pago = 'confirmado' AND OLD.estado_pago <> 'confirmado' THEN
        
        FOR v_linea IN SELECT * FROM linea_de_compra WHERE compra_id = NEW.id LOOP
            
            -- Verificamos si esta línea de compra es un combo
            SELECT id INTO v_combo_id FROM combo WHERE producto_variante_id = v_linea.producto_variante_id;

            IF v_combo_id IS NOT NULL THEN
                -- Es un Combo: Validamos sus componentes
                FOR v_comp IN (SELECT producto_variante_id, cantidad FROM combo_item WHERE combo_id = v_combo_id) LOOP
                    v_stock_actual := fn_obtener_stock_real(v_comp.producto_variante_id);
                    IF v_stock_actual < (v_comp.cantidad * v_linea.cantidad) THEN
                        RAISE EXCEPTION 'No se puede confirmar la compra. El componente % del combo no tiene stock suficiente.', 
                                        v_comp.producto_variante_id;
                    END IF;
                END LOOP;
            ELSE
                -- Es producto individual: Validamos su stock
                v_stock_actual := fn_obtener_stock_real(v_linea.producto_variante_id);
                IF v_stock_actual < v_linea.cantidad THEN
                    RAISE EXCEPTION 'No se puede confirmar la compra. El producto % se quedó sin stock (Disponible: %)', 
                                    v_linea.producto_variante_id, v_stock_actual;
                END IF;
            END IF;
            
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_compra_validar_stock_final
BEFORE UPDATE OF estado_pago ON compra
FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_confirmacion_pago();


-- Esta función simplemente suma los subtotales (cantidad * precio_unitario) de los ítems asociados a un carrito.
CREATE OR REPLACE FUNCTION fn_calcular_total_carrito(p_carrito_id VARCHAR) 
RETURNS DECIMAL AS $$
DECLARE
    v_total DECIMAL;
BEGIN
    SELECT COALESCE(SUM(cantidad * precio_unitario), 0) INTO v_total
    FROM carrito_item
    WHERE carrito_id = p_carrito_id;
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Trigger que actualiza el total del carrito cada vez que se inserta, actualiza o elimina un ítem.
-- Para que el campo total de la tabla carrito esté siempre actualizado, creamos un trigger que se dispare cada vez que agregas, borras o modificas un ítem en carrito_item.
CREATE OR REPLACE FUNCTION fn_trg_actualizar_total_carrito() 
RETURNS TRIGGER AS $$
DECLARE
    v_carrito_id VARCHAR;
BEGIN
    -- Identificamos el ID del carrito afectado (funciona para INSERT, UPDATE y DELETE)
    IF (TG_OP = 'DELETE') THEN
        v_carrito_id := OLD.carrito_id;
    ELSE
        v_carrito_id := NEW.carrito_id;
    END IF;

    -- Actualizamos el total en la tabla padre (carrito)
    UPDATE carrito 
    SET total = fn_calcular_total_carrito(v_carrito_id)
    WHERE id = v_carrito_id;

    RETURN NULL; -- En triggers AFTER el valor de retorno no afecta a la fila
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_total_carrito
AFTER INSERT OR UPDATE OR DELETE ON carrito_item
FOR EACH ROW EXECUTE FUNCTION fn_trg_actualizar_total_carrito();