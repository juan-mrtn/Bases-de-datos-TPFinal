-- 1. Creación de la base de datos
-- CREATE DATABASE gestion_comercio;

BEGIN;

-- 2. Creacion de tipos de datos ENUM

CREATE TYPE tipo_promocion AS ENUM ('Descuento', '2x1');
CREATE TYPE estado_pago AS ENUM ('inactivo', 'procesando', 'confirmado', 'rechazado');
CREATE TYPE estado_carrito AS ENUM ('abierto', 'confirmado', 'cancelado');
CREATE TYPE rol_usuario AS ENUM ('cliente', 'admin');

-- 3. Definición de Tablas y Dominios

-- Tabla: Categorías (Independiente)

-- Tabla: Producto
CREATE TABLE producto (
    id VARCHAR PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    codigo VARCHAR(50) UNIQUE NOT NULL
);

-- Tabla: Promocion
CREATE TABLE promocion (
    id VARCHAR PRIMARY KEY,
    tipo tipo_promocion NOT NULL,
    descripcion TEXT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL CHECK (fecha_fin > fecha_inicio),
    descuento DECIMAL(10, 2) CHECK (descuento >= 0),
    CONSTRAINT check_fechas CHECK (fecha_fin >= fecha_inicio)
);

-- Tabla: ProductoVariante
CREATE TABLE producto_variante (
    id VARCHAR PRIMARY KEY,
    producto_id VARCHAR NOT NULL,
    promocion_id VARCHAR,
    precio DECIMAL(12, 2) NOT NULL CHECK (precio >= 0),
    material VARCHAR(30),
    talle VARCHAR(4),
    CONSTRAINT fk_producto FOREIGN KEY (producto_id) REFERENCES producto(id),
    CONSTRAINT fk_promocion FOREIGN KEY (promocion_id) REFERENCES promocion(id)
);

-- Tabla: Imagen
CREATE TABLE imagen (
    id VARCHAR PRIMARY KEY,
    producto_variante_id VARCHAR NOT NULL,
    url_imagen TEXT NOT NULL, -- Se usa URL o path por eficiencia
    CONSTRAINT fk_variante_imagen FOREIGN KEY (producto_variante_id) REFERENCES producto_variante(id)
);


-- Tabla: Usuario
CREATE TABLE usuario (
    id VARCHAR(50) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    email VARCHAR(30) UNIQUE NOT NULL,
    password VARCHAR(30) NOT NULL,
    rol rol_usuario DEFAULT 'cliente',
    suscrito BOOLEAN DEFAULT FALSE
);

-- Tabla: Proveedor
CREATE TABLE proveedor (
    id VARCHAR PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    contacto TEXT
);

-- Tabla: CompraProveedor (N a N o Histórico de costos)
CREATE TABLE compra_proveedor (
    id VARCHAR PRIMARY KEY,
    proveedor_id VARCHAR NOT NULL,
    producto_variante_id VARCHAR NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    fecha DATE DEFAULT CURRENT_DATE,
    costo DECIMAL(12, 2) NOT NULL CHECK (costo >= 0),
    CONSTRAINT fk_proveedor_compra FOREIGN KEY (proveedor_id) REFERENCES proveedor(id),
    CONSTRAINT fk_variante_compra FOREIGN KEY (producto_variante_id) REFERENCES producto_variante(id)
);


-- Tabla: Direccion
CREATE TABLE direccion (
    id VARCHAR PRIMARY KEY,
    usuario_id VARCHAR NOT NULL,
    calle VARCHAR(30) NOT NULL,
    numero VARCHAR(30),
    codigo_postal VARCHAR(5) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    provincia VARCHAR(50) NOT NULL,
    CONSTRAINT fk_usuario_dir FOREIGN KEY (usuario_id) REFERENCES usuario(id)
);

-- Tabla: Opinion
CREATE TABLE opinion (
    id VARCHAR PRIMARY KEY,
    usuario_id VARCHAR NOT NULL,
    producto_variante_id VARCHAR NOT NULL,
    estrellas INT CHECK (estrellas BETWEEN 1 AND 5),
    comentario TEXT,
    fecha DATE DEFAULT CURRENT_DATE,
    CONSTRAINT fk_usuario_op FOREIGN KEY (usuario_id) REFERENCES usuario(id),
    CONSTRAINT fk_variante_op FOREIGN KEY (producto_variante_id) REFERENCES producto_variante(id)
);

-- Tabla: Favorito
CREATE TABLE favorito (
    id VARCHAR PRIMARY KEY,
    usuario_id VARCHAR NOT NULL,
    producto_variante_id VARCHAR NOT NULL,
    CONSTRAINT fk_usuario_fav FOREIGN KEY (usuario_id) REFERENCES usuario(id),
    CONSTRAINT fk_variante_fav FOREIGN KEY (producto_variante_id) REFERENCES producto_variante(id),
    CONSTRAINT unique_usuario_producto UNIQUE (usuario_id, producto_variante_id)
);

-- Tabla: Carrito
CREATE TABLE carrito (
    id VARCHAR PRIMARY KEY,
    usuario_id VARCHAR NOT NULL,
    total DECIMAL(12, 2) DEFAULT 0,
    descuento_total DECIMAL(12, 2) DEFAULT 0,
    estado estado_carrito DEFAULT 'abierto',
    CONSTRAINT fk_usuario_cart FOREIGN KEY (usuario_id) REFERENCES usuario(id)
);

-- Tabla: CarritoItem
CREATE TABLE carrito_item (
    id VARCHAR PRIMARY KEY,
    carrito_id VARCHAR NOT NULL,
    producto_variante_id VARCHAR NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(12, 2) NOT NULL CHECK (precio_unitario >= 0),
    descuento_unitario DECIMAL(12, 2) DEFAULT 0,
    CONSTRAINT fk_carrito FOREIGN KEY (carrito_id) REFERENCES carrito(id),
    CONSTRAINT fk_variante_cart_item FOREIGN KEY (producto_variante_id) REFERENCES producto_variante(id)
);

-- Tabla: Compra (Venta finalizada)
CREATE TABLE compra (
    id VARCHAR PRIMARY KEY,
    usuario_id VARCHAR NOT NULL,
    numero VARCHAR UNIQUE NOT NULL,
    fecha DATE DEFAULT CURRENT_DATE,
    total DECIMAL(12, 2) NOT NULL  CHECK (total >= 0),
    descuento_total DECIMAL(12, 2) DEFAULT 0,
    estado_pago estado_pago NOT NULL,
    CONSTRAINT fk_usuario_compra FOREIGN KEY (usuario_id) REFERENCES usuario(id)
);

-- Tabla: LineaDeCompra
CREATE TABLE linea_de_compra (
    id VARCHAR PRIMARY KEY,
    compra_id VARCHAR NOT NULL,
    producto_variante_id VARCHAR NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(12, 2) NOT NULL CHECK (precio_unitario >= 0),
    descuento_unitario DECIMAL(12, 2) DEFAULT 0,
    CONSTRAINT fk_compra FOREIGN KEY (compra_id) REFERENCES compra(id),
    CONSTRAINT fk_variante_linea FOREIGN KEY (producto_variante_id) REFERENCES producto_variante(id)
);

-- Tabla: Combo
CREATE TABLE combo (
    id VARCHAR PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
    producto_variante_id VARCHAR NOT NULL REFERENCES producto_variante(id) -- Representante del combo
);

-- Tabla: ComboItem

/*
Se optó por un modelo de Variante Representante para los combos. Esto permite que cada combo herede las 
capacidades de un producto normal (galería de imágenes, sistema de reseñas y categorización) sin duplicar
la estructura de la base de datos. La integridad del inventario se mantiene mediante la relación en ComboItem,
que vincula la oferta comercial con las existencias físicas de cada camisa individual."
*/

CREATE TABLE combo_item (
    combo_id VARCHAR REFERENCES Combo(id),
    producto_variante_id VARCHAR REFERENCES producto_variante(id),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    PRIMARY KEY (combo_id, producto_variante_id)
);

COMMIT;