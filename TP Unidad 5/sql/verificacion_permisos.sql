-- Verificación de permisos de roles de Food Store
-- Ejecutar luego de crear los roles y otorgar privilegios.

\du

SELECT
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN (
    'rol_app_lectura',
    'rol_app_escritura',
    'rol_soporte',
    'rol_reportes',
    'app_web',
    'admin_datos'
)
ORDER BY grantee, table_schema, table_name, privilege_type;

SELECT
    grantee,
    table_schema,
    table_name,
    column_name,
    privilege_type
FROM information_schema.role_column_grants
WHERE grantee IN (
    'rol_app_lectura',
    'rol_app_escritura',
    'rol_soporte',
    'rol_reportes',
    'app_web',
    'admin_datos'
)
ORDER BY grantee, table_name, column_name, privilege_type;
