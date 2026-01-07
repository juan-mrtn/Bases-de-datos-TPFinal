BEGIN;

-- ==========================================================
-- 1. PROVEEDORES (La fuente del stock)
-- ==========================================================
INSERT INTO proveedor (id, nombre, contacto) VALUES 
('PR01', 'Textil Sur', 'Razon Social: Textil ER S.A., Tel: 34542211, ventas@textilsur.com'),
('PR02', 'Botones & Hilos', 'Razon Social: ImpCam S.R.L., Tel: 11432211, info@botoneshilos.com');

-- ==========================================================
-- 2. USUARIOS (Padres de las direcciones)
-- ==========================================================
INSERT INTO usuario (id, nombre, email, password, rol) VALUES 
('U01', 'Juan Admin', 'juan@camiseria.com', 'hash_admin_123', 'admin'),
('U02', 'Facundo Cliente', 'facu@gmail.com', 'hash_cliente_456', 'cliente'),
('U03', 'Maria Gomez', 'maria@outlook.com', 'hash_789', 'cliente');

-- ==========================================================
-- 3. DIRECCIONES
-- ==========================================================
INSERT INTO direccion (id, usuario_id, calle, numero, codigo_postal, ciudad, provincia) VALUES 
('DIR01', 'U02', 'San Lorenzo', '455', '3200', 'Concordia', 'Entre Ríos'),
('DIR02', 'U03', 'Av. Rivadavia', '1200', '1000', 'CABA', 'Buenos Aires');

-- ==========================================================
-- 4. PRODUCTOS
-- ==========================================================
INSERT INTO producto (id, nombre, descripcion, codigo) VALUES 
('P1', 'Camisa Oxford Blanca', '100% Algodón, clásica.', 'OX-001'),
('P2', 'Camisa Oxford Azul', '100% Algodón, formal.', 'OX-002'),
('P3', 'Pack Dupla Oxford', 'Producto representativo para combo.', 'COMBO-01');

-- ==========================================================
-- 5. VARIANTES (Sin columna stock, se calculan solas)
-- ==========================================================
INSERT INTO producto_variante (id, producto_id, precio, material, talle) VALUES 
('V1-B-M', 'P1', 25000, 'Algodón', 'M'),
('V1-B-L', 'P1', 25000, 'Algodón', 'L'),
('V2-A-M', 'P2', 25000, 'Algodón', 'M'),
('V-COMBO', 'P3', 45000, 'Algodón', 'Var');

-- ==========================================================
-- 6. COMPRA A PROVEEDORES (¡ESTO AGREGA EL STOCK!)
-- ==========================================================
-- Sin estos inserts, el catálogo diría "Sin Stock"
INSERT INTO compra_proveedor (id, proveedor_id, producto_variante_id, cantidad, costo) VALUES 
('CP-001', 'PR01', 'V1-B-M', 50, 10000.00), -- Agrega 50 camisas blancas M
('CP-002', 'PR01', 'V1-B-L', 30, 10000.00), -- Agrega 30 camisas blancas L
('CP-003', 'PR02', 'V2-A-M', 40, 11000.00); -- Agrega 40 camisas azules M

-- ==========================================================
-- 7. ESTRUCTURA DEL COMBO
-- ==========================================================
INSERT INTO "Combo" (id, nombre, descripcion, precio, producto_variante_id) VALUES 
('C1', 'Combo 2 Camisas Oxford', 'Llevate una blanca y una azul', 45000, 'V-COMBO');

INSERT INTO "ComboItem" (combo_id, producto_variante_id, cantidad) VALUES 
('C1', 'V1-B-M', 1), -- El combo consume 1 Blanca M
('C1', 'V2-A-M', 1); -- El combo consume 1 Azul M

COMMIT;