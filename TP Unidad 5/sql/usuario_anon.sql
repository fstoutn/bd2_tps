-- Parte D: crea una tabla anonimizada para consultas agregadas.
-- Ejecutar en food_store_tp4 como propietario de public.usuario.
-- Preserva solo rol y mes de alta; reemplaza identificadores personales por datos
-- sintéticos deterministas. No copia los IDs, nombres ni emails de usuario.
--
-- El script es intencionalmente no destructivo: si usuario_anon ya existe, se detiene.
-- Revisar/resguardar la tabla existente antes de decidir cómo actualizarla.

BEGIN;

DO $$
BEGIN
    IF to_regclass('public.usuario_anon') IS NOT NULL THEN
        RAISE EXCEPTION
            'public.usuario_anon ya existe; inspeccionarla y respaldarla antes de reemplazarla';
    END IF;
END
$$;

CREATE TABLE public.usuario_anon AS
WITH usuarios_ordenados AS (
    SELECT
        row_number() OVER (ORDER BY id)::BIGINT AS anon_id,
        rol,
        date_trunc('month', created_at) AS mes_alta
    FROM public.usuario
)
SELECT
    anon_id,
    'Usuario anonimo ' || lpad(anon_id::TEXT, 8, '0') AS nombre,
    'anon-' || lpad(anon_id::TEXT, 8, '0') || '@example.invalid' AS email,
    rol,
    mes_alta
FROM usuarios_ordenados;

ALTER TABLE public.usuario_anon
    ADD CONSTRAINT usuario_anon_pkey PRIMARY KEY (anon_id);

ALTER TABLE public.usuario_anon
    ADD CONSTRAINT usuario_anon_email_key UNIQUE (email);

COMMIT;
