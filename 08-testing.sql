-- ==========================================================
-- SCRIPT 08: 08-testing.sql
-- ==========================================================

BEGIN;

-- 1. SIMULACIÓN TRANSACCIONAL (Camino Feliz)
-- Creamos un carrito para el cliente Facundo (U02)
INSERT INTO carrito (id, usuario_id, total, estado) VALUES 
('C01', 'U02', 0, 'abierto');

-- Agregamos productos al carrito (Los triggers validarán stock y actualizarán el total automáticamente)
INSERT INTO carrito_item (id, carrito_id, producto_variante_id, cantidad, precio_unitario) VALUES 
('CI01', 'C01', 'V1-B-M', 2, 25000),
('CI02', 'C01', 'V9-RB-M', 1, 12000);

-- Ejecutamos el procedimiento para finalizar la compra
CALL sp_finalizar_compra('U02', 'C01');

-- Confirmamos el pago (Dispara la validación final de stock antes de confirmar)
UPDATE compra 
SET estado_pago = 'confirmado' 
WHERE usuario_id = 'U02' AND estado_pago = 'procesando';

-- 2. VALIDACIÓN DE OPINIONES
-- Escribimos una reseña post-compra para disparar y testear los checks de integridad (solo clientes que compraron)
INSERT INTO opinion (id, usuario_id, producto_variante_id, estrellas, comentario) VALUES
('OP-001', 'U02', 'V1-B-M', 5, 'Excelente calidad, el talle M me quedó perfecto.');

COMMIT;
