# Design - Roles y permisos Food Store

## Visión general
La estructura propuesta separa claramente cuatro grupos funcionales y dos roles de login. La intención es que cada identidad posea únicamente el conjunto de permisos que requiere para su tarea.

## Entorno objetivo
- Base de desarrollo: `food_store_tp4`.
- Usuario administrador para aplicar el script: `postgres`.
- Las contraseñas se configuran interactivamente y no se guardan en los archivos del repositorio.

## Roles de grupo

### rol_app_lectura
- Finalidad: acceso de consulta para la aplicación y usuarios operativos de lectura.
- Permisos: `SELECT` sobre `categoria`, `producto`, `pedido` y `detalle_pedido`; en `usuario`, solo las columnas `id`, `rol`, `activo` y `created_at`.
- Justificación: la aplicación puede identificar internamente una cuenta y consultar su estado sin leer nombre ni email de todos los usuarios; no se necesita capacidad de modificación.

### rol_app_escritura
- Finalidad: registrar cambios operativos normales del negocio.
- Permisos: `INSERT` y `UPDATE` sobre `producto`, `pedido` y `detalle_pedido`; en `usuario`, puede consultar `id`, `rol`, `activo` y `created_at`, e insertar/actualizar solo nombre y email. No puede asignar el rol ni activar cuentas.
- Justificación: la app necesita actualizar datos de negocio, pero no debe administrar roles ni realizar tareas de mantenimiento estructural.

### rol_soporte
- Finalidad: revisar incidencias y atender consultas del cliente.
- Permisos: `SELECT` sobre tablas principales; sobre `usuario`, solo puede consultar columnas de soporte y ejecutar `UPDATE (activo)`.
- Justificación: soporte necesita activar o desactivar cuentas y consultar pedidos/usuarios, pero no debe cambiar datos de negocio ni permisos de seguridad.

### rol_reportes
- Finalidad: acceso analítico y consultas agregadas.
- Permisos: `SELECT` sobre tablas de negocio para reportes y métricas; en `usuario`, solo `rol` y `created_at`, requeridas para el agregado de usuarios por rol y mes.
- Justificación: la analítica no requiere operaciones de escritura ni acceso administrativo.

## Roles de login

### app_web
- Finalidad: identidad de acceso de la aplicación web.
- Permisos: hereda `rol_app_lectura` y `rol_app_escritura`.
- Justificación: la app debe operar con permisos funcionales, pero no con autoridad técnica ni de administración.

### admin_datos
- Finalidad: operación de mantenimiento sobre datos del negocio.
- Permisos: privilegios completos sobre tablas de negocio y acceso a los roles de soporte y reportes.
- Justificación: se reserva para la administración operativa de datos y no se usa como acceso general del usuario final.

## Política de permisos

- Se evitarán permisos de tipo `ALL` sobre el esquema para roles no administrativos.
- Se utilizará un ejemplo de permiso a nivel de columna para limitar el alcance de soporte sobre `usuario`.
- Se aplicará `ALTER DEFAULT PRIVILEGES` para evitar que las tablas y secuencias futuras reciban permisos de forma automática. Cada objeto nuevo deberá revisarse y recibir GRANT explícitos según sus datos y uso.
- `ALTER DEFAULT PRIVILEGES` afecta solo a los objetos que cree el rol que ejecuta esa sentencia; si otro propietario crea tablas, deberá configurar sus defaults por separado.
- Los permisos de lectura, escritura, soporte, reportes y administración sobre tablas y secuencias nuevas se conceden explícitamente por objeto para no ampliar el acceso automáticamente a datos sensibles.
- Se prevé que la administración de la base no se extienda a objetos del sistema ni funciones internas del motor.

## Resultado esperado
Cada rol queda documentado y validado contra `information_schema.role_table_grants` para asegurarse de que tiene exactamente los privilegios esperados y no más.
