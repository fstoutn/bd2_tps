# TP4 — Parte 2

## Lectura crítica de planes de JOIN interpretados por IA

### 1. Consulta seleccionada

Para esta parte se seleccionó la consulta **Facturación por categoría y mes**, utilizada también en la Parte 1.

La consulta cruza cuatro tablas:

* `categoria`
* `producto`
* `detalle_pedido`
* `pedido`

El objetivo de esta parte no fue optimizar la consulta, sino analizar críticamente la interpretación realizada por una IA sobre un `EXPLAIN ANALYZE` real.

### 2. Plan analizado

Se utilizó una nueva ejecución del plan original, sin aplicar modificaciones:

```text
Execution Time: 1259.764 ms
Planning Time: 0.885 ms
```

El plan contiene, entre otros, los siguientes nodos:

* `Parallel Seq Scan` sobre `detalle_pedido`
* `Seq Scan` sobre `producto`
* `Hash Join` entre `detalle_pedido` y `producto`
* `Parallel Seq Scan` sobre `pedido`
* `Parallel Hash Join` con `pedido`
* `Sort` con método `external merge`
* `Gather Merge`
* `Nested Loop`
* `Memoize`
* `GroupAggregate`
* `Incremental Sort`

### 3. Prompt utilizado

Se proporcionó a la IA únicamente el texto del `EXPLAIN ANALYZE`, solicitándole que realizara una lectura nodo por nodo sin asumir contexto adicional.

El pedido realizado fue:

> Analiza el siguiente EXPLAIN ANALYZE de PostgreSQL sin asumir ningún contexto adicional. Explica el plan nodo por nodo. Para cada JOIN indica las tablas involucradas, cuál es la entrada externa e interna, qué algoritmo utiliza, las estimaciones frente a los valores reales y el costo y tiempo de ejecución. Indica cuál parece ser el nodo de mayor costo. Presta especial atención al Nested Loop y al Memoize. No propongas optimizaciones.

### 4. Lectura crítica de la respuesta de la IA

### (Se uso este formato y no tabla porque se deformaban los datos y no quedaban claros)
#### 4.1 Primer `Hash Join`

**Afirmación de la IA:**
El primer `Hash Join` une `detalle_pedido` con `producto`.

**Veredicto:** Correcta.

**Evidencia:**
El plan muestra:

```text
Hash Join
Hash Cond: (dp.producto_id = p.id)
```

La entrada externa corresponde a `detalle_pedido`, procesada mediante `Parallel Seq Scan`. La entrada interna corresponde a `producto`, que primero se procesa mediante `Seq Scan` y luego mediante un nodo `Hash`.

---

#### 4.2 Segundo `Parallel Hash Join`

**Afirmación de la IA:**
El segundo JOIN utiliza un `Parallel Hash Join` entre el resultado anterior y `pedido`.

**Veredicto:** Correcta.

**Evidencia:**
El plan muestra:

```text
Parallel Hash Join
Hash Cond: (dp.pedido_id = pe.id)
```

El resultado del primer JOIN funciona como entrada externa, mientras que `pedido` se utiliza como entrada interna mediante `Parallel Hash`.

---

#### 4.3 Scans secuenciales

**Afirmación de la IA:**
`detalle_pedido`, `producto` y `pedido` son leídos mediante scans secuenciales.

**Veredicto:** Correcta.

**Evidencia:**
El plan contiene:

```text
Parallel Seq Scan on detalle_pedido
Seq Scan on producto
Parallel Seq Scan on pedido
```

---

#### 4.4 Ordenamientos `external merge`

**Afirmación de la IA:**
Los nodos `Sort` utilizan `external merge` y escriben datos en disco.

**Veredicto:** Correcta.

**Evidencia:**
El plan muestra:

```text
Sort Method: external merge
Disk: 6376kB
```

También aparecen valores de disco para los dos workers.

---

#### 4.5 `Gather Merge`

**Afirmación de la IA:**
`Gather Merge` reúne y combina los resultados ordenados provenientes de los workers.

**Veredicto:** Correcta.

**Evidencia:**
El plan utiliza dos workers y un nodo:

```text
Gather Merge
Workers Planned: 2
Workers Launched: 2
```

Este nodo recibe los resultados ordenados de los procesos paralelos y los combina manteniendo el orden.

---

#### 4.6 Entrada externa del `Nested Loop`

**Afirmación de la IA:**
La entrada externa del `Nested Loop` es el `Gather Merge`.

**Veredicto:** Correcta.

**Evidencia:**
El plan muestra al `Gather Merge` como el primer hijo del `Nested Loop`.

```text
Nested Loop
    -> Gather Merge
    -> Memoize
```

Por lo tanto, el `Gather Merge` corresponde a la entrada externa.

---

#### 4.7 Entrada interna del `Nested Loop`

**Afirmación de la IA:**
La entrada interna del `Nested Loop` es `Memoize`.

**Veredicto:** Correcta.

**Evidencia:**
El segundo hijo del `Nested Loop` es:

```text
Memoize
Cache Key: p.categoria_id
```

Dentro de `Memoize` se encuentra el `Index Scan` sobre `categoria`.

---

#### 4.8 Funcionamiento de `Memoize`

**Afirmación de la IA:**
`Memoize` tuvo 400.249 hits y solamente 4 misses.

**Veredicto:** Correcta.

**Evidencia:**
El plan muestra:

```text
Hits: 400249
Misses: 4
Evictions: 0
Overflows: 0
```

Esto significa que casi todas las búsquedas fueron resueltas utilizando valores almacenados en caché.

---

#### 4.9 Cantidad de búsquedas reales en `categoria`

**Afirmación de la IA:**
Solamente se realizaron 4 búsquedas reales mediante el índice de `categoria`.

**Veredicto:** Correcta.

**Evidencia:**
El nodo `Memoize` tiene 4 misses y el `Index Scan` sobre `categoria` muestra:

```text
loops=4
```

Las restantes 400.249 iteraciones utilizaron los valores almacenados en caché.

---

#### 4.10 Interpretación del `Nested Loop`

**Afirmación de la IA:**
El `Nested Loop` debe considerarse costoso porque tiene 400.253 loops.

**Veredicto:** Incorrecta o, al menos, incompleta.

**Corrección:**
La cantidad de loops por sí sola no permite afirmar que el `Nested Loop` sea el principal problema del plan.

En este caso, `Memoize` hace que las búsquedas internas sean muy económicas:

```text
Hits: 400249
Misses: 4
```

Además, los tiempos mostrados por un nodo incluyen el trabajo realizado por sus nodos hijos. Por lo tanto, no se puede atribuir todo el tiempo mostrado en el `Nested Loop` exclusivamente al algoritmo de JOIN.

---

#### 4.11 Interpretación de `Memoize`

**Afirmación de la IA:**
`Memoize` representa una parte importante del costo porque se ejecuta 400.253 veces.

**Veredicto:** Incorrecta.

**Corrección:**
Aunque `Memoize` aparece con 400.253 loops, casi todas esas operaciones fueron atendidas desde la caché.

El plan muestra:

```text
Hits: 400249
Misses: 4
```

Además, el tiempo real indicado para el nodo es prácticamente cero:

```text
actual time=0.000..0.000
```

Por lo tanto, la cantidad de loops no significa necesariamente un costo elevado.

---

#### 4.12 Estimación de `GroupAggregate`

**Afirmación de la IA:**
`GroupAggregate` estima aproximadamente 400.253 filas pero realmente produce 28.

**Veredicto:** Correcta, con una aclaración.

**Evidencia:**
El plan muestra:

```text
GroupAggregate
(cost=31460.21..97188.94 rows=400253 ...)
(actual time=637.400..1258.320 rows=28 loops=1)
```

La estimación de PostgreSQL sobre la cantidad de filas de salida es muy superior al resultado real.

La consulta finalmente produce solamente 28 grupos, mientras que el optimizador había estimado 400.253.

Esto muestra una estimación deficiente de la cardinalidad del resultado de la agregación.

---

#### 4.13 `Incremental Sort`

**Afirmación de la IA:**
`Incremental Sort` trabaja sobre datos que ya estaban parcialmente ordenados por el mes.

**Veredicto:** Correcta.

**Evidencia:**
El plan indica:

```text
Presorted Key: (date_trunc('month'::text, pe.fecha_hora))
```

Además, utiliza:

```text
Sort Method: quicksort
Average Memory: 26kB
Peak Memory: 26kB
```

Por lo tanto, la descripción realizada por la IA coincide con el plan real.

---

#### 4.14 Interpretación del `cost`

**Afirmación de la IA:**
El `cost` de PostgreSQL no está expresado en milisegundos.

**Veredicto:** Correcta.

**Evidencia:**
El plan presenta valores como:

```text
cost=31460.55..108195.21
```

mientras que el tiempo real aparece al final como:

```text
Execution Time: 1259.764 ms
```

El `cost` corresponde a unidades internas utilizadas por PostgreSQL para comparar diferentes planes de ejecución. No debe interpretarse como tiempo en milisegundos.

---

#### 4.15 Tiempo total de ejecución

**Afirmación de la IA:**
El tiempo total de ejecución fue de 1259.764 ms.

**Veredicto:** Correcta.

**Evidencia:**
El plan finaliza con:

```text
Planning Time: 0.885 ms
Execution Time: 1259.764 ms
```

---

#### 4.16 Interpretación del tiempo del `Nested Loop`

**Afirmación de la IA:**
El `Nested Loop` consume aproximadamente 1146 ms.

**Veredicto:** Incorrecta si se interpreta como tiempo exclusivo del JOIN.

**Corrección:**
El nodo muestra:

```text
actual time=586.802..1146.927
```

Pero este tiempo es inclusivo. Es decir, también contempla el trabajo realizado por los nodos que producen su entrada externa, especialmente el `Gather Merge`.

Por lo tanto, no se puede afirmar que los aproximadamente 1146 ms correspondan exclusivamente al algoritmo `Nested Loop`.

La interpretación correcta es que el `Nested Loop` termina de producir sus 400.253 filas alrededor de ese momento, pero su tiempo incluye trabajo realizado previamente por sus nodos hijos.
                                   |

### 5. Análisis de los JOIN

#### Primer JOIN: `Hash Join`

```text
Hash Join
Hash Cond: (dp.producto_id = p.id)
```

Las tablas involucradas son `detalle_pedido` y `producto`.

* Entrada externa: `detalle_pedido`.
* Entrada interna: `producto`, previamente convertido en un hash.
* Algoritmo: `Hash Join`.
* `detalle_pedido` se procesa mediante `Parallel Seq Scan`.
* `producto` se procesa mediante `Seq Scan` y luego `Hash`.

El plan muestra que se procesan aproximadamente 400.253 filas en total provenientes de `detalle_pedido`.

#### Segundo JOIN: `Parallel Hash Join`

```text
Parallel Hash Join
Hash Cond: (dp.pedido_id = pe.id)
```

Las tablas involucradas son el resultado del JOIN anterior y `pedido`.

* Entrada externa: resultado del primer `Hash Join`.
* Entrada interna: `pedido`, mediante `Parallel Hash`.
* Algoritmo: `Parallel Hash Join`.

La utilización de paralelismo permite que varios procesos participen en el procesamiento de este JOIN.

#### Tercer JOIN: `Nested Loop`

```text
Nested Loop
```

Este JOIN relaciona el resultado anterior con `categoria`.

* Entrada externa: `Gather Merge`.
* Entrada interna: `Memoize`.
* Dentro de `Memoize`: `Index Scan using categoria_pkey`.
* Clave de caché: `p.categoria_id`.

A primera vista, los 400.253 loops pueden parecer un problema. Sin embargo, la lectura detallada del `Memoize` cambia la interpretación:

```text
Hits: 400249
Misses: 4
```

Esto significa que casi todas las búsquedas fueron resueltas mediante la caché. Solamente cuatro valores distintos necesitaron acceder realmente al índice de `categoria`.

Por lo tanto, **no sería correcto concluir que el Nested Loop es costoso únicamente por la cantidad de loops**.

### 6. Cost vs. tiempo real

El plan presenta:

```text
cost=31460.55..108195.21
Execution Time: 1259.764 ms
```

El `cost` es una estimación interna de PostgreSQL y no representa milisegundos.

En cambio, `actual time` y `Execution Time` representan tiempos observados durante la ejecución real.

Por este motivo, no debe realizarse una comparación directa como:

```text
108195.21 > 1259.764
```

para determinar cuánto más lento es un nodo.

El `cost` sirve principalmente para que PostgreSQL compare alternativas de planes, mientras que `EXPLAIN ANALYZE` permite observar qué ocurrió realmente durante la ejecución.

### 7. Conclusión

La interpretación realizada por la IA fue, en términos generales, correcta. Identificó correctamente los principales algoritmos de JOIN, las entradas externas e internas, el funcionamiento de `Memoize`, los `Sort` con `external merge`, el `Gather Merge` y los valores reales de ejecución.

Sin embargo, la lectura crítica permitió detectar varios puntos que debían ser corregidos o matizados.

El principal fue la interpretación del `Nested Loop`: no es correcto atribuirle todo el tiempo mostrado por su nodo, ya que los tiempos de `EXPLAIN ANALYZE` son inclusivos y contienen el trabajo realizado por sus nodos hijos. Además, `Memoize` demuestra que las búsquedas de `categoria` fueron muy eficientes, con 400.249 accesos resueltos desde caché y solamente 4 misses.

También se identificó una mala estimación de cardinalidad en `GroupAggregate`, donde PostgreSQL estimó 400.253 filas de salida pero realmente produjo solamente 28 grupos.

Finalmente, se verificó que el `cost` de PostgreSQL no debe interpretarse como milisegundos. Para evaluar el rendimiento real se debe utilizar principalmente el `actual time` y el `Execution Time`.

Esta comparación demuestra que una respuesta generada por IA puede ser útil para interpretar un plan, pero debe ser revisada contra el `EXPLAIN ANALYZE` real antes de aceptar sus conclusiones.
