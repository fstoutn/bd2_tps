-- Parte D: comparación de agregados reales y anonimizados.
-- La tabla anon conserva rol y mes_alta, pero no contiene datos identificatorios.

-- Resultado agregado de la tabla real.
SELECT
    rol,
    date_trunc('month', created_at) AS mes_alta,
    count(*) AS cantidad
FROM public.usuario
GROUP BY rol, date_trunc('month', created_at)
ORDER BY rol, mes_alta;

-- Resultado agregado de la tabla anonimizada.
SELECT
    rol,
    mes_alta,
    count(*) AS cantidad
FROM public.usuario_anon
GROUP BY rol, mes_alta
ORDER BY rol, mes_alta;

-- Diferencias entre ambos resultados.
-- Esperado: 0 filas. Una fila indica que falta o difiere un grupo/conteo.
WITH real AS (
    SELECT
        rol,
        date_trunc('month', created_at) AS mes_alta,
        count(*) AS cantidad
    FROM public.usuario
    GROUP BY rol, date_trunc('month', created_at)
),
anon AS (
    SELECT
        rol,
        mes_alta,
        count(*) AS cantidad
    FROM public.usuario_anon
    GROUP BY rol, mes_alta
)
SELECT
    coalesce(real.rol::TEXT, anon.rol::TEXT) AS rol,
    coalesce(real.mes_alta, anon.mes_alta) AS mes_alta,
    real.cantidad AS cantidad_real,
    anon.cantidad AS cantidad_anon
FROM real
FULL OUTER JOIN anon
    ON real.rol = anon.rol
   AND real.mes_alta IS NOT DISTINCT FROM anon.mes_alta
WHERE real.cantidad IS DISTINCT FROM anon.cantidad
ORDER BY rol, mes_alta;
