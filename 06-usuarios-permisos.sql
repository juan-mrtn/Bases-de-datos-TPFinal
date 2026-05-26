-- ==========================================================
-- SCRIPT 06: 06-usuarios-permisos.sql
-- Purpose: Apply Role-Based Access Control (RBAC).
-- ==========================================================

-- 1. DROP EXISTING ROLES TO ENSURE IDEMPOTENCY
DROP ROLE IF EXISTS rol_admin;
DROP ROLE IF EXISTS rol_cliente;

-- 2. CREATE ROLES
CREATE ROLE rol_admin;
CREATE ROLE rol_cliente;

-- 3. PERMISSIONS: ADMINISTRATOR (Full Control)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA public TO rol_admin;

-- 4. PERMISSIONS: CLIENT (Restricted Access)

-- A. Views (Frontend visibility)
GRANT SELECT ON v_catalogo_publico TO rol_cliente;
GRANT SELECT ON v_stock_actual TO rol_cliente;
GRANT SELECT ON v_carrito_detalle TO rol_cliente;
GRANT SELECT ON v_producto_detalle TO rol_cliente;

-- B. Read-Only Tables (Product and Purchase details)
GRANT SELECT ON producto, producto_variante, combo, combo_item TO rol_cliente;
GRANT SELECT ON compra, linea_de_compra TO rol_cliente;
GRANT SELECT ON promocion TO rol_cliente;

-- C. Cart and Account Management (Controlled writing)
GRANT SELECT, INSERT, UPDATE, DELETE ON carrito TO rol_cliente;
GRANT SELECT, INSERT, UPDATE, DELETE ON carrito_item TO rol_cliente;
GRANT SELECT, INSERT, UPDATE ON direccion TO rol_cliente;
GRANT SELECT, INSERT ON opinion TO rol_cliente;
GRANT SELECT, INSERT ON favorito TO rol_cliente;

-- D. Execution of Logic (Crucial for checkout)
GRANT EXECUTE ON PROCEDURE sp_agregar_al_carrito(VARCHAR, VARCHAR, INT, BOOLEAN) TO rol_cliente;
GRANT EXECUTE ON PROCEDURE sp_finalizar_compra(VARCHAR, VARCHAR) TO rol_cliente;
GRANT EXECUTE ON PROCEDURE sp_confirmar_pago(VARCHAR) TO rol_cliente;
GRANT EXECUTE ON FUNCTION fn_obtener_stock_real(VARCHAR) TO rol_cliente;
GRANT EXECUTE ON FUNCTION fn_calcular_total_carrito(VARCHAR) TO rol_cliente;

-- E. Additional permissions 
GRANT USAGE ON SCHEMA public TO rol_cliente;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_cliente;

-- 5. CREATE AND ASSIGN TEST USERS
DROP USER IF EXISTS juan_admin;
DROP USER IF EXISTS facu_cliente;

CREATE USER juan_admin WITH PASSWORD 'admin123';
CREATE USER facu_cliente WITH PASSWORD 'cliente123';

GRANT rol_admin TO juan_admin;
GRANT rol_cliente TO facu_cliente;
