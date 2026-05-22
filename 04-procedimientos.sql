-- ==========================================================
-- SCRIPT 04: 04-procedimientos.sql
-- Purpose: Store procedural transaction blocks executing multi-table mutations on demand.
-- ==========================================================

-- 1. DROP EXISTING PROCEDURES
DROP PROCEDURE IF EXISTS sp_finalizar_compra(VARCHAR, VARCHAR) CASCADE;
DROP PROCEDURE IF EXISTS sp_registrar_ingreso_stock(VARCHAR, VARCHAR, VARCHAR, INT, DECIMAL) CASCADE;

-- 2. STORED PROCEDURES DEFINITION

-- sp_finalizar_compra: Concludes open cart, creates compra, moves items, zeroes cart, updates state
CREATE OR REPLACE PROCEDURE sp_finalizar_compra(
    p_usuario_id VARCHAR,
    p_carrito_id VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_compra_id VARCHAR := 'CMP-' || CAST(floor(random() * 100000) AS VARCHAR);
    v_total_carrito DECIMAL;
    v_item RECORD;
BEGIN
    -- 1. Get accumulated cart total
    SELECT total INTO v_total_carrito FROM carrito WHERE id = p_carrito_id;

    -- 2. Create header (status 'procesando')
    INSERT INTO compra (id, usuario_id, numero, fecha, total, estado_pago)
    VALUES (
        v_compra_id, 
        p_usuario_id, 
        'N-' || CAST(floor(random() * 1000000) AS VARCHAR), 
        CURRENT_TIMESTAMP, 
        v_total_carrito, 
        'procesando'
    );

    -- 3. Move items from cart to order lines
    FOR v_item IN SELECT * FROM carrito_item WHERE carrito_id = p_carrito_id LOOP
        INSERT INTO linea_de_compra (id, compra_id, producto_variante_id, cantidad, precio_unitario)
        VALUES (
            'LC-' || v_compra_id || '-' || v_item.producto_variante_id, 
            v_compra_id, 
            v_item.producto_variante_id, 
            v_item.cantidad, 
            v_item.precio_unitario
        );
    END LOOP;

    -- 4. Clean up cart and toggle state to 'confirmado'
    UPDATE carrito SET total = 0, estado = 'confirmado' WHERE id = p_carrito_id;
    DELETE FROM carrito_item WHERE carrito_id = p_carrito_id;

    RAISE NOTICE 'Compra % generada exitosamente.', v_compra_id;
END;
$$;


-- sp_registrar_ingreso_stock: Matches user-friendly params to validate and log receipt
CREATE OR REPLACE PROCEDURE sp_registrar_ingreso_stock(
    p_nombre_producto VARCHAR,
    p_talle VARCHAR,
    p_proveedor_id VARCHAR,
    p_cantidad INT,
    p_costo_unitario DECIMAL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_variante_id VARCHAR;
BEGIN
    -- Find matching internal variant ID
    SELECT pv.id INTO v_variante_id
    FROM producto_variante pv
    JOIN producto p ON pv.producto_id = p.id
    WHERE p.nombre = p_nombre_producto AND pv.talle = p_talle;

    IF v_variante_id IS NULL THEN
        RAISE EXCEPTION 'Variante no encontrada para % en talle %', p_nombre_producto, p_talle;
    END IF;

    -- Log receipt in compra_proveedor
    INSERT INTO compra_proveedor (id, proveedor_id, producto_variante_id, cantidad, costo, fecha)
    VALUES (
        'CP-' || CAST(floor(random() * 100000) AS VARCHAR), 
        p_proveedor_id, 
        v_variante_id, 
        p_cantidad, 
        p_costo_unitario, 
        CURRENT_DATE
    );
END;
$$;

CREATE OR REPLACE PROCEDURE sp_agregar_al_carrito(
    p_carrito_id VARCHAR,
    p_producto_variante_id VARCHAR,
    p_cantidad INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_precio_unitario DECIMAL;
    v_existe_item INT;
BEGIN
    SELECT precio INTO v_precio_unitario 
    FROM producto_variante 
    WHERE id = p_producto_variante_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El producto variante % no existe.', p_producto_variante_id;
    END IF;

    SELECT count(*) INTO v_existe_item 
    FROM carrito_item 
    WHERE carrito_id = p_carrito_id AND producto_variante_id = p_producto_variante_id;

    IF v_existe_item > 0 THEN
        UPDATE carrito_item 
        SET cantidad = cantidad + p_cantidad
        WHERE carrito_id = p_carrito_id AND producto_variante_id = p_producto_variante_id;
    ELSE
        INSERT INTO carrito_item (id, carrito_id, producto_variante_id, cantidad, precio_unitario, descuento_unitario)
        VALUES (gen_random_uuid(), p_carrito_id, p_producto_variante_id, p_cantidad, v_precio_unitario, 0);
    END IF;

END;
$$;

CREATE OR REPLACE PROCEDURE sp_confirmar_pago(
    p_usuario_id VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_compra_id VARCHAR;
    v_estado_actual estado_pago;
BEGIN
    -- 1. Buscar de forma automática la última compra en proceso del usuario
    SELECT id, estado_pago INTO v_compra_id, v_estado_actual
    FROM compra
    WHERE usuario_id = p_usuario_id AND estado_pago = 'procesando'
    ORDER BY fecha DESC
    LIMIT 1;

    -- 2. Validar que efectivamente exista una orden pendiente de pago
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró ninguna compra pendiente de pago (estado ''procesando'') para el usuario %.', p_usuario_id;
    END IF;

    -- 3. Actualizar el estado de pago de forma segura
    -- Nota: Al pasar a 'confirmado', se ejecutará automáticamente el trigger
    -- 'trg_compra_validar_stock_final' para re-verificar el stock en tiempo real.
    UPDATE compra 
    SET estado_pago = 'confirmado' 
    WHERE id = v_compra_id;

    RAISE NOTICE 'Pago de la compra % confirmado exitosamente.', v_compra_id;
END;
$$;