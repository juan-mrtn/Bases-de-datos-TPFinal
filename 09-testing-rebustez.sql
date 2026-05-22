
-- ==========================================================
-- Testing Robustez
-- Purpose: Automatización de Pruebas Unitarias de Robustez
--          (Caminos alternativos y de error esperado)
-- ==========================================================

DO $$
DECLARE
    v_test_name VARCHAR;
BEGIN
    RAISE NOTICE '=== INICIANDO PROTOCOLO AUTOMATIZADO DE ROBUSTEZ ===';

    -- ------------------------------------------------------
    -- CASO T-INT02: Bloqueo de opiniones falsas (Trigger)
    -- ------------------------------------------------------
    v_test_name := 'T-INT02 (trg_validar_cliente_opinion)';
    BEGIN
        -- Intentamos insertar opinión de un producto que 'U02' jamás compró
        INSERT INTO opinion (id, usuario_id, producto_variante_id, estrellas, comentario, fecha)
        VALUES ('OP-ERR', 'U02', 'V9-RB-M', 5, 'Opinión maliciosa/falsa', CURRENT_DATE);
        
        -- Si la ejecución llega a esta línea, significa que la base de datos PERMITIÓ el insert (TEST FALLADO)
        RAISE WARNING 'Test % FALLÓ: El sistema permitió insertar una opinión sin compra previa.', v_test_name;
    EXCEPTION WHEN OTHERS THEN
        -- Si entra acá es porque el trigger saltó y abortó el INSERT (TEST EXITOSO)
        RAISE NOTICE 'Test % PASÓ: El trigger bloqueó la opinión fraudulenta. Código de error: %', v_test_name, SQLSTATE;
    END;

    -- ------------------------------------------------------
    -- CASO T-INT03: Control de sobreventa en Carrito (Trigger)
    -- ------------------------------------------------------
    v_test_name := 'T-INT03 (trg_carrito_item_valida_stock)';
    BEGIN
        -- Forzamos la carga de una cantidad ridícula (e.g., 9999 unidades) en el carrito
        CALL sp_agregar_al_carrito('C01', 'V1-B-M', 9999);
        
        RAISE WARNING 'Test % FALLÓ: El sistema permitió añadir al carrito más unidades del stock real.', v_test_name;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Test % PASÓ: El trigger interceptó la falta de stock e impidió la reserva. Código de error: %', v_test_name, SQLSTATE;
    END;

    -- ------------------------------------------------------
    -- CASO T-INT04: Restricción de Dominio (CHECK Estrellas)
    -- ------------------------------------------------------
    v_test_name := 'T-INT04 (CHECK estrellas entre 1 y 5)';
    BEGIN
        -- Intentamos insertar una calificación inválida de 7 estrellas
        INSERT INTO opinion (id, usuario_id, producto_variante_id, estrellas, comentario, fecha)
        VALUES ('OP-ERR2', 'U02', 'V1-B-M', 7, 'Excelente', CURRENT_DATE);
        
        RAISE WARNING 'Test % FALLÓ: Se permitió una calificación fuera del rango (1-5).', v_test_name;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Test % PASÓ: La restricción CHECK bloqueó el dominio inválido. Código de error: %', v_test_name, SQLSTATE;
    END;

    -- ------------------------------------------------------
    -- CASO T-INT07: Control de pagos duplicados o inválidos (SP)
    -- ------------------------------------------------------
    v_test_name := 'T-INT07 (sp_confirmar_pago sin órdenes activas)';
    BEGIN
        -- El usuario U02 ya cerró su compra en el script 08, por ende no tiene nada en 'procesando'
        -- Si volvemos a llamar al procedimiento para el mismo usuario, debería saltar la excepción interna
        CALL sp_confirmar_pago('U02');
        
        RAISE WARNING 'Test % FALLÓ: El procedimiento procesó un pago fantasma/inexistente.', v_test_name;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Test % PASÓ: El procedimiento validó el estado y denegó el pago huérfano. Código de error: %', v_test_name, SQLSTATE;
    END;

    RAISE NOTICE '=== PROTOCOLO DE ROBUSTEZ FINALIZADO COMPLETO ===';
END $$;