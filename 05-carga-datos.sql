BEGIN;

-- Limpieza de datos existentes para evitar el error de clave duplicada
TRUNCATE TABLE 
    compra_proveedor, 
    linea_de_compra, 
    compra, 
    carrito_item, 
    carrito, 
    direccion, 
    usuario, 
    combo_item, 
    combo, 
    producto_variante, 
    producto, 
    proveedor 
RESTART IDENTITY CASCADE;
-- ==========================================================
-- 1. PROVEEDORES (3 Proveedores)
-- ==========================================================
INSERT INTO proveedor (id, nombre, contacto) VALUES 
('PR01', 'Textil Sur', 'Razon Social: Textil ER S.A., Tel: 34542211, ventas@textilsur.com'),
('PR02', 'Botones & Hilos', 'Razon Social: ImpCam S.R.L., Tel: 11432211, info@botoneshilos.com'),
('PR03', 'Telas del Norte', 'Razon Social: Norte Textil S.A., Tel: 38745566, contacto@telasnorte.com');

-- ==========================================================
-- 2. USUARIOS
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
-- 4. PRODUCTOS (15 Productos)
-- ==========================================================
INSERT INTO producto (id, nombre, descripcion, codigo) VALUES 
('P01', 'Camisa Oxford Blanca', '100% Algodón, clásica.', 'OX-001'),
('P02', 'Camisa Oxford Azul', '100% Algodón, formal.', 'OX-002'),
('P03', 'Camisa Lino Beige', 'Fresca para verano.', 'LN-001'),
('P04', 'Camisa Lino Celeste', 'Lino de alta calidad.', 'LN-002'),
('P05', 'Pantalón Chino Beige', 'Corte Slim Fit.', 'CH-001'),
('P06', 'Pantalón Chino Azul', 'Corte Recto Clásico.', 'CH-002'),
('P07', 'Jean Slim Blue', 'Denim con elastano.', 'JN-001'),
('P08', 'Jean Regular Black', 'Denim rígido duradero.', 'JN-002'),
('P09', 'Remera Básica Blanca', 'Jersey de algodón.', 'RB-001'),
('P10', 'Remera Básica Negra', 'Jersey de algodón premium.', 'RB-002'),
('P11', 'Suéter Lana Gris', 'Lana merino suave.', 'SW-001'),
('P12', 'Campera Eco-cuero', 'Corte motero.', 'CP-001'),
('P13', 'Bermuda Gabardina', 'Ideal para tiempo libre.', 'BM-001'),
('P14', 'Bufanda Lana', 'Accesorio de invierno.', 'AC-001'),
('P15', 'Pack Dupla Oxford', 'Representante de combo 2 camisas.', 'COMBO-01');

-- ==========================================================
-- 5. VARIANTES (Talles y Colores)
-- ==========================================================
INSERT INTO producto_variante (id, producto_id, precio, material, talle, color) VALUES 
-- Camisas Oxford (P01, P02)
('V1-B-M', 'P01', 25000, 'Algodón', 'M', 'Blanco'),
('V1-B-L', 'P01', 25000, 'Algodón', 'L', 'Blanco'),
('V2-A-M', 'P02', 25000, 'Algodón', 'M', 'Azul'),
('V2-A-L', 'P02', 25000, 'Algodón', 'L', 'Azul'),
-- Camisas Lino (P03, P04)
('V3-BE-M', 'P03', 32000, 'Lino', 'M', 'Beige'),
('V4-CE-L', 'P04', 32000, 'Lino', 'L', 'Celeste'),
-- Pantalones y Jeans (P05-P08)
('V5-CH-42', 'P05', 45000, 'Gabardina', '42', 'Beige'),
('V6-CH-44', 'P06', 45000, 'Gabardina', '44', 'Azul'),
('V7-JN-42', 'P07', 38000, 'Denim', '42', 'Azul'),
('V8-JN-46', 'P08', 38000, 'Denim', '46', 'Negro'),
-- Remeras y Suéter (P09-P11)
('V9-RB-M', 'P09', 12000, 'Algodón', 'M', 'Blanco'),
('V10-RB-L', 'P10', 12000, 'Algodón', 'L', 'Negro'),
('V11-SW-XL', 'P11', 55000, 'Lana', 'XL', 'Gris'),
-- Otros (P12-P14)
('V12-CP-L', 'P12', 85000, 'Sintético', 'L', 'Negro'),
('V13-BM-42', 'P13', 28000, 'Gabardina', '42', 'Verde'),
('V14-BF-UNI', 'P14', 15000, 'Lana', 'Uni', 'Gris'),
-- Variante Representante de Combo (P15)
('V-COMBO', 'P15', 45000, 'Algodón', 'Var', 'Dúo');

-- ==========================================================
-- 6. COMPRA A PROVEEDORES (Carga Inicial de Stock)
-- ==========================================================
INSERT INTO compra_proveedor (id, proveedor_id, producto_variante_id, cantidad, costo, fecha) VALUES 
('CP-001', 'PR01', 'V1-B-M', 50, 10000.00, CURRENT_TIMESTAMP),
('CP-002', 'PR01', 'V1-B-L', 30, 10000.00, CURRENT_TIMESTAMP),
('CP-003', 'PR03', 'V2-A-M', 40, 11000.00, CURRENT_TIMESTAMP),
('CP-004', 'PR03', 'V2-A-L', 20, 11000.00, CURRENT_TIMESTAMP),
('CP-005', 'PR02', 'V5-CH-42', 15, 20000.00, CURRENT_TIMESTAMP),
('CP-006', 'PR02', 'V9-RB-M', 100, 4500.00, CURRENT_TIMESTAMP),
('CP-007', 'PR01', 'V11-SW-XL', 10, 25000.00, CURRENT_TIMESTAMP);

-- ==========================================================
-- 7. ESTRUCTURA DEL COMBO
-- ==========================================================
-- El combo se vincula a su variante representante 'V-COMBO'
INSERT INTO combo (id, nombre, descripcion, precio, producto_variante_id) VALUES 
('C1', 'Pack Dupla Oxford', 'Llevate una blanca y una azul talle M', 45000, 'V-COMBO');

-- Definimos los componentes del combo
INSERT INTO combo_item (combo_id, producto_variante_id, cantidad) VALUES 
('C1', 'V1-B-M', 1), -- Consume 1 Blanca M
('C1', 'V2-A-M', 1); -- Consume 1 Azul M

COMMIT;