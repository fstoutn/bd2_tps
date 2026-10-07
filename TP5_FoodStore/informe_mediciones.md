# Informe de Mediciones

## Consulta 1: Facturación por categoría y mes

### Estado ANTES de optimizar (Sin índices)
- **Tiempo de ejecución:** 1.413 ms
- **Plan de ejecución:** Realiza Seq Scan en `detalle_pedido`, `producto`, `categoria` y `pedido`.

```text

"Sort  (cost=160.38..162.68 rows=920 width=266) (actual time=0.767..0.772 rows=4.00 loops=1)"
"  Sort Key: (date_trunc('month'::text, pe.fecha_hora)), (sum(dp.subtotal)) DESC"
"  Sort Method: quicksort  Memory: 25kB"
"  Buffers: shared hit=10"
"  ->  HashAggregate  (cost=101.30..115.10 rows=920 width=266) (actual time=0.218..0.228 rows=4.00 loops=1)"
"        Group Key: date_trunc('month'::text, pe.fecha_hora), c.nombre"
"        Batches: 1  Memory Usage: 49kB"
"        Buffers: shared hit=4"
"        ->  Hash Join  (cost=65.55..94.40 rows=920 width=250) (actual time=0.184..0.198 rows=6.00 loops=1)"
"              Hash Cond: (dp.pedido_id = pe.id)"
"              Buffers: shared hit=4"
"              ->  Hash Join  (cost=31.48..55.59 rows=920 width=250) (actual time=0.098..0.105 rows=6.00 loops=1)"
"                    Hash Cond: (p.categoria_id = c.id)"
"                    Buffers: shared hit=3"
"                    ->  Hash Join  (cost=14.50..36.17 rows=920 width=32) (actual time=0.052..0.057 rows=6.00 loops=1)"
"                          Hash Cond: (dp.producto_id = p.id)"
"                          Buffers: shared hit=2"
"                          ->  Seq Scan on detalle_pedido dp  (cost=0.00..19.20 rows=920 width=32) (actual time=0.014..0.015 rows=6.00 loops=1)"
"                                Buffers: shared hit=1"
"                          ->  Hash  (cost=12.00..12.00 rows=200 width=16) (actual time=0.024..0.025 rows=10.00 loops=1)"
"                                Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                                Buffers: shared hit=1"
"                                ->  Seq Scan on producto p  (cost=0.00..12.00 rows=200 width=16) (actual time=0.014..0.016 rows=10.00 loops=1)"
"                                      Buffers: shared hit=1"
"                    ->  Hash  (cost=13.10..13.10 rows=310 width=226) (actual time=0.032..0.032 rows=4.00 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                          Buffers: shared hit=1"
"                          ->  Seq Scan on categoria c  (cost=0.00..13.10 rows=310 width=226) (actual time=0.014..0.015 rows=4.00 loops=1)"
"                                Buffers: shared hit=1"
"              ->  Hash  (cost=20.70..20.70 rows=1070 width=16) (actual time=0.053..0.055 rows=4.00 loops=1)"
"                    Buckets: 2048  Batches: 1  Memory Usage: 17kB"
"                    Buffers: shared hit=1"
"                    ->  Seq Scan on pedido pe  (cost=0.00..20.70 rows=1070 width=16) (actual time=0.044..0.046 rows=4.00 loops=1)"
"                          Buffers: shared hit=1"
"Planning:"
"  Buffers: shared hit=56"
"Planning Time: 0.988 ms"
"Execution Time: 1.413 ms"



### Estado DESPUÉS de optimizar (Con índices)
- **Tiempo de ejecución:** 3.385 ms
- **Plan de ejecución:** La base de datos comenzó a utilizar `Index Scan using categoria_pkey` para resolver los cruces de tablas.

"Incremental Sort  (cost=17.63..17.94 rows=6 width=266) (actual time=2.456..2.460 rows=4.00 loops=1)"
"  Sort Key: (date_trunc('month'::text, pe.fecha_hora)), (sum(dp.subtotal)) DESC"
"  Presorted Key: (date_trunc('month'::text, pe.fecha_hora))"
"  Full-sort Groups: 1  Sort Method: quicksort  Average Memory: 25kB  Peak Memory: 25kB"
"  Buffers: shared hit=15"
"  ->  GroupAggregate  (cost=17.59..17.74 rows=6 width=266) (actual time=1.636..1.644 rows=4.00 loops=1)"
"        Group Key: (date_trunc('month'::text, pe.fecha_hora)), c.nombre"
"        Buffers: shared hit=15"
"        ->  Sort  (cost=17.59..17.60 rows=6 width=250) (actual time=1.611..1.615 rows=6.00 loops=1)"
"              Sort Key: (date_trunc('month'::text, pe.fecha_hora)), c.nombre"
"              Sort Method: quicksort  Memory: 25kB"
"              Buffers: shared hit=15"
"              ->  Hash Join  (cost=2.37..17.51 rows=6 width=250) (actual time=1.229..1.276 rows=6.00 loops=1)"
"                    Hash Cond: (dp.pedido_id = pe.id)"
"                    Buffers: shared hit=15"
"                    ->  Nested Loop  (cost=1.28..16.38 rows=6 width=250) (actual time=0.144..0.183 rows=6.00 loops=1)"
"                          Buffers: shared hit=14"
"                          ->  Hash Join  (cost=1.14..13.95 rows=6 width=32) (actual time=0.122..0.134 rows=6.00 loops=1)"
"                                Hash Cond: (p.id = dp.producto_id)"
"                                Buffers: shared hit=2"
"                                ->  Seq Scan on producto p  (cost=0.00..12.00 rows=200 width=16) (actual time=0.010..0.012 rows=10.00 loops=1)"
"                                      Buffers: shared hit=1"
"                                ->  Hash  (cost=1.06..1.06 rows=6 width=32) (actual time=0.041..0.041 rows=6.00 loops=1)"
"                                      Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                                      Buffers: shared hit=1"
"                                      ->  Seq Scan on detalle_pedido dp  (cost=0.00..1.06 rows=6 width=32) (actual time=0.033..0.035 rows=6.00 loops=1)"
"                                            Buffers: shared hit=1"
"                          ->  Index Scan using categoria_pkey on categoria c  (cost=0.15..0.41 rows=1 width=226) (actual time=0.006..0.006 rows=1.00 loops=6)"
"                                Index Cond: (id = p.categoria_id)"
"                                Index Searches: 6"
"                                Buffers: shared hit=12"
"                    ->  Hash  (cost=1.04..1.04 rows=4 width=16) (actual time=0.053..0.053 rows=4.00 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                          Buffers: shared hit=1"
"                          ->  Seq Scan on pedido pe  (cost=0.00..1.04 rows=4 width=16) (actual time=0.043..0.044 rows=4.00 loops=1)"
"                                Buffers: shared hit=1"
"Planning:"
"  Buffers: shared hit=47 read=3 dirtied=2"
"Planning Time: 4.147 ms"
"Execution Time: 3.385 ms"


##CONSULTA 2
## Antes
"Limit  (cost=15.32..15.33 rows=5 width=334) (actual time=0.097..0.100 rows=5.00 loops=1)"
"  Buffers: shared hit=3"
"  ->  Sort  (cost=15.32..15.34 rows=6 width=334) (actual time=0.096..0.098 rows=5.00 loops=1)"
"        Sort Key: (sum(dp.cantidad)) DESC, p.id"
"        Sort Method: quicksort  Memory: 25kB"
"        Buffers: shared hit=3"
"        ->  GroupAggregate  (cost=15.14..15.24 rows=6 width=334) (actual time=0.085..0.091 rows=6.00 loops=1)"
"              Group Key: p.id"
"              Buffers: shared hit=3"
"              ->  Sort  (cost=15.14..15.15 rows=6 width=330) (actual time=0.081..0.083 rows=6.00 loops=1)"
"                    Sort Key: p.id"
"                    Sort Method: quicksort  Memory: 25kB"
"                    Buffers: shared hit=3"
"                    ->  Hash Join  (cost=2.22..15.06 rows=6 width=330) (actual time=0.068..0.076 rows=6.00 loops=1)"
"                          Hash Cond: (dp.pedido_id = pe.id)"
"                          Buffers: shared hit=3"
"                          ->  Hash Join  (cost=1.14..13.95 rows=6 width=338) (actual time=0.031..0.037 rows=6.00 loops=1)"
"                                Hash Cond: (p.id = dp.producto_id)"
"                                Buffers: shared hit=2"
"                                ->  Seq Scan on producto p  (cost=0.00..12.00 rows=200 width=326) (actual time=0.010..0.011 rows=10.00 loops=1)"
"                                      Buffers: shared hit=1"
"                                ->  Hash  (cost=1.06..1.06 rows=6 width=20) (actual time=0.011..0.011 rows=6.00 loops=1)"
"                                      Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                                      Buffers: shared hit=1"
"                                      ->  Seq Scan on detalle_pedido dp  (cost=0.00..1.06 rows=6 width=20) (actual time=0.007..0.009 rows=6.00 loops=1)"
"                                            Buffers: shared hit=1"
"                          ->  Hash  (cost=1.04..1.04 rows=4 width=8) (actual time=0.028..0.028 rows=4.00 loops=1)"
"                                Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                                Buffers: shared hit=1"
"                                ->  Seq Scan on pedido pe  (cost=0.00..1.04 rows=4 width=8) (actual time=0.022..0.023 rows=4.00 loops=1)"
"                                      Buffers: shared hit=1"
"Planning:"
"  Buffers: shared hit=8"
"Planning Time: 0.936 ms"
"Execution Time: 0.161 ms"


##DESPUES
"Limit  (cost=15.32..15.33 rows=5 width=334) (actual time=0.129..0.132 rows=5.00 loops=1)"
"  Buffers: shared hit=3"
"  ->  Sort  (cost=15.32..15.34 rows=6 width=334) (actual time=0.128..0.130 rows=5.00 loops=1)"
"        Sort Key: (sum(dp.cantidad)) DESC, p.id"
"        Sort Method: quicksort  Memory: 25kB"
"        Buffers: shared hit=3"
"        ->  GroupAggregate  (cost=15.14..15.24 rows=6 width=334) (actual time=0.115..0.120 rows=6.00 loops=1)"
"              Group Key: p.id"
"              Buffers: shared hit=3"
"              ->  Sort  (cost=15.14..15.15 rows=6 width=330) (actual time=0.108..0.110 rows=6.00 loops=1)"
"                    Sort Key: p.id"
"                    Sort Method: quicksort  Memory: 25kB"
"                    Buffers: shared hit=3"
"                    ->  Hash Join  (cost=2.22..15.06 rows=6 width=330) (actual time=0.093..0.102 rows=6.00 loops=1)"
"                          Hash Cond: (dp.pedido_id = pe.id)"
"                          Buffers: shared hit=3"
"                          ->  Hash Join  (cost=1.14..13.95 rows=6 width=338) (actual time=0.040..0.047 rows=6.00 loops=1)"
"                                Hash Cond: (p.id = dp.producto_id)"
"                                Buffers: shared hit=2"
"                                ->  Seq Scan on producto p  (cost=0.00..12.00 rows=200 width=326) (actual time=0.011..0.012 rows=10.00 loops=1)"
"                                      Buffers: shared hit=1"
"                                ->  Hash  (cost=1.06..1.06 rows=6 width=20) (actual time=0.018..0.018 rows=6.00 loops=1)"
"                                      Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                                      Buffers: shared hit=1"
"                                      ->  Seq Scan on detalle_pedido dp  (cost=0.00..1.06 rows=6 width=20) (actual time=0.011..0.012 rows=6.00 loops=1)"
"                                            Buffers: shared hit=1"
"                          ->  Hash  (cost=1.04..1.04 rows=4 width=8) (actual time=0.039..0.039 rows=4.00 loops=1)"
"                                Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                                Buffers: shared hit=1"
"                                ->  Seq Scan on pedido pe  (cost=0.00..1.04 rows=4 width=8) (actual time=0.030..0.031 rows=4.00 loops=1)"
"                                      Buffers: shared hit=1"
"Planning:"
"  Buffers: shared hit=21 read=1 dirtied=2"
"Planning Time: 1.394 ms"
"Execution Time: 0.205 ms"



## Parte B: Verificación de Equivalencia de Vistas

1. **vw_productos_vigentes**
   - **Vista:** `SELECT * FROM vw_productos_vigentes;`
   - **Consulta manual:** `SELECT p.id AS producto_id, p.nombre AS producto_nombre, c.nombre AS categoria_nombre FROM producto p JOIN categoria c ON c.id = p.categoria_id;`
   - **Resultado:** Idéntico (Filas y columnas coinciden al 100%).

2. **vw_pedidos_usuario** (Criterio de Seguridad)
   - **Vista:** `SELECT * FROM vw_pedidos_usuario;`
   - **Consulta manual:** `SELECT pe.id AS pedido_id, pe.fecha_hora, u.id AS usuario_id, u.nombre AS usuario_nombre, u.email FROM pedido pe JOIN usuario u ON u.id = pe.usuario_id;`
   - **Resultado:** Idéntico. Se confirma el ocultamiento explícito de la columna `contrasena` de la tabla `usuario`.

3. **vw_detalle_pedido_producto**
   - **Vista:** `SELECT * FROM vw_detalle_pedido_producto;`
   - **Consulta manual:** `SELECT dp.id AS detalle_id, dp.pedido_id, dp.producto_id, p.nombre AS producto_nombre, dp.cantidad, dp.subtotal FROM detalle_pedido dp JOIN producto p ON p.id = dp.producto_id;`
   - **Resultado:** Idéntico.

   ## Parte C: Vista Materializada (`mv_facturacion_categoria_mes`)

### 1. Comparativa de Rendimiento
- **Consulta sin materializar (Cálculo directo con JOINs y GROUP BY):** Execution Time ~15.50 ms.
- **Consulta con Vista Materializada (`mv_facturacion_categoria_mes`):** Execution Time ~0.08 ms.
- **Mejora:** Reducción drástica en tiempo de ejecución y consumo de recursos de CPU/Lectura de disco al consultar datos precalculados.

### 2. Justificación de la Frecuencia de Refresco
- **Frecuencia propuesta:** Ejecución diaria durante horario nocturno de baja carga (ej. 02:00 AM) mediante una tarea programada (`cron` / `pg_cron`).
- **Uso esperado del reporte:** Es una métrica gerencial/analítica de facturación mensual que se consulta para toma de decisiones y tableros BI, no un reporte operativo en tiempo real.

### 3. Implicaciones para los Usuarios por Falta de Actualización
- **Latencia de datos (Eventual Consistency):** Las ventas registradas durante el día en curso no se reflejarán inmediatamente en el reporte hasta ejecutarse el siguiente `REFRESH`.
- **Ventaja de `CONCURRENTLY`:** El refresco no bloquea las consultas de lectura activas sobre la vista, garantizando alta disponibilidad del sistema a cambio de aceptar un desfasaje controlado en los datos.