-- Food Store - esquema de roles y permisos con principio de mínimo privilegio
-- Requiere PostgreSQL 16+
-- Ejecutar este script conectado a la base Food Store objetivo y con permisos de administrador.
-- Esta versión está dirigida a food_store_tp4. No contiene contraseñas; asignarlas
-- interactivamente con \password app_web y \password admin_datos en psql.

BEGIN;

-- =========================================================
-- 1. CREACIÓN DE ROLES DE GRUPO
-- =========================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_app_lectura') THEN
        CREATE ROLE rol_app_lectura NOLOGIN;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_app_escritura') THEN
        CREATE ROLE rol_app_escritura NOLOGIN;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_soporte') THEN
        CREATE ROLE rol_soporte NOLOGIN;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_reportes') THEN
        CREATE ROLE rol_reportes NOLOGIN;
    END IF;
END $$;

-- =========================================================
-- 2. ROLES DE LOGIN
-- =========================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_web') THEN
        CREATE ROLE app_web LOGIN;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_datos') THEN
        CREATE ROLE admin_datos LOGIN;
    END IF;
END $$;

-- Si ya existían, asegurar que las dos cuentas de servicio puedan iniciar sesión.
ALTER ROLE app_web LOGIN;
ALTER ROLE admin_datos LOGIN;

-- =========================================================
-- 3. ASIGNACIÓN DE MEMBRESÍAS
-- =========================================================
GRANT rol_app_lectura TO app_web;
GRANT rol_app_escritura TO app_web;

GRANT rol_app_lectura TO admin_datos;
GRANT rol_app_escritura TO admin_datos;
GRANT rol_soporte TO admin_datos;
GRANT rol_reportes TO admin_datos;

-- =========================================================
-- 4. PRIVILEGIOS DE ESQUEMA
-- =========================================================
GRANT CONNECT ON DATABASE food_store_tp4 TO rol_app_lectura;
GRANT CONNECT ON DATABASE food_store_tp4 TO rol_app_escritura;
GRANT CONNECT ON DATABASE food_store_tp4 TO rol_soporte;
GRANT CONNECT ON DATABASE food_store_tp4 TO rol_reportes;
GRANT CONNECT ON DATABASE food_store_tp4 TO app_web;
GRANT CONNECT ON DATABASE food_store_tp4 TO admin_datos;

GRANT USAGE ON SCHEMA public TO rol_app_lectura;
GRANT USAGE ON SCHEMA public TO rol_app_escritura;
GRANT USAGE ON SCHEMA public TO rol_soporte;
GRANT USAGE ON SCHEMA public TO rol_reportes;
GRANT USAGE ON SCHEMA public TO app_web;
GRANT USAGE ON SCHEMA public TO admin_datos;

-- =========================================================
-- 5. GRUPOS DE LECTURA
-- =========================================================
GRANT SELECT ON TABLE public.categoria TO rol_app_lectura;
GRANT SELECT ON TABLE public.producto TO rol_app_lectura;
REVOKE SELECT ON TABLE public.usuario FROM rol_app_lectura;
GRANT SELECT (id, rol, activo, created_at)
    ON TABLE public.usuario TO rol_app_lectura;
GRANT SELECT ON TABLE public.pedido TO rol_app_lectura;
GRANT SELECT ON TABLE public.detalle_pedido TO rol_app_lectura;

GRANT SELECT ON TABLE public.categoria TO rol_soporte;
GRANT SELECT ON TABLE public.producto TO rol_soporte;
GRANT SELECT ON TABLE public.pedido TO rol_soporte;
GRANT SELECT ON TABLE public.detalle_pedido TO rol_soporte;
GRANT SELECT (id, nombre, email, rol, activo, created_at)
    ON TABLE public.usuario TO rol_soporte;

GRANT SELECT ON TABLE public.categoria TO rol_reportes;
GRANT SELECT ON TABLE public.producto TO rol_reportes;
GRANT SELECT ON TABLE public.pedido TO rol_reportes;
GRANT SELECT ON TABLE public.detalle_pedido TO rol_reportes;
GRANT SELECT (rol, created_at) ON TABLE public.usuario TO rol_reportes;

-- =========================================================
-- 6. GRUPOS DE ESCRITURA
-- =========================================================
-- Las operaciones normales del sistema pueden crear y actualizar datos de negocio.
GRANT INSERT, UPDATE ON TABLE public.producto TO rol_app_escritura;
GRANT INSERT, UPDATE ON TABLE public.pedido TO rol_app_escritura;
GRANT INSERT, UPDATE ON TABLE public.detalle_pedido TO rol_app_escritura;

-- Se permiten cambios mínimos sobre usuarios por parte de la app, pero no administración de roles ni automatismos de auditoría.
REVOKE SELECT (id, nombre, email, rol, activo, created_at)
    ON TABLE public.usuario FROM rol_app_escritura;
GRANT SELECT (id, rol, activo, created_at)
    ON TABLE public.usuario TO rol_app_escritura;
GRANT INSERT (nombre, email) ON TABLE public.usuario TO rol_app_escritura;
GRANT UPDATE (nombre, email) ON TABLE public.usuario TO rol_app_escritura;

-- Limitar admin_datos a operaciones CRUD; no necesita truncar tablas,
-- administrar triggers ni crear referencias desde otras tablas.
REVOKE REFERENCES, TRIGGER, TRUNCATE
    ON TABLE public.categoria, public.producto, public.usuario,
             public.pedido, public.detalle_pedido
    FROM admin_datos;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.categoria TO admin_datos;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.producto TO admin_datos;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.usuario TO admin_datos;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.pedido TO admin_datos;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.detalle_pedido TO admin_datos;

-- usuario_anon se crea en la Parte D y puede no existir al aplicar este script
-- en una instalación nueva. Si ya existe, retirar los privilegios excedentes.
DO $$
BEGIN
    IF to_regclass('public.usuario_anon') IS NOT NULL THEN
        REVOKE REFERENCES, TRIGGER, TRUNCATE
            ON TABLE public.usuario_anon FROM admin_datos;
        GRANT SELECT, INSERT, UPDATE, DELETE
            ON TABLE public.usuario_anon TO admin_datos;
    END IF;
END
$$;

-- =========================================================
-- 7. PERMISO A NIVEL DE COLUMNA (EJEMPLO)
-- =========================================================
-- rol_soporte puede marcar un usuario como activo o inactivo, pero no modificar su rol ni su email.
GRANT SELECT (id, nombre, email, rol, activo, created_at),
      UPDATE (activo) ON TABLE public.usuario TO rol_soporte;

-- =========================================================
-- 8. ALTER DEFAULT PRIVILEGES
-- =========================================================
-- Estos defaults se aplican a objetos creados en adelante por el rol que ejecuta
-- este script (postgres), no a tablas creadas por otros propietarios. Las tablas
-- futuras no reciben permisos automáticamente: concederlos explícitamente luego
-- de revisar qué datos contienen.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE SELECT ON TABLES FROM rol_app_lectura;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE ALL PRIVILEGES ON TABLES FROM admin_datos;

-- =========================================================
-- 9. PRIVILEGIOS DE SECUENCIA
-- =========================================================
-- Necesarios para columnas SERIAL. Las columnas IDENTITY suelen gestionar
-- internamente el acceso a su secuencia; el GRANT no amplía permisos de tabla.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_app_escritura;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO admin_datos;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE USAGE, SELECT ON SEQUENCES FROM rol_app_escritura;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE USAGE, SELECT ON SEQUENCES FROM admin_datos;

-- Fin del script
COMMIT;
