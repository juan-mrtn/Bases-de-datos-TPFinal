-- ==========================================================
-- SCRIPT 03: 03-vistas.sql
-- Purpose: Create optimized data abstraction layers for frontend consumption.
-- ==========================================================

-- 1. DROP EXISTING VIEWS
DROP VIEW IF EXISTS v_producto_detalle CASCADE;
DROP VIEW IF EXISTS v_carrito_detalle CASCADE;
DROP VIEW IF EXISTS v_catalogo_publico CASCADE;
DROP VIEW IF EXISTS v_stock_actual CASCADE;

-- 2. VIEWS DEFINITION

-- v_stock_actual: Maps every variant ID to the live integer output
CREATE OR REPLACE VIEW v_stock_actual AS
SELECT 
    id AS producto_variante_id,
    fn_obtener_stock_real(id) AS stock_disponible
FROM producto_variante;


-- v_catalogo_publico: Groups items by base product, hides numeric quantities
CREATE OR REPLACE VIEW v_catalogo_publico AS
SELECT 
    p.id AS producto_id,
    p.nombre AS producto,
    
    -- Priority: 0 if available, 1 if out of stock
    CASE 
        WHEN COALESCE(SUM(s.stock_disponible), 0) > 0 THEN 0 
        ELSE 1 
    END AS prioridad,
    
    -- Status String
    CASE 
        WHEN COALESCE(SUM(s.stock_disponible), 0) > 0 THEN 'Disponible' 
        ELSE 'Sin Stock' 
    END AS estado_disponibilidad

FROM producto p
LEFT JOIN producto_variante pv ON p.id = pv.producto_id
LEFT JOIN v_stock_actual s ON pv.id = s.producto_variante_id
GROUP BY p.id, p.nombre;


-- v_carrito_detalle: Flat view displaying clear rows with item subtotals
CREATE OR REPLACE VIEW v_carrito_detalle AS
SELECT 
    c.id AS carrito_id,
    c.usuario_id,
    u.email AS usuario_email,
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


-- v_producto_detalle: Structured data for item pages with Array aggregation
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
    
    -- Secondary picture URLs into a single array
    COALESCE(ARRAY_AGG(i.url_imagen) FILTER (WHERE i.url_imagen IS NOT NULL), '{}') AS galeria_imagenes,
    
    -- Safely chain active promotions
    promo.tipo AS tipo_promocion,
    promo.descuento AS valor_descuento

FROM producto_variante pv
JOIN producto p ON pv.producto_id = p.id
LEFT JOIN imagen i ON pv.id = i.producto_variante_id
LEFT JOIN promocion promo ON pv.promocion_id = promo.id 
    AND CURRENT_DATE BETWEEN promo.fecha_inicio AND promo.fecha_fin
    
GROUP BY 
    pv.id, p.id, p.nombre, p.descripcion, p.codigo, pv.precio, 
    pv.material, pv.talle, pv.color, pv.imagen_url, 
    promo.tipo, promo.descuento;
