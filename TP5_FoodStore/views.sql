-- =====================================================
-- PARTE B: Vistas para reportes del sistema
-- =====================================================

-- 1. Vista de productos vigentes con su categoría
CREATE OR REPLACE VIEW vw_productos_vigentes AS
SELECT 
    p.id AS producto_id,
    p.nombre AS producto_nombre,
    c.nombre AS categoria_nombre
FROM producto p
JOIN categoria c ON c.id = p.categoria_id;

-- 2. Vista de pedidos con datos de usuario (Seguridad: Oculta la columna contraseña)
CREATE OR REPLACE VIEW vw_pedidos_usuario AS
SELECT 
    pe.id AS pedido_id,
    pe.fecha_hora,
    u.id AS usuario_id,
    u.nombre AS usuario_nombre,
    u.email
FROM pedido pe
JOIN usuario u ON u.id = pe.usuario_id;

-- 3. Vista de detalle de pedido con el nombre del producto
CREATE OR REPLACE VIEW vw_detalle_pedido_producto AS
SELECT 
    dp.id AS detalle_id,
    dp.pedido_id,
    dp.producto_id,
    p.nombre AS producto_nombre,
    dp.cantidad,
    dp.subtotal
FROM detalle_pedido dp
JOIN producto p ON p.id = dp.producto_id;

-- =====================================================
-- PARTE C: Vista Materializada para Reporte Analítico
-- =====================================================

CREATE MATERIALIZED VIEW mv_facturacion_categoria_mes AS
SELECT 
    EXTRACT(YEAR FROM pe.fecha_hora)::integer AS anio,
    EXTRACT(MONTH FROM pe.fecha_hora)::integer AS mes,
    c.id AS categoria_id,
    c.nombre AS categoria_nombre,
    SUM(dp.subtotal) AS total_facturado,
    COUNT(DISTINCT pe.id) AS cantidad_pedidos
FROM pedido pe
JOIN detalle_pedido dp ON dp.pedido_id = pe.id
JOIN producto p ON p.id = dp.producto_id
JOIN categoria c ON c.id = p.categoria_id
GROUP BY 
    EXTRACT(YEAR FROM pe.fecha_hora),
    EXTRACT(MONTH FROM pe.fecha_hora),
    c.id,
    c.nombre
WITH DATA;

-- Índice único requerido para REFRESH MATERIALIZED VIEW CONCURRENTLY
CREATE UNIQUE INDEX idx_mv_facturacion_cat_mes 
ON mv_facturacion_categoria_mes (anio, mes, categoria_id);