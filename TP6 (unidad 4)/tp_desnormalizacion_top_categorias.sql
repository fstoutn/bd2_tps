-- ============================================================================
-- TRABAJO PRÁCTICO N° 4 - PARTE 2: DESNORMALIZACIÓN CONTROLADA
-- Archivo: tp_desnormalizacion_top_categorias.sql
-- ============================================================================

ROLLBACK;

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. CREACIÓN DE LA ESTRUCTURA DESNORMALIZADA (VISTA MATERIALIZADA)
-- ----------------------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS mv_top_categorias_diarias CASCADE;

CREATE MATERIALIZED VIEW mv_top_categorias_diarias AS
SELECT 
    c.id AS categoria_id,
    c.nombre AS categoria,
    ped.fecha_hora::date AS fecha,
    SUM(dp.subtotal) AS total_vendido
FROM detalle_pedido dp
JOIN producto pr ON pr.id = dp.producto_id
JOIN categoria c ON c.id = pr.categoria_id
JOIN pedido ped ON ped.id = dp.pedido_id
GROUP BY c.id, c.nombre, ped.fecha_hora::date;

-- Índice para acelerar la consulta del reporte diario por fecha
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_top_cat_fecha 
ON mv_top_categorias_diarias (fecha, categoria_id);

COMMIT;

-- Refresco de la vista desnormalizada
REFRESH MATERIALIZED VIEW mv_top_categorias_diarias;

-- ----------------------------------------------------------------------------
-- 2. MEDICIÓN OPTIMIZADA CON EXPLAIN ANALYZE ("DESPUÉS")
-- ----------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT 
    categoria,
    total_vendido
FROM mv_top_categorias_diarias
WHERE fecha = CURRENT_DATE
ORDER BY total_vendido DESC
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 3. AUDITORÍA DE SINCRONIZACIÓN (Debe devolver 0 filas)
-- ----------------------------------------------------------------------------
SELECT 
    mv.categoria, 
    mv.total_vendido AS total_desnormalizado,
    orig.total_vendido AS total_real
FROM mv_top_categorias_diarias mv
FULL OUTER JOIN (
    SELECT 
        c.nombre AS categoria,
        SUM(dp.subtotal) AS total_vendido
    FROM detalle_pedido dp
    JOIN producto pr ON pr.id = dp.producto_id
    JOIN categoria c ON c.id = pr.categoria_id
    JOIN pedido ped ON ped.id = dp.pedido_id
    WHERE ped.fecha_hora::date = CURRENT_DATE
    GROUP BY c.nombre
) orig ON mv.categoria = orig.categoria
WHERE mv.fecha = CURRENT_DATE
  AND (mv.total_vendido IS NULL 
       OR orig.total_vendido IS NULL 
       OR mv.total_vendido <> orig.total_vendido);