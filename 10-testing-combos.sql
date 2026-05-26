
-- =========================================================================
-- CASOS DE PRUEBA AVANZADOS: GESTIÓN DE COMBOS POLIMÓRFICOS Y CARRITOS MIXTOS
-- =========================================================================

-- SETUP DEL ESCENARIO: Creamos un usuario y un carrito limpio exclusivo para estas pruebas
INSERT INTO usuario (id, nombre, email, password, rol, suscrito)
VALUES ('USR-PRUEBA-COMBOS', 'Lucas', 'lucas.test@laurbanasistemas.com', 'hash_secure_255', 'cliente', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO carrito (id, usuario_id, total, descuento_total, estado)
VALUES ('CART-PRUEBA-COMBOS', 'USR-PRUEBA-COMBOS', 0, 0, 'abierto')
ON CONFLICT (id) DO NOTHING;

-- Garantizamos idempotencia limpiando remanentes de ejecuciones previas
DELETE FROM carrito_item WHERE carrito_id = 'CART-PRUEBA-COMBOS';
UPDATE carrito SET total = 0, estado = 'abierto' WHERE id = 'CART-PRUEBA-COMBOS';

-- =========================================================================
-- TEST 1: AGREGAR UN COMBO AL CARRITO OPERATIVO
-- Objetivo: Validar que el SP resuelva el polimorfismo insertando el combo_id
--           en la tabla intermedia y que la vista de detalle lo renderice.
-- =========================================================================

-- 1. Ejecutar la carga del combo virtual (2 unidades de 'COMBO-URBANO-01')
CALL sp_agregar_al_carrito('CART-PRUEBA-COMBOS', 'C1', 2, TRUE);

-- 2. VERIFICACIÓN DE RESULTADO: Consultar la vista del detalle del carrito
SELECT 
    carrito_id, 
    producto AS articulo_añadido, 
    cantidad, 
    precio_unitario, 
    subtotal_item, 
    total_acumulado_carrito
FROM v_carrito_detalle
WHERE carrito_id = 'CART-PRUEBA-COMBOS';

/* RESULTADO ESPERADO:
  - Deberá aparecer una fila donde 'articulo_añadido' sea "Combo Verano Urbano".
  - cantidad = 2.
  - precio_unitario = 15000.00.
  - subtotal_item = 30000.00.
  - total_acumulado_carrito = 30000.00 (calculado dinámicamente por la base de datos).
*/


-- =========================================================================
-- TEST 2: CARRITO MIXTO (COMBO + PRENDA INDIVIDUAL) Y COMPRA COMPLETA
-- Objetivo: Evaluar la coexistencia de ambos tipos de ítems en el checkout,
--           validar la atomicidad de la transacción y comprobar el impacto 
--           del "cuello de botella" en el stock dinámico final.
-- =========================================================================

-- 1. Guardar una foto del stock actual de los componentes individuales antes de la compra
SELECT producto_variante_id, stock_disponible, tipo_item 
FROM v_stock_actual 
WHERE producto_variante_id IN ('V1-B-M', 'V9-RB-M', 'C1');

-- 2. Añadir prendas individuales al mismo carrito (Ej: 2 unidades de la camisa suelta 'V1-B-M')
CALL sp_agregar_al_carrito('CART-PRUEBA-COMBOS', 'V1-B-M', 2, FALSE);

-- 3. Verificar el estado del carrito mixto en la vista flat antes de cerrar la orden
SELECT producto, talle, cantidad, precio_unitario, subtotal_item, total_acumulado_carrito
FROM v_carrito_detalle
WHERE carrito_id = 'CART-PRUEBA-COMBOS';

-- 4. PROCESO DE CHECKOUT: Compilar la orden transaccional (Pasa a estado 'procesando')
CALL sp_finalizar_compra('USR-PRUEBA-COMBOS', 'CART-PRUEBA-COMBOS');

-- 5. CONFIRMACIÓN MERCADOPAGO: Acreditar pago (Dispara triggers de verificación de stock final)
CALL sp_confirmar_pago('USR-PRUEBA-COMBOS');

-- 6. VERIFICACIÓN DE IMPACTO FINAL: Consultar el nuevo stock neto remanente
SELECT producto_variante_id, stock_disponible, tipo_item 
FROM v_stock_actual 
WHERE producto_variante_id IN ('V1-B-M', 'V9-RB-M', 'C1');

/* ANÁLISIS MATEMÁTICO DE REDUCCIÓN DE STOCK ESPERADO:
  En el carrito teníamos:
    - 2 Combos (Cada uno consume 1 'V1-B-M' y 1 'V9-RB-M' -> Total combos: 2 de cada una).
    - 2 Camisas individuales 'V1-B-M'.
  
  Egresos totales confirmados por la transacción:
    - Para 'V9-RB-M': Se deben descontar exactamente 2 unidades.
    - Para 'V1-B-M': Se deben descontar 4 unidades (2 del combo + 2 individuales).
  
  RESULTADO ESPERADO EN CONSOLA:
    - El stock de 'V9-RB-M' debe haber bajado de 46 a 44.
    - El stock de 'V1-B-M' debe haber bajado en 4 unidades respecto a su estado inicial.
    - El stock del 'COMBO-URBANO-01' se reajustará de manera automática en la vista 
      mostrando el nuevo cuello de botella (el stock mínimo remanente entre sus componentes).
*/