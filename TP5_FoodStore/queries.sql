-- ============================================================
-- TP4 - Consultas analíticas para laboratorio de JOINs
-- Reconstruidas a partir de las consultas trabajadas en TP3
-- ============================================================


-- ============================================================
-- CONSULTA 1
-- Facturación por categoría y mes
--
-- Tablas involucradas:
-- categoria
-- producto
-- detalle_pedido
-- pedido
--
-- Objetivo:
-- Obtener la facturación total de cada categoría agrupada
-- por año y mes.
-- ============================================================

SELECT
    c.nombre AS categoria,
    DATE_TRUNC('month', pe.fecha_hora) AS mes,
    SUM(dp.subtotal) AS facturacion_total
FROM categoria c
JOIN producto p
    ON p.categoria_id = c.id
JOIN detalle_pedido dp
    ON dp.producto_id = p.id
JOIN pedido pe
    ON pe.id = dp.pedido_id
GROUP BY
    c.id,
    c.nombre,
    DATE_TRUNC('month', pe.fecha_hora)
ORDER BY
    mes,
    facturacion_total DESC;


-- ============================================================
-- CONSULTA 2
-- Top 5 productos más vendidos
--
-- Tablas involucradas:
-- producto
-- detalle_pedido
-- pedido
--
-- Objetivo:
-- Obtener los 5 productos con mayor cantidad de unidades
-- vendidas.
-- ============================================================

SELECT
    p.id,
    p.nombre,
    SUM(dp.cantidad) AS unidades_vendidas
FROM producto p
JOIN detalle_pedido dp
    ON dp.producto_id = p.id
JOIN pedido pe
    ON pe.id = dp.pedido_id
GROUP BY
    p.id,
    p.nombre
ORDER BY
    unidades_vendidas DESC,
    p.id ASC
LIMIT 5;
