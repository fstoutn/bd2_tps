-- Consulta 1: Facturación por categoría y mes
CREATE INDEX idx_detalle_pedido_pedido_id ON detalle_pedido(pedido_id);
CREATE INDEX idx_detalle_pedido_producto_id ON detalle_pedido(producto_id);
CREATE INDEX idx_pedido_fecha_hora ON pedido(fecha_hora);

-- Consulta 2: Top 5 productos más vendidos
CREATE INDEX idx_detalle_pedido_prod_cant ON detalle_pedido(producto_id, cantidad);
