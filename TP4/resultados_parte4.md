# Parte 4 — Competencia de optimizaciones

## Objetivo

En esta parte se seleccionó una consulta analítica con múltiples `JOIN` y agregación para probar distintas propuestas de optimización sugeridas por IA.

La consulta elegida calcula la facturación total por categoría y mes:

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

La consulta involucra cuatro tablas, tres operaciones `JOIN` y una agregación mediante `SUM`.

---

## Línea base

La ejecución inicial se realizó mediante `EXPLAIN ANALYZE`, sin modificar la consulta ni la configuración.

El tiempo obtenido fue:

**Execution Time: 831.841 ms**

El plan presentó:

* `Hash Join` entre `detalle_pedido` y `producto`.
* `Parallel Hash Join` entre el resultado anterior y `pedido`.
* `Nested Loop` con `Memoize` para acceder a `categoria`.
* `GroupAggregate`.
* `Incremental Sort`.
* Ordenamientos paralelos mediante `external merge`.
* Los `Sort` utilizaron espacio en disco temporal.

Un aspecto importante fue:

```text
Sort Method: external merge
Disk: 6016kB
Worker 0: Sort Method: external merge
Disk: 6080kB
Worker 1: Sort Method: external merge
Disk: 5360kB
```

Esto indicó que los ordenamientos estaban derramando datos a disco, por lo que aumentar `work_mem` fue considerado una propuesta directamente respaldada por el plan.

---

## Propuesta 1 — Aumentar `work_mem`

La primera propuesta consistió en utilizar:

```sql
SET LOCAL work_mem = '64MB';
```

La consulta se volvió a ejecutar dentro de una transacción para que el cambio no afectara permanentemente la configuración de la base.

El resultado fue:

**Execution Time: 595.058 ms**

Comparación:

* Línea base: 831.841 ms
* Con `work_mem = 64MB`: 595.058 ms
* Mejora: 236.783 ms
* Reducción: aproximadamente 28.47%
* Factor de mejora: aproximadamente 1.40x

Además del menor tiempo, se observó un cambio concreto en los ordenamientos.

Anteriormente se utilizaba:

```text
Sort Method: external merge
```

Con `work_mem = 64MB` pasó a utilizar:

```text
Sort Method: quicksort
Memory: 12960kB
```

Los workers también dejaron de utilizar `external merge`.

Por lo tanto, esta propuesta fue **aceptada**.

También se produjo un cambio en el plan: el acceso a `categoria` dejó de realizarse mediante `Nested Loop + Memoize` y pasó a utilizar un `Hash Join`. La agregación pasó a una estructura paralela con `Partial GroupAggregate` y `Finalize GroupAggregate`.

---

## Propuesta 2 — Reescritura de la consulta

La segunda propuesta consistió en separar la agregación de la presentación final mediante una CTE:

```sql
WITH facturacion AS (
    SELECT
        c.id AS categoria_id,
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
)
SELECT
    categoria,
    mes,
    facturacion_total
FROM facturacion
ORDER BY
    mes,
    facturacion_total DESC;
```

La prueba se realizó manteniendo `work_mem = 64MB`.

El resultado fue:

**Execution Time: 457.822 ms**

Comparación:

* Línea base: 831.841 ms
* Propuesta 1: 595.058 ms
* Propuesta 2: 457.822 ms

La propuesta 2 obtuvo:

* Mejora respecto de la línea base: 373.019 ms
* Reducción: aproximadamente 44.96%
* Factor de mejora: aproximadamente 1.82x
* Mejora adicional respecto de la propuesta 1: 137.236 ms

La propuesta había planteado que PostgreSQL podría elegir `HashAggregate`, pero esto no ocurrió. El plan continuó utilizando:

```text
Finalize GroupAggregate
    -> Gather Merge
        -> Partial GroupAggregate
```

Por lo tanto, la mejora no se atribuye a `HashAggregate`, sino al plan efectivamente elegido por PostgreSQL y a la eliminación del ordenamiento externo gracias a `work_mem`.

La propuesta fue **aceptada y seleccionada como ganadora**.

---

## Propuesta 3 — Aumentar el paralelismo

La tercera propuesta consistió en probar:

```sql
SET LOCAL max_parallel_workers_per_gather = 4;
```

manteniendo:

```sql
SET LOCAL work_mem = '64MB';
```

El resultado fue:

**Execution Time: 605.570 ms**

Este resultado fue peor que las dos alternativas anteriores:

* Línea base: 831.841 ms
* Propuesta 1: 595.058 ms
* Propuesta 2: 457.822 ms
* Propuesta 3: 605.570 ms

Además, el plan mostró:

```text
Workers Planned: 2
Workers Launched: 2
```

Por lo tanto, aunque se solicitó un máximo de 4 workers, PostgreSQL continuó utilizando solamente 2 workers en esta ejecución.

La propuesta fue **rechazada**, ya que no produjo una mejora y terminó siendo más lenta que la configuración de `work_mem` utilizada anteriormente.

---

## Propuesta 4 — Crear índices

También se evaluó la posibilidad de agregar índices sobre las columnas utilizadas en los `JOIN`, como:

```text
detalle_pedido(pedido_id)
detalle_pedido(producto_id)
pedido(fecha_hora)
```

Sin embargo, esta propuesta no se aplicó.

La consulta no posee filtros `WHERE` que reduzcan significativamente el conjunto de datos y necesita recorrer una gran cantidad de registros de `detalle_pedido` y `pedido`.

El plan ya utilizaba `Parallel Seq Scan` y los `Hash Join` procesaban grandes cantidades de registros. Además, los hash utilizados no presentaban problemas de memoria:

```text
Batches: 1
```

Por lo tanto, no había evidencia suficiente en el plan que justificara crear índices únicamente para esta consulta.

La propuesta quedó **descartada por falta de evidencia**, sin realizar cambios en el esquema.

---

## Comparación final

Las pruebas realizadas fueron:

| Alternativa                                 | Execution Time | Resultado                |
| ------------------------------------------- | -------------: | ------------------------ |
| Línea base                                  |     831.841 ms | Referencia               |
| `work_mem = 64MB`                           |     595.058 ms | Aceptada                 |
| Reescritura + `work_mem = 64MB`             | **457.822 ms** | **Ganadora**             |
| Reescritura + 4 workers + `work_mem = 64MB` |     605.570 ms | Rechazada                |
| Nuevos índices                              |     No probado | Sin evidencia suficiente |

La mejor medición obtenida fue de **457.822 ms**, correspondiente a la consulta reescrita utilizando `work_mem = 64MB`.

Durante otra ejecución de la consulta ganadora se obtuvo un tiempo de 589.341 ms. Esta diferencia demuestra que existe cierta variabilidad entre ejecuciones de `EXPLAIN ANALYZE`. Por este motivo, la comparación se realizó tomando como referencia las mediciones obtenidas durante cada experimento y observando también los cambios concretos del plan, no solamente un único valor aislado.

---

## Verificación de equivalencia

Para comprobar que la optimización no modificó los resultados, se utilizaron comparaciones mediante `EXCEPT` en ambos sentidos.

Resultado:

```text
ORIGINAL EXCEPT OPTIMIZADA → 0
OPTIMIZADA EXCEPT ORIGINAL → 0
```

Esto demuestra que no existen filas presentes solamente en la consulta original ni filas presentes solamente en la consulta optimizada.

Por lo tanto, ambas consultas producen el mismo conjunto de resultados.

---

## Conclusión

La optimización ganadora fue la combinación de la reescritura de la consulta con `work_mem = 64MB`.

El cambio de `work_mem` permitió que los ordenamientos que originalmente utilizaban `external merge` y espacio en disco pasaran a realizarse mediante `quicksort` en memoria.

La reescritura produjo una ejecución aún más rápida, alcanzando una mejor medición de **457.822 ms**, frente a los **831.841 ms** de la línea base.

No todas las propuestas de IA fueron aceptadas. El aumento del paralelismo no mejoró el tiempo y los índices no se aplicaron porque el plan no proporcionaba evidencia suficiente para justificarlos.

La decisión final se tomó a partir de los planes reales y de los tiempos obtenidos mediante `EXPLAIN ANALYZE`, verificando además que la consulta optimizada mantuviera exactamente los mismos resultados que la consulta original.
