
-- ==========================================================
-- 1. VISTA: Stock Actual de Productos
-- ==========================================================
CREATE OR REPLACE VIEW v_stock_actual AS
SELECT 
    id AS producto_variante_id,
    fn_obtener_stock_real(id) AS stock_disponible
FROM producto_variante;

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
-- 2. VISTA: Catálogo para el Usuario (Evolucionada para el Grid)
-- ==========================================================
CREATE OR REPLACE VIEW v_catalogo_publico AS
SELECT 
    p.id AS producto_id,
    p.nombre AS producto,
    
    -- Sumamos el stock de todas las variantes (usando tu vista v_stock_actual)
    COALESCE(SUM(s.stock_disponible), 0) AS stock_total,
    
    -- El orden prioritario (0 = con stock, 1 = al fondo)
    CASE 
        WHEN COALESCE(SUM(s.stock_disponible), 0) > 0 THEN 0 
        ELSE 1 
    END AS prioridad,
    
    -- Mantenemos tu columna original intacta, pero evaluando el total
    CASE 
        WHEN COALESCE(SUM(s.stock_disponible), 0) > 0 THEN 'Disponible' 
        ELSE 'Sin Stock' 
    END AS estado_disponibilidad

FROM producto p
LEFT JOIN producto_variante pv ON p.id = pv.producto_id
LEFT JOIN v_stock_actual s ON pv.id = s.producto_variante_id
GROUP BY p.id, p.nombre;
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

-- ==========================================================
-- 5. VISTA: Registro de Compras a Proveedores
-- ==========================================================

-- "Este procedimiento responde a la necesidad de gestión de inventario por parte del administrador, permitiendo el ingreso de mercadería de forma intuitiva
-- mediante parámetros de negocio (Nombre y Talle) en lugar de claves técnicas (IDs), garantizando la trazabilidad de la entrada de stock."

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
    -- Buscar la variante correspondiente
    SELECT pv.id INTO v_variante_id
    FROM producto_variante pv
    JOIN producto p ON pv.producto_id = p.id
    WHERE p.nombre = p_nombre_producto AND pv.talle = p_talle;

    IF v_variante_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró la variante para % en talle %', p_nombre_producto, p_talle;
    END IF;

    -- Insertar el registro de compra al proveedor
    INSERT INTO compra_proveedor (id, proveedor_id, producto_variante_id, cantidad, costo, fecha)
    VALUES ('CP-'||CAST(floor(random()*100000) AS VARCHAR), p_proveedor_id, v_variante_id, p_cantidad, p_costo_unitario, CURRENT_DATE);
END;
$$;

-- ==========================================================
-- VISTA 6: Detalle de Producto (Para la página individual)
-- ==========================================================
CREATE OR REPLACE VIEW v_producto_detalle AS
SELECT 
    pv.id AS variante_id,
    p.id AS producto_id,
    p.nombre,
    p.descripcion,
    p.codigo,
    pv.precio,
    pv.material,
    pv.talle,
    pv.color,
    pv.imagen_url AS imagen_principal,
    fn_obtener_stock_real(pv.id) AS stock_disponible,
    
    -- Agrupamos todas las fotos de la galería en una lista (Array) de PostgreSQL
    COALESCE(ARRAY_AGG(i.url_imagen) FILTER (WHERE i.url_imagen IS NOT NULL), '{}') AS galeria_imagenes,
    
    -- Traemos datos de promoción solo si está vigente el día de hoy
    promo.tipo AS tipo_promocion,
    promo.descuento AS valor_descuento

FROM producto_variante pv
JOIN producto p ON pv.producto_id = p.id
LEFT JOIN imagen i ON pv.id = i.producto_variante_id
LEFT JOIN promocion promo ON pv.promocion_id = promo.id 
    AND CURRENT_DATE BETWEEN promo.fecha_inicio AND promo.fecha_fin
    
-- Como usamos ARRAY_AGG (función de agregación), debemos agrupar por el resto de las columnas
GROUP BY 
    pv.id, p.id, p.nombre, p.descripcion, p.codigo, pv.precio, 
    pv.material, pv.talle, pv.color, pv.imagen_url, 
    promo.tipo, promo.descuento;
--Se utiliza: SELECT * FROM v_producto_detalle WHERE variante_id = 'V1-B-M';