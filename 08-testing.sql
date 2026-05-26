-- ==========================================================
-- SCRIPT 08: 08-testing.sql
-- Purpose: Protocolo de pruebas integrado con SPs de negocio
-- ==========================================================
rollback;
BEGIN;

-- 1. LIMPIEZA PREVENTIVA: Aseguramos un entorno limpio y vaciamos tablas operativas
TRUNCATE TABLE opinion, compra, linea_de_compra, carrito_item, carrito RESTART IDENTITY CASCADE;

-- 2. INICIALIZACIÓN: Apertura del carrito para el cliente Facundo (U02)
INSERT INTO carrito (id, usuario_id, total, estado) VALUES 
('C01', 'U02', 0, 'abierto');

-- 3. CARGA DE PRODUCTOS: Uso del primer procedimiento almacenado
CALL sp_agregar_al_carrito('C01', 'V1-B-M', 2, FALSE);
CALL sp_agregar_al_carrito('C01', 'V9-RB-M', 1, FALSE);

-- 4. CHECKOUT: Cierre de la orden y migración atómica de ítems
CALL sp_finalizar_compra('U02', 'C01');

-- 5. CONFIRMACIÓN DE PAGO: Uso del segundo procedimiento almacenado
CALL sp_confirmar_pago('U02');

-- 6. RESEÑA POST-COMPRA: Uso del tercer procedimiento almacenado con ID aleatorio automático
-- La base de datos autogestiona el identificador y audita los accesos de forma interna
CALL sp_dejar_opinion('U02', 'V1-B-M', 5, 'Excelente calidad, el talle es perfecto y el ID aleatorio funciona genial.');

COMMIT;