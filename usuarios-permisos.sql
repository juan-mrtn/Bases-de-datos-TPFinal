-- ==========================================================
-- 1. LIMPIEZA Y CREACIÓN DE ROLES
-- ==========================================================
-- Borramos si existen para evitar errores y volvemos a crear
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_admin') THEN
        DROP ROLE rol_admin;
    END IF;
    IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_cliente') THEN
        DROP ROLE rol_cliente;
    END IF;
END $$;

CREATE ROLE rol_admin;
CREATE ROLE rol_cliente;

-- ==========================================================
-- 2. PERMISOS: ADMINISTRADOR (Control Total)
-- ==========================================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA public TO rol_admin;

-- ==========================================================
-- 3. PERMISOS: CLIENTE (Acceso Restringido)
-- ==========================================================

-- A. Vistas (Lo que el cliente ve en la App)
GRANT SELECT ON v_catalogo_publico TO rol_cliente;
GRANT SELECT ON v_stock_actual TO rol_cliente; -- Necesaria para que el trigger valide stock

-- B. Tablas de Lectura (Para ver detalles de productos y sus compras)
GRANT SELECT ON producto, producto_variante, "Combo", "ComboItem" TO rol_cliente;
GRANT SELECT ON compra, linea_de_compra TO rol_cliente;

-- C. Gestión de Carrito y Cuenta (Escritura controlada)
GRANT SELECT, INSERT, UPDATE, DELETE ON carrito TO rol_cliente;
GRANT SELECT, INSERT, UPDATE, DELETE ON carrito_item TO rol_cliente;
GRANT SELECT, INSERT, UPDATE ON direccion TO rol_cliente;
GRANT SELECT, INSERT ON opinion TO rol_cliente;
GRANT SELECT, INSERT ON favorito TO rol_cliente;

-- D. Ejecución de Lógica (Crucial para el stock calculado)
-- El cliente debe poder ejecutar la función de stock para que el trigger no le de error
GRANT EXECUTE ON FUNCTION fn_obtener_stock_real(VARCHAR) TO rol_cliente;
GRANT EXECUTE ON PROCEDURE sp_finalizar_compra(VARCHAR, VARCHAR) TO rol_cliente;

-- ==========================================================
-- 4. CREACIÓN DE USUARIOS DE PRUEBA
-- ==========================================================
-- Creamos usuarios reales y les asignamos los roles
-- DROP USER IF EXISTS juan_admin;
-- DROP USER IF EXISTS facu_cliente;

CREATE USER juan_admin WITH PASSWORD 'admin123';
CREATE USER facu_cliente WITH PASSWORD 'cliente123';

GRANT rol_admin TO juan_admin;
GRANT rol_cliente TO facu_cliente;