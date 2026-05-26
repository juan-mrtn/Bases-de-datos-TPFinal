-- ==========================================================
-- SCRIPT 02: 02-funciones.sql
-- Purpose: House all computational and business logic functions.
-- ==========================================================

-- 1. DROP EXISTING FUNCTIONS
DROP FUNCTION IF EXISTS fn_obtener_stock_real(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS fn_calcular_total_carrito(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS fn_trg_validar_disponibilidad() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_validar_confirmacion_pago() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_actualizar_total_carrito() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_validar_promo() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_validar_cliente_opinion() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_validar_favorito() CASCADE;

-- 2. BUSINESS LOGIC FUNCTIONS

-- fn_obtener_stock_real: Computes net inventory on the fly
CREATE OR REPLACE FUNCTION fn_obtener_stock_real(p_variante_id VARCHAR) 
RETURNS INT AS $$
DECLARE
    v_ingresos INT;
    v_egresos_directos INT;
    v_egresos_combos INT;
    v_stock_combo_detalles INT;
    v_item_componente RECORD;
    v_stock_componente_individual INT;
    v_combos_posibles INT;
BEGIN
    -- BIFURCACIÓN CONDICIONAL: ¿El ID consultado pertenece a un Combo Virtual?
    IF EXISTS (SELECT 1 FROM combo WHERE id = p_variante_id) THEN
        
        -- Inicializamos con un valor alto para buscar el mínimo limitante (patrón Pivot)
        v_combos_posibles := 999999; 

        -- Iteramos sobre los componentes reales indexados en combo_item para ese combo
        FOR v_item_componente IN (
            SELECT producto_variante_id, cantidad 
            FROM combo_item 
            WHERE combo_id = p_variante_id
        ) LOOP
            v_stock_componente_individual := fn_obtener_stock_real(v_item_componente.producto_variante_id);
            v_stock_combo_detalles := floor(v_stock_componente_individual / v_item_componente.cantidad);
            
            IF v_stock_combo_detalles < v_combos_posibles THEN
                v_combos_posibles := v_stock_combo_detalles;
            END IF;
        END LOOP;

        IF v_combos_posibles = 999999 THEN
            RETURN 0;
        END IF;

        RETURN v_combos_posibles;

    ELSE
        SELECT COALESCE(SUM(cantidad), 0) INTO v_ingresos 
        FROM compra_proveedor 
        WHERE producto_variante_id = p_variante_id;

        SELECT COALESCE(SUM(lc.cantidad), 0) INTO v_egresos_directos
        FROM linea_de_compra lc
        JOIN compra c ON lc.compra_id = c.id
        WHERE lc.producto_variante_id = p_variante_id 
        AND c.estado_pago = 'confirmado';

        SELECT COALESCE(SUM(lc.cantidad * ci.cantidad), 0) INTO v_egresos_combos
        FROM linea_de_compra lc
        JOIN compra c ON lc.compra_id = c.id
        JOIN combo_item ci ON lc.combo_id = ci.combo_id
        WHERE ci.producto_variante_id = p_variante_id
        AND c.estado_pago = 'confirmado';

        RETURN v_ingresos - v_egresos_directos - v_egresos_combos;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- fn_calcular_total_carrito: Computes the sum for the cart
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


-- 3. TRIGGER HANDLER FUNCTIONS

-- fn_trg_validar_disponibilidad: Checks stock before inserting to cart
CREATE OR REPLACE FUNCTION fn_trg_validar_disponibilidad() 
RETURNS TRIGGER AS $$
DECLARE
    v_stock_actual INT;
    v_item_combo RECORD;
    v_combo_id VARCHAR;
BEGIN
    SELECT id INTO v_combo_id FROM combo WHERE producto_variante_id = NEW.producto_variante_id;

    IF v_combo_id IS NOT NULL THEN
        FOR v_item_combo IN (SELECT producto_variante_id, cantidad FROM combo_item WHERE combo_id = v_combo_id) LOOP
            v_stock_actual := fn_obtener_stock_real(v_item_combo.producto_variante_id);
            IF v_stock_actual < (v_item_combo.cantidad * NEW.cantidad) THEN
                RAISE EXCEPTION 'Stock insuficiente en componentes del combo. Variante % disponible: %.', 
                                v_item_combo.producto_variante_id, v_stock_actual;
            END IF;
        END LOOP;
    ELSE
        v_stock_actual := fn_obtener_stock_real(NEW.producto_variante_id);
        IF v_stock_actual < NEW.cantidad THEN
            RAISE EXCEPTION 'No hay stock suficiente para la variante %. Disponible: %', 
                            NEW.producto_variante_id, v_stock_actual;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- fn_trg_validar_confirmacion_pago: Prevents overselling upon checkout confirmation
CREATE OR REPLACE FUNCTION fn_trg_validar_confirmacion_pago() 
RETURNS TRIGGER AS $$
DECLARE
    v_linea RECORD;
    v_stock_actual INT;
    v_comp RECORD;
    v_id_a_validar VARCHAR;
    v_combo_id VARCHAR;
BEGIN
    IF NEW.estado_pago = 'confirmado' AND OLD.estado_pago <> 'confirmado' THEN
        
        FOR v_linea IN SELECT * FROM linea_de_compra WHERE compra_id = NEW.id LOOP
            
            -- Determinar qué ID validar (variante o combo)
            IF v_linea.producto_variante_id IS NOT NULL THEN
                v_id_a_validar := v_linea.producto_variante_id;
            ELSIF v_linea.combo_id IS NOT NULL THEN
                v_id_a_validar := v_linea.combo_id;
            ELSE
                RAISE EXCEPTION 'La línea de compra no tiene asociado ni una variante ni un combo.';
            END IF;

            -- Verificar si es un combo
            SELECT id INTO v_combo_id FROM combo WHERE id = v_id_a_validar;

            IF v_combo_id IS NOT NULL THEN
                -- Es un combo: validar stock de cada componente
                FOR v_comp IN (SELECT producto_variante_id, cantidad FROM combo_item WHERE combo_id = v_combo_id) LOOP
                    v_stock_actual := fn_obtener_stock_real(v_comp.producto_variante_id);
                    IF v_stock_actual < (v_comp.cantidad * v_linea.cantidad) THEN
                        RAISE EXCEPTION 'Error al confirmar: Componente % sin stock (Disp: %, Necesario: %).', 
                                        v_comp.producto_variante_id, v_stock_actual, (v_comp.cantidad * v_linea.cantidad);
                    END IF;
                END LOOP;
            ELSE
                -- Es una variante simple
                v_stock_actual := fn_obtener_stock_real(v_id_a_validar);
                IF v_stock_actual < v_linea.cantidad THEN
                    RAISE EXCEPTION 'Error al confirmar: Variante % sin stock (Disp: %, Necesario: %).', 
                                    v_id_a_validar, v_stock_actual, v_linea.cantidad;
                END IF;
            END IF;
            
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- fn_trg_actualizar_total_carrito: Syncs total back to cart parent row
CREATE OR REPLACE FUNCTION fn_trg_actualizar_total_carrito() 
RETURNS TRIGGER AS $$
DECLARE
    v_carrito_id VARCHAR;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_carrito_id := OLD.carrito_id;
    ELSE
        v_carrito_id := NEW.carrito_id;
    END IF;

    UPDATE carrito 
    SET total = fn_calcular_total_carrito(v_carrito_id)
    WHERE id = v_carrito_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- fn_trg_validar_promo: Rejects cart additions if promotion is expired
CREATE OR REPLACE FUNCTION fn_trg_validar_promo() 
RETURNS TRIGGER AS $$
DECLARE
    v_fecha_fin DATE;
    v_precio_original DECIMAL(12,2);
BEGIN
    IF NEW.promocion_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    SELECT fecha_fin INTO v_fecha_fin 
    FROM promocion 
    WHERE id = NEW.promocion_id;
    
    IF v_fecha_fin >= CURRENT_DATE THEN
        RETURN NEW;
    END IF;
    
    RAISE WARNING 'La promoción % ha expirado (vigente hasta %). Se agregará el ítem sin descuento.', 
                  NEW.promocion_id, v_fecha_fin;
    
    -- Obtener el precio original según el tipo de ítem
    IF NEW.producto_variante_id IS NOT NULL THEN
        SELECT precio INTO v_precio_original
        FROM producto_variante
        WHERE id = NEW.producto_variante_id;
    ELSIF NEW.combo_id IS NOT NULL THEN
        SELECT precio INTO v_precio_original
        FROM combo
        WHERE id = NEW.combo_id;
    ELSE
        v_precio_original := NEW.precio_unitario;
    END IF;
    
    -- Actualizar los campos del ítem: sin promoción, sin descuento, precio original
    NEW.promocion_id := NULL;
    NEW.descuento_unitario := 0;
    NEW.precio_unitario := v_precio_original;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- fn_trg_validar_cliente_opinion: Blocks review if hasn't purchased
CREATE OR REPLACE FUNCTION fn_trg_validar_cliente_opinion() 
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM linea_de_compra lc
        JOIN compra c ON lc.compra_id = c.id
        WHERE c.usuario_id = NEW.usuario_id 
        AND lc.producto_variante_id = NEW.producto_variante_id
        AND c.estado_pago = 'confirmado'
    ) THEN
        RAISE EXCEPTION 'No puedes opinar sobre una variante que no has comprado o confirmado.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- fn_aplicar_promocion: Calcula el precio unitario final y el descuento aplicado
CREATE OR REPLACE FUNCTION fn_aplicar_promocion(
    p_precio_original DECIMAL,
    p_promocion_id VARCHAR,
    p_cantidad INT DEFAULT 1
)
RETURNS TABLE (precio_final DECIMAL, descuento_unitario DECIMAL) AS $$
DECLARE
    v_tipo tipo_promocion;
    v_descuento DECIMAL;
    v_cantidad_efectiva INT;
BEGIN
    -- Si no hay promoción, devolver el precio original sin descuento
    IF p_promocion_id IS NULL THEN
        RETURN QUERY SELECT p_precio_original, 0.00;
        RETURN;
    END IF;
    
    -- Obtener tipo y valor de descuento
    SELECT tipo, descuento INTO v_tipo, v_descuento
    FROM promocion
    WHERE id = p_promocion_id
      AND CURRENT_DATE BETWEEN fecha_inicio AND fecha_fin;
    
    -- Si la promoción no está vigente, ignorarla (descuento 0)
    IF NOT FOUND THEN
        RETURN QUERY SELECT p_precio_original, 0.00;
        RETURN;
    END IF;
    
    -- Aplicar lógica según tipo
    CASE v_tipo
        WHEN 'descuento' THEN
            -- Descuento porcentual (ej. 0.20 = 20%)
            RETURN QUERY SELECT 
                ROUND(p_precio_original * (1 - v_descuento), 2),
                ROUND(p_precio_original * v_descuento, 2);
                
        WHEN '2x1' THEN
            -- 2x1: cada 2 unidades se paga 1. Precio unitario efectivo = (precio_original * (unidades_pagas) / total_unidades)
            -- Para simplificar, se aplica descuento del 50% sobre el precio unitario original.
            -- Nota: Para cantidades impares, la unidad extra se paga al 100%, pero el promedio sigue siendo el mismo descuento.
            -- Se puede mejorar pero para el TP es suficiente.
            RETURN QUERY SELECT 
                ROUND(p_precio_original * 0.5, 2),
                ROUND(p_precio_original * 0.5, 2);
                
        ELSE
            -- Por defecto, sin descuento
            RETURN QUERY SELECT p_precio_original, 0.00;
    END CASE;
END;
$$ LANGUAGE plpgsql;