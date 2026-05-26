-- ==========================================================
-- SCRIPT 05: 05-triggers.sql
-- Purpose: Instantiate and bind automated trigger events.
-- ==========================================================

-- 1. DROP EXISTING TRIGGERS
DROP TRIGGER IF EXISTS trg_carrito_item_valida_stock ON carrito_item CASCADE;
DROP TRIGGER IF EXISTS trg_compra_validar_stock_final ON compra CASCADE;
DROP TRIGGER IF EXISTS trg_actualizar_total_carrito ON carrito_item CASCADE;
DROP TRIGGER IF EXISTS trg_validar_promo ON carrito_item CASCADE;
DROP TRIGGER IF EXISTS trg_validar_cliente_opinion ON opinion CASCADE;
DROP TRIGGER IF EXISTS trg_validar_favorito ON favorito CASCADE;

-- 2. TRIGGERS DEFINITION

-- trg_carrito_item_valida_stock: Validates stock on cart update
CREATE TRIGGER trg_carrito_item_valida_stock
BEFORE INSERT OR UPDATE ON carrito_item
FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_disponibilidad();

-- trg_compra_validar_stock_final: Re-validates stock on checkout
CREATE TRIGGER trg_compra_validar_stock_final
BEFORE UPDATE OF estado_pago ON compra
FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_confirmacion_pago();

-- trg_actualizar_total_carrito: Syncs total back to cart
CREATE TRIGGER trg_actualizar_total_carrito
AFTER INSERT OR UPDATE OR DELETE ON carrito_item
FOR EACH ROW EXECUTE FUNCTION fn_trg_actualizar_total_carrito();

-- trg_validar_promo: Rejects cart additions if promo expired
CREATE TRIGGER trg_validar_promo
BEFORE INSERT OR UPDATE ON carrito_item
FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_promo();

-- trg_validar_cliente_opinion: Blocks review from users who haven't bought
CREATE TRIGGER trg_validar_cliente_opinion
BEFORE INSERT ON opinion
FOR EACH ROW EXECUTE FUNCTION fn_trg_validar_cliente_opinion();

