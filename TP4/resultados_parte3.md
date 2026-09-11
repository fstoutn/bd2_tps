# TP4 — Parte 3

## Consultas con función de ventana y subconsulta correlacionada

### Objetivo

La Parte 3 requiere definir dos consultas analíticas precisas:

1. Una consulta de ranking utilizando una función de ventana.
2. Una consulta que utilice una subconsulta correlacionada.

Para cada consulta se generaron dos implementaciones estructuralmente diferentes y se verificó que ambas fueran equivalentes mediante `EXCEPT` en ambos sentidos.

---

# Consulta 1 — Ranking de productos por categoría

## Especificación

La consulta debe:

* trabajar con `producto`, `categoria` y `detalle_pedido`;
* considerar solamente productos activos (`producto.activo = TRUE`);
* considerar solamente categorías activas (`categoria.activo = TRUE`);
* incluir productos que nunca fueron vendidos;
* considerar 0 unidades vendidas para los productos sin ventas;
* mostrar categoría, producto, unidades vendidas y ranking;
* realizar el ranking dentro de cada categoría;
* ordenar por unidades vendidas de mayor a menor;
* utilizar `RANK()`;
* mantener los empates con el mismo ranking;
* utilizar `producto_id` únicamente para estabilizar el orden de salida, sin utilizarlo como criterio del ranking.

---

## Versión 1 — RANK() directo

```sql
WITH ventas_por_producto AS (
    SELECT
        p.id AS producto_id,
        p.categoria_id,
        c.nombre AS categoria,
        p.nombre AS producto,
        COALESCE(SUM(dp.cantidad), 0) AS unidades_vendidas
    FROM producto p
    JOIN categoria c
      ON c.id = p.categoria_id
    LEFT JOIN detalle_pedido dp
      ON dp.producto_id = p.id
    WHERE p.activo = TRUE
      AND c.activo = TRUE
    GROUP BY p.id, p.categoria_id, c.nombre, p.nombre
)
SELECT
    categoria,
    producto,
    unidades_vendidas,
    RANK() OVER (
        PARTITION BY categoria_id
        ORDER BY unidades_vendidas DESC
    ) AS ranking
FROM ventas_por_producto
ORDER BY categoria, unidades_vendidas DESC, producto_id;
```

La consulta devuelve los 50.010 productos activos.

El uso de `LEFT JOIN` permite incluir productos que no tienen registros asociados en `detalle_pedido`. `COALESCE` transforma el resultado nulo de `SUM()` en 0.

---

## Versión 2 — CTE intermedio para el ranking

```sql
WITH ventas_por_producto AS (
    SELECT
        p.id AS producto_id,
        p.categoria_id,
        c.nombre AS categoria,
        p.nombre AS producto,
        COALESCE(SUM(dp.cantidad), 0) AS unidades_vendidas
    FROM producto p
    JOIN categoria c
      ON c.id = p.categoria_id
    LEFT JOIN detalle_pedido dp
      ON dp.producto_id = p.id
    WHERE p.activo = TRUE
      AND c.activo = TRUE
    GROUP BY p.id, p.categoria_id, c.nombre, p.nombre
),
ranking_categoria AS (
    SELECT
        vp.categoria_id,
        vp.producto_id,
        vp.categoria,
        vp.producto,
        vp.unidades_vendidas,
        RANK() OVER (
            PARTITION BY vp.categoria_id
            ORDER BY vp.unidades_vendidas DESC
        ) AS ranking
    FROM ventas_por_producto vp
)
SELECT
    categoria,
    producto,
    unidades_vendidas,
    ranking
FROM ranking_categoria
ORDER BY categoria_id, unidades_vendidas DESC, producto_id;
```

Esta versión separa explícitamente el cálculo del ranking en el CTE `ranking_categoria`.

También devuelve 50.010 productos.

Como ejemplo, se observaron empates:

* 90 unidades → ranking 1.
* 85 unidades → ranking 4.
* 80 unidades → ranking 10.

Esto confirma el comportamiento esperado de `RANK()`: los productos empatados comparten posición y luego se producen los saltos correspondientes.

---

## Verificación de equivalencia

Se compararon ambas versiones mediante `EXCEPT` en ambos sentidos.

### Versión 1 EXCEPT Versión 2

Resultado:

```text
0 filas
```

### Versión 2 EXCEPT Versión 1

Resultado:

```text
0 filas
```

Por lo tanto, ambas consultas producen el mismo conjunto de resultados.

**Conclusión:** equivalencia demostrada.

---

# Consulta 2 — Productos por encima del promedio de su categoría

## Especificación

La consulta debe:

* trabajar con `producto`, `categoria` y `detalle_pedido`;
* considerar solamente productos activos;
* considerar solamente categorías activas;
* incluir productos sin ventas como 0 para el cálculo del promedio;
* calcular el promedio de unidades vendidas dentro de cada categoría;
* devolver solamente los productos cuya cantidad vendida sea mayor al promedio de su categoría;
* utilizar una subconsulta realmente correlacionada;
* generar una segunda implementación estructuralmente diferente;
* verificar que ambas implementaciones sean equivalentes.

---

## Primeras propuestas y análisis de rendimiento

La primera propuesta utilizaba una subconsulta correlacionada directamente sobre `ventas_por_producto`:

```sql
WHERE unidades_vendidas > (
    SELECT AVG(v2.unidades_vendidas)
    FROM ventas_por_producto v2
    WHERE v2.categoria_id = v.categoria_id
)
```

Con la cantidad real de datos de la base, esta implementación presentó un rendimiento inaceptable y fue detenida después de más de 30 segundos.

Se probó posteriormente una versión que precalculaba los promedios por categoría, pero el tiempo de ejecución continuó siendo elevado.

Estas propuestas fueron descartadas debido a su comportamiento real en PostgreSQL.

La optimización final mantuvo la condición de correlación, pero redujo el conjunto sobre el cual trabaja la subconsulta a una tabla con una única fila por categoría.

---

## Versión 1 — Subconsulta correlacionada

```sql
WITH ventas_por_producto AS MATERIALIZED (
    SELECT
        p.id AS producto_id,
        p.categoria_id,
        c.nombre AS categoria,
        p.nombre AS producto,
        COALESCE(SUM(dp.cantidad), 0) AS unidades_vendidas
    FROM producto p
    JOIN categoria c
        ON c.id = p.categoria_id
    LEFT JOIN detalle_pedido dp
        ON dp.producto_id = p.id
    WHERE p.activo = TRUE
      AND c.activo = TRUE
    GROUP BY
        p.id,
        p.categoria_id,
        c.nombre,
        p.nombre
),
promedio_categoria AS MATERIALIZED (
    SELECT
        categoria_id,
        AVG(unidades_vendidas) AS promedio
    FROM ventas_por_producto
    GROUP BY categoria_id
)
SELECT
    v.categoria,
    v.producto,
    v.unidades_vendidas
FROM ventas_por_producto v
WHERE v.unidades_vendidas > (
    SELECT pc.promedio
    FROM promedio_categoria pc
    WHERE pc.categoria_id = v.categoria_id
)
ORDER BY
    v.categoria,
    v.producto;
```

La condición:

```sql
pc.categoria_id = v.categoria_id
```

hace que la subconsulta sea realmente correlacionada, ya que utiliza un valor perteneciente a la fila externa `v`.

El CTE `promedio_categoria` contiene solamente una fila por categoría. En esta base existen cuatro categorías activas:

| Categoría | Productos | Promedio de unidades |
| --------- | --------: | -------------------: |
| Pizzas    |    12.503 |              23,9286 |
| Empanadas |    12.503 |              24,0487 |
| Bebidas   |    12.502 |              23,9666 |
| Postres   |    12.502 |              24,0997 |

La consulta devuelve:

```text
22.185 filas
```

---

## Versión 2 — JOIN contra el promedio por categoría

```sql
WITH ventas_por_producto AS MATERIALIZED (
    SELECT
        p.id AS producto_id,
        p.categoria_id,
        c.nombre AS categoria,
        p.nombre AS producto,
        COALESCE(SUM(dp.cantidad), 0) AS unidades_vendidas
    FROM producto p
    JOIN categoria c
        ON c.id = p.categoria_id
    LEFT JOIN detalle_pedido dp
        ON dp.producto_id = p.id
    WHERE p.activo = TRUE
      AND c.activo = TRUE
    GROUP BY
        p.id,
        p.categoria_id,
        c.nombre,
        p.nombre
),
promedio_categoria AS (
    SELECT
        categoria_id,
        AVG(unidades_vendidas) AS promedio
    FROM ventas_por_producto
    GROUP BY categoria_id
)
SELECT
    v.categoria,
    v.producto,
    v.unidades_vendidas
FROM ventas_por_producto v
JOIN promedio_categoria pc
    ON pc.categoria_id = v.categoria_id
WHERE v.unidades_vendidas > pc.promedio
ORDER BY
    v.categoria,
    v.producto;
```

Esta implementación reemplaza la subconsulta correlacionada por un `JOIN` directo contra los promedios previamente calculados.

La consulta también devuelve:

```text
22.185 filas
```

---

## Verificación de equivalencia

Se compararon ambas implementaciones mediante `EXCEPT` en ambos sentidos.

### Versión 1 EXCEPT Versión 2

Resultado:

```text
0 filas
```

### Versión 2 EXCEPT Versión 1

Resultado:

```text
0 filas
```

Por lo tanto, ambas consultas producen exactamente el mismo conjunto de resultados.

**Conclusión:** equivalencia demostrada.

---

# Conclusión de la Parte 3

Las dos consultas requeridas fueron implementadas mediante dos estructuras diferentes y verificadas sobre la base real.

La primera consulta utiliza una función de ventana `RANK()` para obtener el ranking de productos dentro de cada categoría.

La segunda consulta utiliza una subconsulta correlacionada para comparar cada producto con el promedio de unidades vendidas de su categoría. Debido al volumen real de datos, las primeras propuestas de correlación presentaron tiempos de ejecución elevados y fueron descartadas. Finalmente se redujo el conjunto utilizado por la correlación a los promedios previamente calculados por categoría.

En ambos casos se comprobó la equivalencia mediante `EXCEPT` en ambos sentidos, obteniendo 0 filas en todas las comparaciones.

Esto permite afirmar que las implementaciones alternativas son equivalentes respecto de sus resultados.