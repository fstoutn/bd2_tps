# Requerimientos - Roles y permisos Food Store

## Objetivo
Diseñar un esquema mínimo de privilegios para Food Store que permita separar lectura, escritura, soporte, reportes y administración sin otorgar más permisos de los necesarios.

## Requisitos funcionales

1. Debe existir un rol de lectura para consultas normales del sistema.
   - Permite consultar catálogo, pedidos y usuarios necesarios para operar la aplicación.
   - No debe permitir escritura ni administración de estructura.

2. Debe existir un rol de escritura para la lógica de negocio.
   - Permite crear y actualizar datos de ventas, productos y pedidos.
   - No debe otorgar permisos de administración del esquema ni de gestión de roles.

3. Debe existir un rol de soporte para gestión de atención al cliente.
   - Permite revisar información de clientes y pedidos para resolver incidencias.
   - No debe poder cambiar roles, ni alterar datos sensibles que no correspondan a su tarea.

4. Debe existir un rol de reportes para consumo analítico.
   - Permite consultar agregado y métricas.
   - No debe poder modificar ni administrar datos transaccionales.

5. Debe existir un rol de login para la app web.
   - Actúa como identidad de la aplicación y hereda permisos funcionales del negocio.
   - No es un rol administrativo.

6. Debe existir un rol de administración de datos.
   - Permite tareas de mantenimiento operativo sobre los datos de negocio.
   - Se reserva para la operación técnica y no reemplaza la separación de roles.

## Requisitos de seguridad

- Aplicar principio de mínimo privilegio.
- Evitar permisos de DDL para roles funcionales.
- No otorgar acceso total a todas las tablas a roles de lectura o soporte.
- Usar control de columnas cuando una operación requiere un alcance reducido.
- Proteger la base con privilegios heredados por roles y con default privileges coherentes.
- Las tablas futuras no deben otorgar acceso automáticamente a roles funcionales o de aplicación; los permisos deben concederse explícitamente luego de revisar la sensibilidad de la tabla.
- La aplicación no debe recibir SELECT sobre todas las columnas de `usuario`; el acceso de lectura se limita a `id`, `rol`, `activo` y `created_at`. Este permiso de columnas no restringe las filas visibles.

## Criterio de validación
El esquema será correcto si cada rol tiene exactamente los permisos definidos en la especificación y no se observa ningún privilegio extra en `information_schema.role_table_grants`.
