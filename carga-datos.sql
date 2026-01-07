-- Iniciar transacción para asegurar que se cargue todo o nada
BEGIN;

-- 1. PROVEEDORES
INSERT INTO proveedor (id, nombre, contacto) VALUES 
('PROV01', 'Textil Entre Ríos', 'Razon Social: Textil ER S.A., Tel: 34542211, Email: ventas@textiler.com'),
('PROV02', 'Importadora Camisera', 'Razon Social: ImpCam S.R.L., Tel: 11432211, Email: contacto@impcam.com.ar');

-- 2. PRODUCTOS
INSERT INTO producto (id, nombre, descripcion, codigo) VALUES 
('P01', 'Camisa Oxford', 'Camisa clásica 100% algodón ideal para oficina.', 'OXF-001'),
('P02', 'Camisa Lino Verano', 'Camisa liviana de lino premium.', 'LIN-502'),
('P03', 'Pack Promocional', 'Producto virtual para agrupar combos.', 'COMBO-VIRT');

-- 3. PRODUCTO_VARIANTE (Incluye variantes reales y la del combo)
INSERT INTO producto_variante (id, producto_id, precio, material, talle, stock) VALUES 
('PV01', 'P01', 45000.00, 'Algodón', 'M', 0), -- Stock inicial 0, subirá con compra_proveedor
('PV02', 'P01', 45000.00, 'Algodón', 'L', 0),
('PV03', 'P02', 55000.00, 'Lino', 'S', 0),
('PV04', 'P02', 55000.00, 'Lino', 'M', 0),
('PV_COMBO_VIRT', 'P03', 85000.00, 'Mix', 'Variados', 0); -- Representante del combo

-- 4. COMBOS Y COMBOITEM
INSERT INTO "Combo" (id, nombre, descripcion, precio, producto_variante_id) VALUES 
('C01', 'Combo Oficina', 'Llevate una Oxford M y una de Lino S con descuento', 85000.00, 'PV_COMBO_VIRT');

INSERT INTO "ComboItem" (combo_id, producto_variante_id, cantidad) VALUES 
('C01', 'PV01', 1),
('C01', 'PV03', 1);

-- 5. USUARIOS (Datos de la plataforma)
INSERT INTO usuario (id, nombre, email, password, rol) VALUES 
('U01', 'Juan Admin', 'juan@camiseria.com', 'hash_admin_123', 'admin'),
('U02', 'Facundo Cliente', 'facu@gmail.com', 'hash_cliente_456', 'cliente'),
('U03', 'Maria Gomez', 'maria@outlook.com', 'hash_789', 'cliente');

-- 6. COMPRA_PROVEEDOR (Esto activará el Trigger de Stock)
INSERT INTO compra_proveedor (id, proveedor_id, producto_variante_id, cantidad, costo) VALUES 
('CP01', 'PROV01', 'PV01', 20, 15000.00), -- Stock PV01 pasa a 20
('CP02', 'PROV01', 'PV02', 20, 15000.00),
('CP03', 'PROV02', 'PV03', 15, 20000.00),
('CP04', 'PROV02', 'PV04', 15, 20000.00);

-- 7. DIRECCIONES
INSERT INTO direccion (id, usuario_id, calle, numero, codigo_postal, ciudad, provincia) VALUES 
('DIR01', 'U02', 'San Lorenzo', '455', '3200', 'Concordia', 'Entre Ríos'),
('DIR02', 'U03', 'Av. Rivadavia', '1200', '1000', 'CABA', 'Buenos Aires');

-- 8. CARRITO Y CARRITO_ITEM
INSERT INTO carrito (id, usuario_id, total, estado) VALUES 
('CART01', 'U02', 45000.00, 'abierto');

INSERT INTO carrito_item (id, carrito_id, producto_variante_id, cantidad, precio_unitario) VALUES 
('CI01', 'CART01', 'PV01', 1, 45000.00);

-- 9. OPINIONES
INSERT INTO opinion (id, usuario_id, producto_variante_id, estrellas, comentario) VALUES 
('OP01', 'U02', 'PV01', 5, 'Excelente calidad, el talle M me quedó perfecto.'),
('OP02', 'U03', 'PV03', 4, 'Muy linda pero se arruga un poco por el lino.');

COMMIT;