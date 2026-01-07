-- ==========================================================
-- 1. VISTA: Stock Actual de Productos (Cálculo en Tiempo Real)
-- ==========================================================
-- Esta vista reemplaza la columna física 'stock'. 
-- Resta compras confirmadas (individuales y combos) a los ingresos de proveedores.

CREATE OR REPLACE VIEW v_stock_actual AS
SELECT 
    pv.id AS producto_variante_id,
    (
        -- Ingresos totales desde proveedores
        COALESCE((SELECT SUM(cp.cantidad) FROM compra_proveedor cp WHERE cp.producto_variante_id = pv.id), 0) 
        - 
        -- Egresos por ventas individuales confirmadas
        COALESCE((SELECT SUM(lc.cantidad) FROM linea_de_compra lc 
                  JOIN compra c ON lc.compra_id = c.id 
                  WHERE lc.producto_variante_id = pv.id AND c.estado_pago = 'confirmado'), 0)
        -
        -- Egresos por ventas de combos confirmadas (desglose de componentes)
        COALESCE((SELECT SUM(lc.cantidad * ci.cantidad) FROM linea_de_compra lc
                  JOIN compra c ON lc.compra_id = c.id
                  JOIN "ComboItem" ci ON lc.combo_id = ci.combo_id
                  WHERE ci.producto_variante_id = pv.id AND c.estado_pago = 'confirmado'), 0)
    ) AS stock_disponible
FROM producto_variante pv;

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
JOIN v_stock_actual s ON pv.id = s.producto_variante_id; -- Unión con la vista de cálculo

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