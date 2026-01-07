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
    -- Buscamos en LineaDeCompra los combos y miramos en ComboItem cuántas unidades de esta variante traían
    SELECT COALESCE(SUM(lc.cantidad * ci.cantidad), 0) INTO v_egresos_combos
    FROM linea_de_compra lc
    JOIN compra c ON lc.compra_id = c.id
    JOIN "ComboItem" ci ON lc.combo_id = ci.combo_id
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
BEGIN
    -- CASO A: El usuario agrega un producto individual
    IF NEW.producto_variante_id IS NOT NULL THEN
        v_stock_actual := fn_obtener_stock_real(NEW.producto_variante_id);
        IF v_stock_actual < NEW.cantidad THEN
            RAISE EXCEPTION 'No hay stock suficiente para el producto %. Disponible: %', 
                            NEW.producto_variante_id, v_stock_actual;
        END IF;

    -- CASO B: El usuario agrega un Combo
    ELSIF NEW.combo_id IS NOT NULL THEN
        -- Debemos validar cada componente del combo
        FOR v_item_combo IN (SELECT producto_variante_id, cantidad FROM "ComboItem" WHERE combo_id = NEW.combo_id) LOOP
            v_stock_actual := fn_obtener_stock_real(v_item_combo.producto_variante_id);
            IF v_stock_actual < (v_item_combo.cantidad * NEW.cantidad) THEN
                RAISE EXCEPTION 'Stock insuficiente en componentes del combo. La variante % solo tiene % unidades.', 
                                v_item_combo.producto_variante_id, v_stock_actual;
            END IF;
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_carrito_item_valida_stock
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
BEGIN
    -- Se dispara solo cuando el pago pasa a ser 'confirmado'
    IF NEW.estado_pago = 'confirmado' AND OLD.estado_pago <> 'confirmado' THEN
        
        -- Recorremos cada ítem de la compra que se quiere confirmar
        FOR v_linea IN SELECT * FROM linea_de_compra WHERE compra_id = NEW.id LOOP
            
            -- 1. Si es producto individual
            IF v_linea.producto_variante_id IS NOT NULL THEN
                v_stock_actual := fn_obtener_stock_real(v_linea.producto_variante_id);
                IF v_stock_actual < v_linea.cantidad THEN
                    RAISE EXCEPTION 'No se puede confirmar la compra. El producto % se quedó sin stock (Disponible: %)', 
                                    v_linea.producto_variante_id, v_stock_actual;
                END IF;

            -- 2. Si es un Combo
            ELSIF v_linea.combo_id IS NOT NULL THEN
                FOR v_comp IN (SELECT producto_variante_id, cantidad FROM "ComboItem" WHERE combo_id = v_linea.combo_id) LOOP
                    v_stock_actual := fn_obtener_stock_real(v_comp.producto_variante_id);
                    IF v_stock_actual < (v_comp.cantidad * v_linea.cantidad) THEN
                        RAISE EXCEPTION 'No se puede confirmar la compra. Un componente del combo (%) no tiene stock suficiente.', 
                                        v_comp.producto_variante_id;
                    END IF;
                END LOOP;
            END IF;
            
        END LOOP;
    END IF;

    -- Si pasó todas las validaciones, permitimos el cambio de estado.
    -- Al ser 'confirmado', la función fn_obtener_stock_real ahora incluirá esta compra 
    -- en la resta, haciendo que el stock baje "virtualmente" para el resto del sistema.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_compra_validar_stock_final
BEFORE UPDATE OF estado_pago ON compra
FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_confirmacion_pago();
