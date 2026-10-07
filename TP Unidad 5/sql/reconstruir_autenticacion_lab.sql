-- Reconstrucción de fn_autenticar para el simulacro de la Parte C.
-- Solo usa una identidad sintética de laboratorio; no autentica usuarios reales.
-- Ejecutar como postgres en food_store_tp4.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.usuario_auth_lab (
    email TEXT PRIMARY KEY,
    password_hash TEXT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- Credencial ficticia y exclusiva del laboratorio. No reutilizarla en otros sistemas.
INSERT INTO public.usuario_auth_lab (email, password_hash, activo)
VALUES (
    'demo@foodstore.test',
    public.crypt('Demo-U5-Temporal-2026!', public.gen_salt('bf')),
    TRUE
)
ON CONFLICT (email) DO NOTHING;

CREATE OR REPLACE FUNCTION public.fn_autenticar(
    p_email TEXT,
    p_password TEXT
)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
    SELECT EXISTS (
        SELECT 1
        FROM public.usuario_auth_lab AS auth
        WHERE lower(auth.email) = lower(p_email)
          AND auth.activo
          AND auth.password_hash = public.crypt(p_password, auth.password_hash)
    );
$function$;

REVOKE ALL ON TABLE public.usuario_auth_lab FROM PUBLIC;
REVOKE ALL ON TABLE public.usuario_auth_lab FROM app_web;
REVOKE ALL ON TABLE public.usuario_auth_lab FROM admin_datos;
REVOKE ALL ON TABLE public.usuario_auth_lab FROM rol_app_lectura;
REVOKE ALL ON TABLE public.usuario_auth_lab FROM rol_app_escritura;
REVOKE ALL ON TABLE public.usuario_auth_lab FROM rol_soporte;
REVOKE ALL ON TABLE public.usuario_auth_lab FROM rol_reportes;
REVOKE ALL ON FUNCTION public.fn_autenticar(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_autenticar(TEXT, TEXT) TO app_web;

COMMIT;
