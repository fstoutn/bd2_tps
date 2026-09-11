# DUIA — Documentación del Uso de IA

## Trabajo Práctico 4 — Reportes analíticos asistidos por IA sobre Food Store

Este documento registra el uso de inteligencia artificial durante la realización del Trabajo Práctico 4.

La IA se utilizó como herramienta de apoyo para analizar planes de ejecución, proponer reescrituras de consultas y posibles optimizaciones, explicar decisiones del optimizador y generar alternativas de SQL.

Las propuestas generadas por IA no fueron aceptadas automáticamente. Cada modificación relevante fue probada en la base de datos mediante `EXPLAIN ANALYZE`, y las decisiones finales se tomaron a partir de los resultados reales obtenidos.

---

# Parte 1 — Optimización de consultas con JOIN

## Consulta 1 — Facturación por categoría y mes

La primera consulta analizada calcula la facturación por categoría y mes utilizando las tablas:

* `categoria`
* `producto`
* `detalle_pedido`
* `pedido`

La medición inicial fue de:

**1284.808 ms**

El plan utilizaba principalmente:

* `Hash Join`
* `Parallel Hash Join`
* `Nested Loop`
* `Memoize`
* `GroupAggregate`
* `Incremental Sort`

También se detectaron ordenamientos mediante `external merge` que utilizaban espacio en disco.

### Propuestas de IA

La IA propuso principalmente:

1. Aumentar `work_mem`.
2. Reescribir la consulta para realizar la agregación antes de volver a unir con `categoria`.
3. No crear nuevos índices sin evidencia suficiente.
4. No forzar manualmente algoritmos de JOIN.

La propuesta de aumentar `work_mem` fue probada utilizando `32MB`.

Resultado:

**1116.708 ms**

El cambio permitió que los ordenamientos pasaran de `external merge` a `quicksort` en memoria.

Luego se probó la reescritura de la consulta mediante una CTE que agrupaba primero por categoría y mes.

Resultado:

**536.027 ms**

La mejora respecto de la línea base fue de aproximadamente **58.27%**.

La equivalencia entre la consulta original y la optimizada fue verificada mediante `EXCEPT` en ambos sentidos, obteniendo cero diferencias.

La propuesta fue aceptada.

---

## Consulta 2 — Top 5 productos más vendidos

La segunda consulta utilizó:

* `producto`
* `detalle_pedido`
* `pedido`

La medición inicial fue:

**491.697 ms**

La IA analizó que el `JOIN` con `pedido` no aportaba columnas ni filtros a la consulta y que la integridad referencial de la base garantizaba que no existieran registros huérfanos.

Por lo tanto, propuso eliminar ese `JOIN`.

Resultado:

**449.000 ms**

Luego propuso realizar primero la agregación de `detalle_pedido` por `producto_id` y posteriormente unir el resultado con `producto`.

La consulta resultante obtuvo:

**280.695 ms**

Esto representó una mejora de aproximadamente **42.91%** respecto de la consulta original.

La equivalencia fue comprobada comparando los resultados de ambas consultas. Los cinco productos obtenidos fueron iguales en ambas versiones.

La segunda reescritura fue aceptada como la mejor alternativa.

---

# Parte 2 — Lectura crítica de un plan de ejecución

Para esta parte se proporcionó a la IA únicamente el plan de ejecución real de la consulta de facturación por categoría y mes.

El objetivo fue comprobar si la interpretación de la IA coincidía con el comportamiento real de PostgreSQL.

La IA identificó correctamente:

* Los `Hash Join`.
* El `Parallel Hash Join`.
* El uso de `Gather Merge`.
* Los `Sort` mediante `external merge`.
* El `Nested Loop`.
* El `Memoize`.
* Los accesos mediante `Seq Scan`.
* El tiempo total de ejecución.

También identificó correctamente que `Memoize` tenía:

```text
Hits: 400249
Misses: 4
```

Esto permitió comprobar que el acceso a `categoria` no constituía un cuello de botella importante.

Se detectó una interpretación que necesitaba corrección: la cantidad de loops del `Nested Loop` no significa por sí sola que el nodo sea costoso. En este caso, `Memoize` hacía que la mayoría de los accesos internos fueran atendidos desde caché.

También se aclaró que los valores de `cost` del plan son unidades utilizadas por el optimizador y no representan milisegundos.

La lectura del plan se contrastó con los valores reales de `actual time`, los métodos de ordenamiento y las cantidades de filas procesadas.

---

# Parte 3 — Ranking y subconsulta correlacionada

En esta parte se utilizaron especificaciones precisas para solicitar a la IA dos consultas diferentes.

## Consulta 1 — Ranking por categoría

La especificación requería:

* utilizar productos y categorías activos;
* incluir productos sin ventas;
* mostrar unidades vendidas;
* utilizar una función de ventana;
* particionar el ranking por categoría;
* utilizar `RANK()`;
* permitir empates;
* utilizar el `id` del producto solamente como orden final.

La primera versión generada utilizó correctamente `RANK()` y `LEFT JOIN` para conservar los productos sin ventas.

Se solicitó además una segunda versión estructuralmente diferente.

La IA tuvo dificultades inicialmente para generar una alternativa eficiente. Una de las propuestas utilizaba una subconsulta que comparaba cada producto con los demás productos de su categoría. Esta alternativa tuvo un tiempo de ejecución excesivo y fue descartada.

Luego, la IA resolvió correctamente la consulta utilizando una estructura diferente mediante CTEs y manteniendo la función de ventana.

Ambas versiones devolvieron:

**50.010 filas**

La equivalencia fue verificada mediante:

```text
V1 EXCEPT V2 = 0
V2 EXCEPT V1 = 0
```

Por lo tanto, ambas consultas fueron consideradas equivalentes.

---

## Consulta 2 — Productos por encima del promedio de su categoría

La segunda especificación requería:

* utilizar productos y categorías activos;
* incluir productos con cero ventas en el cálculo del promedio;
* calcular el promedio de unidades vendidas por categoría;
* devolver solamente los productos que superaran el promedio;
* utilizar una subconsulta correlacionada.

Las primeras propuestas de la IA presentaron problemas de rendimiento. Una de las consultas correlacionadas tardó más de 30 segundos y otra alternativa también presentó un tiempo de ejecución excesivo, por lo que fueron detenidas y descartadas.

La IA continuó trabajando sobre el problema y finalmente resolvió la consulta utilizando una estructura con CTEs materializadas, manteniendo la comparación mediante una subconsulta correlacionada.

La consulta produjo:

**22.185 filas**

Posteriormente se generó una segunda versión estructuralmente diferente que utilizó un `JOIN` con los promedios previamente calculados.

Las dos versiones fueron comparadas mediante:

```text
V1 EXCEPT V2 = 0
V2 EXCEPT V1 = 0
```

Los resultados fueron cero diferencias.

Por lo tanto, ambas consultas fueron consideradas equivalentes.

Esta parte permitió comprobar que una propuesta generada por IA puede ser conceptualmente correcta pero presentar un rendimiento inaceptable. Por este motivo, las consultas fueron evaluadas tanto por su resultado como por su comportamiento real.

---

# Parte 4 — Competencia de optimizaciones

Para la última parte se seleccionó nuevamente una consulta analítica con múltiples `JOIN` y agregación.

La consulta calcula la facturación por categoría y mes.

La línea base obtenida en esta etapa fue:

**831.841 ms**

El plan presentaba ordenamientos mediante `external merge` y utilización de disco temporal.

La IA propuso varias alternativas.

## Propuesta 1 — Aumentar `work_mem`

Se probó:

```sql
SET LOCAL work_mem = '64MB';
```

Resultado:

**595.058 ms**

Los `Sort` dejaron de utilizar `external merge` y pasaron a:

```text
quicksort
```

en memoria.

La propuesta fue aceptada.

---

## Propuesta 2 — Reescritura de la consulta

Se probó una reescritura utilizando una CTE para separar la agregación de la presentación final.

Manteniendo `work_mem = 64MB`, se obtuvo:

**457.822 ms**

Esta fue la mejor medición obtenida durante la competencia.

La mejora respecto de la línea base fue de aproximadamente:

**44.96%**

La consulta fue seleccionada como ganadora.

La IA había planteado como posibilidad que PostgreSQL pudiera utilizar `HashAggregate`, pero esto no ocurrió. El plan real continuó utilizando:

* `Partial GroupAggregate`
* `Gather Merge`
* `Finalize GroupAggregate`

Por lo tanto, la conclusión se basó en el plan real y no en la predicción de la IA.

---

## Propuesta 3 — Aumentar el paralelismo

Se probó:

```sql
SET LOCAL max_parallel_workers_per_gather = 4;
```

manteniendo `work_mem = 64MB`.

El resultado fue:

**605.570 ms**

El plan continuó utilizando:

```text
Workers Planned: 2
Workers Launched: 2
```

Por lo tanto, el aumento del parámetro no produjo una mejora efectiva.

La propuesta fue rechazada.

---

## Propuesta 4 — Crear índices

La IA también evaluó la posibilidad de crear índices adicionales sobre columnas utilizadas en los JOIN.

Esta propuesta no fue aplicada porque la consulta no tenía filtros selectivos y necesitaba procesar una gran cantidad de registros.

El plan utilizaba `Seq Scan` y `Hash Join` sobre grandes conjuntos de datos, por lo que no existía evidencia suficiente para justificar nuevos índices.

La propuesta fue descartada sin modificar el esquema.

---

# Criterio utilizado para aceptar o rechazar propuestas

Durante todo el trabajo se siguió el siguiente criterio:

1. Analizar la propuesta de IA.
2. Identificar qué parte del plan intentaba mejorar.
3. Comprobar que la propuesta tuviera una justificación técnica.
4. Ejecutar la consulta modificada mediante `EXPLAIN ANALYZE`.
5. Comparar el tiempo real con la versión anterior.
6. Comprobar la equivalencia de resultados cuando correspondía.
7. Aceptar solamente las modificaciones respaldadas por evidencia.

Por este motivo, no todas las sugerencias realizadas por IA fueron incorporadas al resultado final.

---

# Conclusión general

La IA fue utilizada como herramienta de análisis y generación de alternativas, pero las decisiones finales se basaron en la ejecución real sobre PostgreSQL.

Durante el TP se comprobó que una propuesta puede parecer correcta desde el punto de vista conceptual y, sin embargo, tener un rendimiento peor al ejecutarse sobre el volumen real de datos.

También se comprobó la importancia de analizar los planes de ejecución y no interpretar de forma aislada valores como `cost`, cantidad de `loops` o tipo de JOIN.

Las optimizaciones aceptadas fueron aquellas que demostraron una mejora mediante `EXPLAIN ANALYZE` y, cuando correspondía, conservaron exactamente los mismos resultados.

En particular, en la Parte 4 la mejor alternativa obtuvo una medición de **457.822 ms**, frente a **831.841 ms** de la línea base, logrando una reducción aproximada del **44.96%**.

La equivalencia de la consulta optimizada fue comprobada mediante `EXCEPT` en ambos sentidos:

```text
ORIGINAL EXCEPT OPTIMIZADA → 0
OPTIMIZADA EXCEPT ORIGINAL → 0
```

De esta manera, se logró optimizar la consulta manteniendo su comportamiento funcional.
