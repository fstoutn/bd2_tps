# spec: indice_top_productos
Objetivo: Acelerar la consulta de los 5 productos más vendidos.
Consulta afectada: Consulta 2 (JOIN entre producto, detalle_pedido y pedido con agregación de cantidad).
Columnas candidatas a indexar: 
  - detalle_pedido(producto_id, cantidad)
  - pedido(id)
Criterio de aceptación: Optimizar los JOINs y agrupamientos reduciendo el tiempo en EXPLAIN ANALYZE.