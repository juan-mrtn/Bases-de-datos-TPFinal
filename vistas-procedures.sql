-- ==========================================================
-- 1. VISTA: Stock Actual de Productos (Cálculo en Tiempo Real)
-- ==========================================================
-- Esta vista reemplaza la columna física 'stock'. 
-- Resta compras confirmadas (individuales y combos) a los ingresos de proveedores.

CREATE OR REPLACE VIEW v_stock_actual AS
WITH stock_base AS (
    -- Calculamos el stock físico real de cada variante individual
    SELECT 
        pv.id AS producto_variante_id,
        COALESCE((SELECT SUM(cantidad) FROM compra_proveedor WHERE producto_variante_id = pv.id), 0) -
        COALESCE((
            SELECT SUM(lc.cantidad) 
            FROM linea_de_compra lc
            JOIN compra c ON lc.compra_id = c.id
            WHERE lc.producto_variante_id = pv.id AND c.estado_pago = 'confirmado'
        ), 0) AS disponible
    FROM producto_variante pv
)
SELECT 
    sb.producto_variante_id,
    CASE 
        -- Si la variante es un representante de COMBO
        WHEN EXISTS (SELECT 1 FROM "combo" WHERE producto_variante_id = sb.producto_variante_id) THEN
            (
                SELECT MIN(sb_comp.disponible / ci.cantidad)
                FROM "combo_item" ci
                JOIN stock_base sb_comp ON ci.producto_variante_id = sb_comp.producto_variante_id
                WHERE ci.combo_id = (SELECT id FROM "combo" WHERE producto_variante_id = sb.producto_variante_id)
            )
        -- Si es un producto normal
        ELSE sb.disponible
    END AS stock_disponible
FROM stock_base sb;

-- ==========================================================
-- 2. VISTA: Catálogo para el Usuario (Usa la vista de stock)
-- ==========================================================
CREATE OR REPLACE VIEW v_catalogo_publico AS
SELECT 
    p.nombre AS producto,
    pv.precio,
    pv.talle,
    pv.material,
    CASE 
        WHEN s.stock_disponible > 0 THEN 'Disponible' 
        ELSE 'Sin Stock' 
    END AS estado_disponibilidad
FROM producto_variante pv
JOIN producto p ON pv.producto_id = p.id
JOIN v_stock_actual s ON pv.id = s.producto_variante_id;

-- ==========================================================
-- 3. STORED PROCEDURE: Finalizar Compra
-- ==========================================================
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
    -- 1. Obtener el total acumulado en el carrito
    SELECT total INTO v_total_carrito FROM carrito WHERE id = p_carrito_id;

    -- 2. Crear la cabecera de la compra (Estado inicial: 'inactivo')
    INSERT INTO compra (id, usuario_id, fecha, total, estado_pago)
    VALUES (v_compra_id, p_usuario_id, CURRENT_TIMESTAMP, v_total_carrito, 'inactivo');

    -- 3. Mover todos los ítems del Carrito a la Línea de Compra
    FOR v_item IN SELECT * FROM carrito_item WHERE carrito_id = p_carrito_id LOOP
        INSERT INTO linea_de_compra (id, compra_id, producto_variante_id, combo_id, cantidad, precio_unitario)
        VALUES (
            'LC-' || v_compra_id || '-' || COALESCE(v_item.producto_variante_id, v_item.combo_id), 
            v_compra_id, 
            v_item.producto_variante_id, 
            v_item.combo_id, 
            v_item.cantidad, 
            v_item.precio_unitario
        );
    END LOOP;

    -- 4. Limpieza: Se confirma el carrito y se vacían sus ítems
    UPDATE carrito SET total = 0, estado = 'confirmado' WHERE id = p_carrito_id;
    DELETE FROM carrito_item WHERE carrito_id = p_carrito_id;

    RAISE NOTICE 'Compra % generada exitosamente. Pendiente de confirmación de pago.', v_compra_id;
END;
$$;

-- ==========================================================
-- 1. VISTA: Stock Actual de Productos (Corregida)
-- ==========================================================
CREATE OR REPLACE VIEW v_stock_actual AS
SELECT 
    id AS producto_variante_id,
    fn_obtener_stock_real(id) AS stock_disponible
FROM producto_variante;

-- ==========================================================
-- 3. STORED PROCEDURE: Finalizar Compra
-- ==========================================================
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
    -- 1. Obtener el total acumulado en el carrito
    SELECT total INTO v_total_carrito FROM carrito WHERE id = p_carrito_id;

    -- 2. Crear la cabecera de la compra (Estado inicial: 'pendiente' o 'inactivo')
    -- Nota: Usamos 'pendiente' para que sea consistente con los triggers
    INSERT INTO compra (id, usuario_id, fecha, total, estado_pago)
    VALUES (v_compra_id, p_usuario_id, CURRENT_TIMESTAMP, v_total_carrito, 'procesando');

    -- 3. Mover todos los ítems del Carrito a la Línea de Compra
    FOR v_item IN SELECT * FROM carrito_item WHERE carrito_id = p_carrito_id LOOP
        -- Eliminamos combo_id de la lista de columnas y del COALESCE
        INSERT INTO linea_de_compra (id, compra_id, producto_variante_id, cantidad, precio_unitario)
        VALUES (
            'LC-' || v_compra_id || '-' || v_item.producto_variante_id, 
            v_compra_id, 
            v_item.producto_variante_id, 
            v_item.cantidad, 
            v_item.precio_unitario
        );
    END LOOP;

    -- 4. Limpieza: Se confirma el carrito y se vacían sus ítems
    UPDATE carrito SET total = 0, estado = 'confirmado' WHERE id = p_carrito_id;
    DELETE FROM carrito_item WHERE carrito_id = p_carrito_id;

    RAISE NOTICE 'Compra % generada exitosamente. Pendiente de confirmación de pago.', v_compra_id;
END;
$$;

-- probamos el Stored Procedure sp_finalizar_compra y el Trigger de confirmación.

CALL sp_finalizar_compra('U02', 'C01');

-- Revisa que la tabla compra tenga un registro nuevo en estado 'pendiente' y linea_de_compra

-- Ahora, para confirmar el pago y que el trigger trg_compra_validar_stock_final se dispare (y así descuente el stock virtualmente)
UPDATE compra 
SET estado_pago = 'confirmado' 
WHERE usuario_id = 'U02' AND estado_pago = 'procesando';

-- ==========================================================
-- 4. VISTA: Detalle del Carrito
-- ==========================================================

CREATE OR REPLACE VIEW v_carrito_detalle AS
SELECT 
    c.id AS carrito_id,
    c.usuario_id,
    u.email AS usuario_email, -- Agregamos el email para que sea más informativo
    c.estado AS estado_carrito,
    ci.producto_variante_id,
    p.nombre AS producto,
    pv.talle,
    pv.material,
    ci.cantidad,
    ci.precio_unitario,
    (ci.cantidad * ci.precio_unitario) AS subtotal_item,
    c.total AS total_acumulado_carrito
FROM carrito c
JOIN usuario u ON c.usuario_id = u.id
JOIN carrito_item ci ON c.id = ci.carrito_id
JOIN producto_variante pv ON ci.producto_variante_id = pv.id
JOIN producto p ON pv.producto_id = p.id;