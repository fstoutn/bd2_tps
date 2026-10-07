# spec: indice_facturacion_categoria_mes
Objetivo: Optimizar la consulta de facturación agrupada por categoría y mes.
Consulta afectada: Consulta 1 (JOIN entre pedido, detalle_pedido, producto y categoria).
Columnas candidatas a indexar: 
  - detalle_pedido(pedido_id)
  - detalle_pedido(producto_id)
  - pedido(fecha_hora)
Criterio de aceptación: Evitar Seq Scan en las tablas principales y pasar a Index Scan / Bitmap Scan.