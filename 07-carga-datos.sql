-- ==========================================================
-- SCRIPT 07: 07-carga-datos.sql
-- Purpose: Population script for base entities.
-- ==========================================================
BEGIN;

-- 1. PROVEEDORES (3)
INSERT INTO proveedor (id, nombre, contacto) VALUES 
('PR01', 'Textil Sur', 'Razon Social: Textil ER S.A., Tel: 34542211'),
('PR02', 'Botones & Hilos', 'Razon Social: ImpCam S.R.L., Tel: 11432211'),
('PR03', 'Telas del Norte', 'Razon Social: Norte Textil S.A., Tel: 38745566');

-- 2. USUARIOS (6)
INSERT INTO usuario (id, nombre, email, password, rol, suscrito) VALUES 
('U01', 'Juan Admin', 'juan@camiseria.com', 'hash_admin_123', 'admin', true),
('U02', 'Facundo Cliente', 'facu@gmail.com', 'hash_cliente_456', 'cliente', true),
('U03', 'Maria Gomez', 'maria@outlook.com', 'hash_789', 'cliente', false),
('U04', 'Carlos Rodriguez', 'carlos@gmail.com', 'hash_101', 'cliente', true),
('U05', 'Ana Lopez', 'ana@outlook.com', 'hash_202', 'cliente', false),
('U06', 'Pedro Sanchez', 'pedro@gmail.com', 'hash_303', 'cliente', true);

-- 3. PRODUCTOS (15)
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
('P15', 'Pack Dupla Oxford', 'Representante de combo.', 'COMBO-01');

-- 4. PROMOCIONES (4)
INSERT INTO promocion (id, tipo, descripcion, fecha_inicio, fecha_fin, descuento) VALUES
('PROM-01', 'descuento', 'Promo Verano 20%', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', 0.20),
('PROM-02', '2x1', '2x1 en Remeras', CURRENT_DATE, CURRENT_DATE + INTERVAL '15 days', 0.50),
('PROM-03', 'descuento', 'Día del Padre 15%', CURRENT_DATE - INTERVAL '5 days', CURRENT_DATE + INTERVAL '10 days', 0.15),
('PROM-04', 'descuento', 'Black Friday', CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE + INTERVAL '20 days', 0.30);

-- 5. VARIANTES (17)
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

-- 6. IMÁGENES (15 filas)
INSERT INTO imagen (id, producto_variante_id, url_imagen) VALUES
('IMG-01', 'V1-B-M', 'https://example.com/img/oxford_blanca_m.jpg'),
('IMG-02', 'V1-B-L', 'https://example.com/img/oxford_blanca_l.jpg'),
('IMG-03', 'V2-A-M', 'https://example.com/img/oxford_azul_m.jpg'),
('IMG-04', 'V3-BE-M', 'https://example.com/img/lino_beige.jpg'),
('IMG-05', 'V4-CE-L', 'https://example.com/img/lino_celeste.jpg'),
('IMG-06', 'V5-CH-42', 'https://example.com/img/chino_beige.jpg'),
('IMG-07', 'V7-JN-42', 'https://example.com/img/jean_blue.jpg'),
('IMG-08', 'V9-RB-M', 'https://example.com/img/remera_blanca.jpg'),
('IMG-09', 'V10-RB-L', 'https://example.com/img/remera_negra.jpg'),
('IMG-10', 'V11-SW-XL', 'https://example.com/img/sueter_gris.jpg'),
('IMG-11', 'V12-CP-L', 'https://example.com/img/campera.jpg'),
('IMG-12', 'V13-BM-42', 'https://example.com/img/bermuda.jpg'),
('IMG-13', 'V-COMBO', 'https://example.com/img/combo_dupla.jpg'),
('IMG-14', 'V1-B-M', 'https://example.com/img/oxford_blanca_back.jpg'),
('IMG-15', 'V2-A-M', 'https://example.com/img/oxford_azul_back.jpg');

-- 7. DIRECCIONES (12 filas)
INSERT INTO direccion (id, usuario_id, titulo, calle, numero, codigo_postal, ciudad, provincia, principal) VALUES
('DIR01', 'U02', 'Casa', 'San Martin', '123', '3100', 'Paraná', 'Entre Ríos', true),
('DIR02', 'U02', 'Trabajo', '9 de Julio', '456', '3100', 'Paraná', 'Entre Ríos', false),
('DIR03', 'U03', 'Casa', 'Alem', '789', '3260', 'Concordia', 'Entre Ríos', true),
('DIR04', 'U04', 'Casa', 'Bv. Racedo', '101', '3100', 'Paraná', 'Entre Ríos', true),
('DIR05', 'U05', 'Casa', 'Urquiza', '202', '3200', 'Gualeguaychú', 'Entre Ríos', true),
('DIR06', 'U06', 'Casa', 'Mitre', '303', '3100', 'Paraná', 'Entre Ríos', true),
('DIR07', 'U02', 'Departamento', 'La Rioja', '150', '3100', 'Paraná', 'Entre Ríos', false),
('DIR08', 'U03', 'Veraneo', 'Costanera', '500', '3260', 'Concordia', 'Entre Ríos', false),
('DIR09', 'U04', 'Oficina', 'Corrientes', '220', '3100', 'Paraná', 'Entre Ríos', false),
('DIR10', 'U05', 'Familia', '25 de Mayo', '75', '3200', 'Gualeguaychú', 'Entre Ríos', false);

-- 8. COMBO
INSERT INTO combo (id, nombre, descripcion, precio, producto_variante_id) VALUES 
('C1', 'Pack Dupla Oxford', 'Llevate una blanca y una azul talle M', 45000, 'V-COMBO');

INSERT INTO combo_item (combo_id, producto_variante_id, cantidad) VALUES 
('C1', 'V1-B-M', 1),
('C1', 'V2-A-M', 1);

-- 9. CARGA DE STOCK (18 ingresos)
CALL sp_registrar_ingreso_stock('Camisa Oxford Blanca', 'M', 'PR01', 50, 10000.00);
CALL sp_registrar_ingreso_stock('Camisa Oxford Blanca', 'L', 'PR01', 30, 10000.00);
CALL sp_registrar_ingreso_stock('Camisa Oxford Azul', 'M', 'PR03', 40, 11000.00);
CALL sp_registrar_ingreso_stock('Camisa Oxford Azul', 'L', 'PR03', 20, 11000.00);
CALL sp_registrar_ingreso_stock('Pantalón Chino Beige', '42', 'PR02', 25, 20000.00);
CALL sp_registrar_ingreso_stock('Remera Básica Blanca', 'M', 'PR02', 120, 4500.00);
CALL sp_registrar_ingreso_stock('Suéter Lana Gris', 'XL', 'PR01', 15, 25000.00);
CALL sp_registrar_ingreso_stock('Jean Slim Blue', '42', 'PR01', 35, 18000.00);
CALL sp_registrar_ingreso_stock('Camisa Lino Beige', 'M', 'PR03', 18, 15000.00);

-- 10. FAVORITOS (15)
INSERT INTO favorito (id, usuario_id, producto_variante_id) VALUES
('FAV01', 'U02', 'V1-B-M'), ('FAV02', 'U02', 'V9-RB-M'), ('FAV03', 'U02', 'V11-SW-XL'),
('FAV04', 'U03', 'V2-A-M'), ('FAV05', 'U03', 'V7-JN-42'),
('FAV06', 'U04', 'V5-CH-42'), ('FAV07', 'U04', 'V12-CP-L'),
('FAV08', 'U05', 'V3-BE-M'), ('FAV09', 'U05', 'V10-RB-L'),
('FAV10', 'U06', 'V1-B-L'), ('FAV11', 'U06', 'V4-CE-L'),
('FAV12', 'U02', 'V-COMBO'), ('FAV13', 'U03', 'V13-BM-42'),
('FAV14', 'U04', 'V8-JN-46'), ('FAV15', 'U05', 'V6-CH-44');

-- 11. OPINIONES (10) - Solo sobre productos comprados
INSERT INTO opinion (id, usuario_id, producto_variante_id, estrellas, comentario) VALUES
('OP01', 'U02', 'V1-B-M', 5, 'Excelente calidad y ajuste perfecto.'),
('OP02', 'U02', 'V9-RB-M', 4, 'Muy cómoda para uso diario.'),
('OP03', 'U03', 'V2-A-M', 5, 'Color vibrante y buen tejido.'),
('OP04', 'U04', 'V5-CH-42', 4, 'Buen pantalón formal.'),
('OP05', 'U05', 'V3-BE-M', 5, 'Lino muy fresco para el verano.'),
('OP06', 'U06', 'V7-JN-42', 4, 'Jean de buena calidad.'),
('OP07', 'U02', 'V11-SW-XL', 5, 'Suéter muy abrigado y suave.'),
('OP08', 'U03', 'V1-B-M', 5, 'Repetiría sin duda.'),
('OP09', 'U04', 'V12-CP-L', 4, 'Campera con buen corte.'),
('OP10', 'U05', 'V10-RB-L', 5, 'Remera negra ideal.');

COMMIT;