# 🐘 Core Relacional & Motor Transaccional para E-Commerce (PostgreSQL)

> Arquitectura de base de datos *Thick-Database* diseñada para gestionar la lógica de negocio, concurrencia e integridad referencial de una plataforma de comercio electrónico a nivel del motor relacional.

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![PL/pgSQL](https://img.shields.io/badge/PL/pgSQL-000000?style=flat&logo=database&logoColor=white)
![Testing](https://img.shields.io/badge/Testing-Automated_SQL-green?style=flat)

## 📌 Arquitectura y Paradigma
Este repositorio contiene el núcleo de datos de un e-commerce completo. En lugar de delegar la validación de reglas de negocio a la capa de aplicación (Backend), el sistema implementa un paradigma donde la base de datos es la máxima autoridad. Garantiza transacciones ACID, previene condiciones de carrera (race conditions) en el inventario y audita la seguridad de los datos de forma autónoma.

## 🚀 Capacidades Técnicas Destacadas

* **Gestión Polimórfica de Carrito y Combos Virtuales:** Implementación de *Stored Procedures* que permiten agrupar productos individuales y "Combos Virtuales". El sistema calcula dinámicamente el stock real de un combo buscando el cuello de botella (patrón Pivot) entre los componentes que lo integran mediante funciones recursivas en `PL/pgSQL`.
* **Seguridad y RBAC (Role-Based Access Control):** Aislamiento de capas de abstracción. Los clientes no tienen acceso directo a las tablas transaccionales; operan exclusivamente a través de *Views* de solo lectura y *Stored Procedures* con permisos granulares (GRANT/REVOKE).
* **Triggers de Auditoría y Reglas de Negocio:**
  * `trg_validar_confirmacion_pago`: Previene el *overselling* validando el inventario milisegundos antes de confirmar el checkout.
  * `trg_validar_cliente_opinion`: Sistema anti-fraude que cruza la tabla de compras históricas para bloquear reseñas de usuarios que no hayan adquirido efectivamente el producto.
  * `trg_validar_promo`: Invalidación automática de ítems promocionales en carritos abandonados una vez que la campaña expira.
* **Vistas de Abstracción (Data Abstraction Layer):** Vistas materializadas lógicamente (`v_producto_detalle`, `v_carrito_detalle`) que utilizan *Array Aggregation* (`ARRAY_AGG`) para consolidar galerías de imágenes y atributos, entregando JSON-ready data al frontend y reduciendo el cómputo del ORM.

## 📂 Estructura del Motor

El motor se inicializa de forma determinista y topológica a través de 10 etapas:

1. `01-creacion-tablas.sql`: DDL idempotente, tipos enumerados (ENUMS) y extensión pgcrypto para UUIDs.
2. `02-funciones.sql`: Lógica computacional y de negocio.
3. `03-vistas.sql`: Capa de lectura optimizada.
4. `04-procedimientos.sql`: Bloques transaccionales (Checkout, Pagos, Ingreso de Stock).
5. `05-triggers.sql`: Eventos automatizados y validaciones asíncronas.
6. `06-usuarios-permisos.sql`: Definición de perfiles (Admin vs Cliente).
7. `07-carga-datos.sql`: Seeding de catálogo, promociones e inventario base.
8. `08 a 10-testing.sql`: Entorno de pruebas y control de robustez.

## 🧪 Pruebas de Robustez Integradas
El repositorio incluye rutinas de testing directamente escritas en SQL (`DO $$ bloques anónimos`) que simulan:
- Intentos de inyección de opiniones fraudulentas.
- Compra concurrente superando el stock máximo disponible.
- Pagos duplicados y caducidad de carritos mixtos.
- Comprobación de integridad tras confirmación transaccional.

## ⚙️ Despliegue Local

Para inicializar el motor en cualquier entorno Linux/Unix con PostgreSQL:

```bash
# 1. Crear la base de datos
createdb ecommerce_engine_db

# 2. Ejecutar la secuencia de inicialización (ejemplo de los primeros 3 scripts)
psql -d ecommerce_engine_db -f 01-creacion-tablas.sql
psql -d ecommerce_engine_db -f 02-funciones.sql
psql -d ecommerce_engine_db -f 03-vistas.sql
psql -d ecommerce_engine_db -f 04-procedimientos.sql
psql -d ecommerce_engine_db -f 05-triggers.sql
psql -d ecommerce_engine_db -f 06-usuarios-permisos.sql
psql -d ecommerce_engine_db -f 07-carga-datos.sql
```
