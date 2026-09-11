# TP4 — Parte 1

## Laboratorio: consultas analíticas lentas

### Objetivo

Analizar consultas analíticas sobre la base de datos Food Store utilizando `EXPLAIN ANALYZE`, identificar los algoritmos de JOIN utilizados por PostgreSQL, solicitar propuestas de optimización mediante IA y validar las propuestas mediante nuevas mediciones.

Todas las mediciones se realizaron sobre la copia de trabajo `food_store_tp4`, utilizando la base masivamente poblada al finalizar la Semana 3.

---

# Consulta 1 — Facturación por categoría y mes

## Consulta original

```sql
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
```

## Plan inicial

### Tiempo

**Execution Time: 1284.808 ms**

### Algoritmos de JOIN identificados

1. `detalle_pedido` + `producto`:

   * **Hash Join**
   * Condición: `dp.producto_id = p.id`

2. Resultado + `pedido`:

   * **Parallel Hash Join**
   * Condición: `dp.pedido_id = pe.id`

3. Resultado + `categoria`:

   * **Nested Loop + Memoize**
   * PostgreSQL realizó 400249 hits y solamente 4 misses en `Memoize`.

El `Nested Loop` final no fue considerado problemático, ya que el `Memoize` evitó repetir las búsquedas sobre `categoria`.

### Otros aspectos relevantes

El plan inicial presentó operaciones `external merge` durante los ordenamientos de los trabajadores, utilizando espacio temporal en disco. Esto indicó presión sobre `work_mem`.

---

## Optimización 1 — Aumento de `work_mem`

La primera propuesta de IA fue aumentar `work_mem` de manera temporal para la ejecución de la consulta.

Se utilizó:

```sql
BEGIN;

SET LOCAL work_mem = '32MB';

EXPLAIN ANALYZE
-- consulta original

ROLLBACK;
```

### Resultado

**Execution Time: 1116.708 ms**

El ordenamiento cambió de:

```text
external merge
```

a:

```text
quicksort
```

y pasó a realizarse en memoria, sin utilizar disco temporal.

### Comparación

* Tiempo inicial: **1284.808 ms**
* Tiempo con `work_mem = 32MB`: **1116.708 ms**
* Mejora absoluta: **168.100 ms**
* Mejora porcentual: **13.09%**
* Factor: aproximadamente **1.15x**

Los algoritmos de JOIN no cambiaron.

### Decisión

**Aceptada.**

La propuesta fue aceptada porque produjo una mejora medible y el plan mostró evidencia concreta de que el ordenamiento dejó de utilizar disco.

---

## Optimización 2 — Agregación antes del JOIN con `categoria`

La segunda propuesta consistió en realizar primero la agregación por categoría y mes y unir posteriormente el resultado reducido con `categoria`.

```sql
WITH facturacion AS (
    SELECT
        p.categoria_id,
        DATE_TRUNC('month', pe.fecha_hora) AS mes,
        SUM(dp.subtotal) AS facturacion_total
    FROM producto p
    JOIN detalle_pedido dp
        ON dp.producto_id = p.id
    JOIN pedido pe
        ON pe.id = dp.pedido_id
    GROUP BY
        p.categoria_id,
        DATE_TRUNC('month', pe.fecha_hora)
)
SELECT
    c.nombre AS categoria,
    f.mes,
    f.facturacion_total
FROM facturacion f
JOIN categoria c
    ON c.id = f.categoria_id
ORDER BY
    f.mes,
    f.facturacion_total DESC;
```

### Resultado

**Execution Time: 536.027 ms**

El resultado de la agregación quedó reducido a solamente 28 filas antes del JOIN con `categoria`.

El JOIN final cambió de:

```text
Nested Loop + Memoize
```

a:

```text
Hash Join
```

El ordenamiento final solamente tuvo que ordenar 28 filas y utilizó aproximadamente 26 kB de memoria.

### Comparación

* Tiempo original: **1284.808 ms**
* Tiempo final: **536.027 ms**
* Mejora absoluta: **748.781 ms**
* Mejora porcentual: **58.27%**
* Factor de mejora: aproximadamente **2.40x**

Comparado con la primera optimización:

* Con `work_mem`: **1116.708 ms**
* Con la reescritura: **536.027 ms**
* Mejora adicional: aproximadamente **2.08x**

### Verificación de equivalencia

Se compararon los resultados de la consulta original y la reescrita mediante `EXCEPT` en ambas direcciones.

Resultado:

* Original `EXCEPT` reescrita: **0 filas**
* Reescrita `EXCEPT` original: **0 filas**

Por lo tanto, ambas consultas producen el mismo resultado.

### Decisión

**Aceptada.**

La propuesta fue aceptada porque produjo una mejora significativa y medible, reduciendo el tiempo de ejecución en aproximadamente un 58.27%.

---

# Consulta 2 — Top 5 productos más vendidos

## Consulta original

```sql
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
```

## Plan inicial

### Tiempo

**Execution Time: 491.697 ms**

### Algoritmos de JOIN identificados

1. `detalle_pedido` + `producto`:

   * **Hash Join**
   * Condición: `dp.producto_id = p.id`

2. Resultado + `pedido`:

   * **Parallel Hash Join**
   * Condición: `dp.pedido_id = pe.id`

### Otros aspectos relevantes

La consulta utilizó agregación paralela:

```text
Partial HashAggregate
        ↓
Gather
        ↓
Finalize HashAggregate
```

El `Sort` utilizó:

```text
top-N heapsort
```

con solamente 25 kB de memoria debido al `LIMIT 5`.

No se observaron derrames a disco en los agregados (`Batches: 1`), por lo que no se consideró necesario aumentar `work_mem`.

---

## Optimización 1 — Eliminación del JOIN redundante con `pedido`

Se verificó que `detalle_pedido.pedido_id` posee una clave foránea válida hacia `pedido.id` y que no existen registros huérfanos.

Por este motivo, el JOIN con `pedido` no modifica el resultado de la consulta, ya que no se utilizan columnas de `pedido` ni se aplican filtros sobre dicha tabla.

La consulta quedó:

```sql
SELECT
    p.id,
    p.nombre,
    SUM(dp.cantidad) AS unidades_vendidas
FROM producto p
JOIN detalle_pedido dp
    ON dp.producto_id = p.id
GROUP BY
    p.id,
    p.nombre
ORDER BY
    unidades_vendidas DESC,
    p.id ASC
LIMIT 5;
```

### Resultado

**Execution Time: 449.000 ms**

Desaparecieron del plan:

* `Parallel Hash Join` con `pedido`
* `Parallel Seq Scan` sobre `pedido`
* construcción del hash correspondiente a `pedido`

### Comparación

* Tiempo inicial: **491.697 ms**
* Tiempo optimizado: **449.000 ms**
* Mejora absoluta: **42.697 ms**
* Mejora porcentual: **8.68%**
* Factor: aproximadamente **1.10x**

### Decisión

**Aceptada como mejora parcial.**

La propuesta produjo una mejora medible, pero posteriormente se evaluó una segunda reescritura que obtuvo un resultado considerablemente mejor.

---

## Optimización 2 — Preagregación de `detalle_pedido`

La segunda propuesta consistió en agrupar primero `detalle_pedido` por producto y realizar posteriormente el JOIN con `producto`.

```sql
WITH ventas AS (
    SELECT
        dp.producto_id,
        SUM(dp.cantidad) AS unidades_vendidas
    FROM detalle_pedido dp
    GROUP BY dp.producto_id
)
SELECT
    p.id,
    p.nombre,
    v.unidades_vendidas
FROM ventas v
JOIN producto p
    ON p.id = v.producto_id
ORDER BY
    v.unidades_vendidas DESC,
    p.id ASC
LIMIT 5;
```

### Resultado

**Execution Time: 280.695 ms**

La agregación se realizó primero sobre `detalle_pedido`, reduciendo las aproximadamente 400.253 filas de detalles a 49.981 grupos por producto antes de realizar el JOIN con `producto`.

El plan final utilizó:

```text
HashAggregate
        ↓
Hash Join
        ↓
top-N heapsort
        ↓
Limit
```

### Comparación

* Tiempo original: **491.697 ms**
* Tiempo final: **280.695 ms**
* Mejora absoluta: **211.002 ms**
* Mejora porcentual: **42.91%**
* Factor de mejora: aproximadamente **1.75x**

### Verificación de equivalencia

Se compararon los resultados de la consulta original y la reescrita.

Ambas consultas devolvieron exactamente los mismos cinco productos, en el mismo orden y con las mismas cantidades vendidas.

Resultado observado:

```text
63419  Producto Test #23494  110
88814  Producto Test #38804  100
96939  Producto Test #31144  100
64914  Producto Test #36298   95
91544  Producto Test #16932   95
```

### Decisión

**Aceptada.**

La propuesta fue aceptada porque obtuvo una mejora considerable respecto de la consulta original y fue verificada mediante comparación de resultados.

---

# Tabla comparativa final

| Consulta                        | Tiempo inicial | Cambio aplicado                                                    | Tiempo final |     Mejora |    Factor |
| ------------------------------- | -------------: | ------------------------------------------------------------------ | -----------: | ---------: | --------: |
| Facturación por categoría y mes |    1284.808 ms | `work_mem = 32MB` + preagregación antes de `categoria`             |   536.027 ms | **58.27%** | **2.40x** |
| Top 5 productos más vendidos    |     491.697 ms | Eliminación de JOIN redundante + preagregación de `detalle_pedido` |   280.695 ms | **42.91%** | **1.75x** |

# Conclusiones de la Parte 1

Las mediciones permitieron comprobar que no todas las optimizaciones propuestas por IA deben aplicarse automáticamente.

En la consulta de facturación, aumentar `work_mem` produjo una mejora moderada al evitar el uso de disco durante el ordenamiento. Sin embargo, la mayor mejora se obtuvo al modificar el orden de las operaciones y realizar la agregación antes del JOIN con `categoria`.

En la consulta de productos más vendidos, eliminar el JOIN redundante con `pedido` produjo una mejora del 8.68%. La mayor mejora se obtuvo al preagrupar `detalle_pedido` por producto antes de realizar el JOIN con `producto`.

En ambos casos, las decisiones fueron tomadas a partir de mediciones reales mediante `EXPLAIN ANALYZE`, y no únicamente a partir de las recomendaciones de la IA.

No se agregaron nuevos índices durante estas optimizaciones, ya que los planes analizados no mostraron evidencia suficiente para justificar su incorporación.
