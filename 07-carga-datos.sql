-- ==========================================================
-- SCRIPT 07: 07-carga-datos.sql
-- Purpose: Population script for base entities.
-- ==========================================================

BEGIN;

-- 1. PROVEEDORES
INSERT INTO proveedor (id, nombre, contacto) VALUES 
('PR01', 'Textil Sur', 'Razon Social: Textil ER S.A., Tel: 34542211, ventas@textilsur.com'),
('PR02', 'Botones & Hilos', 'Razon Social: ImpCam S.R.L., Tel: 11432211, info@botoneshilos.com'),
('PR03', 'Telas del Norte', 'Razon Social: Norte Textil S.A., Tel: 38745566, contacto@telasnorte.com');

-- 2. USUARIOS (Root Strong Entities - Note test users were created in Script 06, here we mock initial generic rows if needed, or link to IDs)
INSERT INTO usuario (id, nombre, email, password, rol) VALUES 
('U01', 'Juan Admin', 'juan@camiseria.com', 'hash_admin_123', 'admin'),
('U02', 'Facundo Cliente', 'facu@gmail.com', 'hash_cliente_456', 'cliente'),
('U03', 'Maria Gomez', 'maria@outlook.com', 'hash_789', 'cliente');

-- 3. PRODUCTOS (15 base products)
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

-- 4. PROMOCIONES ACTIVAS
INSERT INTO promocion (id, tipo, descripcion, fecha_inicio, fecha_fin, descuento) VALUES
('PROM-01', 'descuento', 'Promo Verano 20%', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 0.20),
('PROM-02', '2x1', '2x1 en Remeras', CURRENT_DATE, CURRENT_DATE + INTERVAL '15 days', 0.50);

-- 5. VARIANTES (17 variants including representative combo variant)
INSERT INTO producto_variante (id, producto_id, precio, material, talle, color) VALUES 
('V1-B-M', 'P01', 25000, 'Algodón', 'M', 'Blanco'),
('V1-B-L', 'P01', 25000, 'Algodón', 'L', 'Blanco'),
('V2-A-M', 'P02', 25000, 'Algodón', 'M', 'Azul'),
('V2-A-L', 'P02', 25000, 'Algodón', 'L', 'Azul'),
('V3-BE-M', 'P03', 32000, 'Lino', 'M', 'Beige'),
('V4-CE-L', 'P04', 32000, 'Lino', 'L', 'Celeste'),
('V5-CH-42', 'P05', 45000, 'Gabardina', '42', 'Beige'),
('V6-CH-44', 'P06', 45000, 'Gabardina', '44', 'Azul'),
('V7-JN-42', 'P07', 38000, 'Denim', '42', 'Azul'),
('V8-JN-46', 'P08', 38000, 'Denim', '46', 'Negro'),
('V9-RB-M', 'P09', 12000, 'Algodón', 'M', 'Blanco'),
('V10-RB-L', 'P10', 12000, 'Algodón', 'L', 'Negro'),
('V11-SW-XL', 'P11', 55000, 'Lana', 'XL', 'Gris'),
('V12-CP-L', 'P12', 85000, 'Sintético', 'L', 'Negro'),
('V13-BM-42', 'P13', 28000, 'Gabardina', '42', 'Verde'),
('V14-BF-UNI', 'P14', 15000, 'Lana', 'Uni', 'Gris'),
('V-COMBO', 'P15', 45000, 'Algodón', 'Var', 'Dúo');

-- 6. IMÁGENES
INSERT INTO imagen (id, producto_variante_id, url_imagen) VALUES
('IMG-01', 'V1-B-M', 'https://example.com/img/oxford_blanca.jpg'),
('IMG-02', 'V2-A-M', 'https://example.com/img/oxford_azul.jpg'),
('IMG-03', 'V-COMBO', 'https://example.com/img/combo_dupla.jpg');

-- 7. ESTRUCTURA DEL COMBO
INSERT INTO combo (id, nombre, descripcion, precio, producto_variante_id) VALUES 
('C1', 'Pack Dupla Oxford', 'Llevate una blanca y una azul talle M', 45000, 'V-COMBO');

INSERT INTO combo_item (combo_id, producto_variante_id, cantidad) VALUES 
('C1', 'V1-B-M', 1),
('C1', 'V2-A-M', 1);

-- 8. CARGA INICIAL DE STOCK (CALL sp_registrar_ingreso_stock)
CALL sp_registrar_ingreso_stock('Camisa Oxford Blanca', 'M', 'PR01', 50, 10000.00);
CALL sp_registrar_ingreso_stock('Camisa Oxford Blanca', 'L', 'PR01', 30, 10000.00);
CALL sp_registrar_ingreso_stock('Camisa Oxford Azul', 'M', 'PR03', 40, 11000.00);
CALL sp_registrar_ingreso_stock('Camisa Oxford Azul', 'L', 'PR03', 20, 11000.00);
CALL sp_registrar_ingreso_stock('Pantalón Chino Beige', '42', 'PR02', 15, 20000.00);
CALL sp_registrar_ingreso_stock('Remera Básica Blanca', 'M', 'PR02', 100, 4500.00);
CALL sp_registrar_ingreso_stock('Suéter Lana Gris', 'XL', 'PR01', 10, 25000.00);

COMMIT;
