# spec: vista_materializada_facturacion

Objetivo: Acelerar la consulta del reporte gerencial de facturación por categoría y mes.

Consulta afectada:
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
GROUP BY 1, 2, 3, 4;

Columnas candidatas: pe.fecha_hora, dp.pedido_id, dp.producto_id, p.categoria_id.

Criterio de aceptación:
- La consulta pasa de ejecutar múltiples JOINs a consultar registros precalculados.
- La vista materializada se crea con la opción WITH DATA.
- Se crea el índice único idx_mv_facturacion_cat_mes sobre (anio, mes, categoria_id) para habilitar REFRESH MATERIALIZED VIEW CONCURRENTLY.