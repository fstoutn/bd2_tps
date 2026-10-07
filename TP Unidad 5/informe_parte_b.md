# Informe - Parte B: Auditoría en PostgreSQL

## Verificación de la configuración

Se consultó `pg_settings` para comprobar los parámetros de auditoría configurados
en el servidor PostgreSQL 17. Los cuatro parámetros aparecen con origen
`configuration file`, cargados desde
`C:/Program Files/PostgreSQL/17/data/postgresql.auto.conf`, y con
`pending_restart = false`.

La recarga de configuración devolvió `true`. La consulta directa con `SHOW`
confirmó estos valores:

| Parámetro | Valor efectivo | Contexto | Resultado |
|---|---|---|---|
| `log_connections` | `on` | `superuser-backend` | Activo |
| `log_disconnections` | `on` | `superuser-backend` | Activo |
| `log_statement` | `all` | `superuser` | Activo; registra todas las sentencias, incluidos los `SELECT` |
| `log_line_prefix` | `%m [%p] %u@%d %h ` | `sighup` | Activo; incluye hora, PID, usuario, base de datos y host en el prefijo |

Salida de `SHOW` registrada:

```text
log_connections    on
log_disconnections on
log_statement      all
log_line_prefix    %m [%p] %u@%d %h
```

### Análisis

La configuración solicitada quedó aplicada correctamente. La columna
`pending_restart = false` indica que estos valores no están pendientes de un
reinicio del servidor. El contexto `sighup` de `log_line_prefix` permite aplicar
el cambio mediante recarga de configuración; los otros valores también aparecen
ya como efectivos en `pg_settings`.

La consulta a `pg_file_settings` muestra que los cuatro valores definidos en
`postgresql.auto.conf` tienen `applied = true`. También aparece una definición
anterior de `log_line_prefix` (`%t`) en `postgresql.conf`, con `applied = false`;
no es un error: queda reemplazada por el valor posterior de
`postgresql.auto.conf`, que es el que está aplicado y coincide con `pg_settings`.

`log_statement = 'all'` se mantiene temporalmente para capturar también lecturas
durante la prueba. Los logs pueden contener sentencias y datos sensibles, por lo
que deben compartirse solo después de revisar y anonimizar su contenido.

## Prueba de lectura, escritura y reversión

Se ejecutó la secuencia transaccional indicada para la prueba. El `SELECT` sobre
`public.usuario` devolvió cinco filas. No se reproducen nombres, emails ni otros
datos personales de esas filas en este informe.

El `INSERT`, el `UPDATE` y el `ROLLBACK` se ejecutaron correctamente. Al finalizar
con `ROLLBACK`, se revirtieron los cambios realizados dentro de la transacción.

En un nombre de la salida se observó una secuencia de caracteres acentuados mal
interpretada, compatible con un problema de codificación al mostrar el texto.
Esta salida por sí sola no permite concluir que el dato almacenado esté corrupto;
queda pendiente verificar la codificación de la conexión y del cliente si la
anomalía también aparece en otras consultas o herramientas.

## Consulta del archivo de log e intento de login fallido

El primer intento de ejecutar `psql -U usuario_invalido -d food_store_tp4 -h
localhost -W` se hizo dentro del prompt de `psql`, que lo interpretó como SQL y
devolvió un error de sintaxis. Luego se corrigió ejecutándolo desde PowerShell,
fuera de la sesión interactiva. El servidor rechazó la conexión por fallo de
autenticación del usuario `usuario_invalido` en `localhost` (`::1`), como se
esperaba para esta prueba.

La consulta `SHOW log_filename` devolvió el patrón
`postgresql-%Y-%m-%d_%H%M%S.log`. Este patrón contiene marcadores de fecha y hora,
no el nombre concreto del archivo generado. `SHOW log_directory` devolvió
`log` y `SHOW logging_collector` devolvió `on`, confirmando que el servidor
escribe los logs en archivos. Como `log` es una ruta relativa, se resuelve bajo
el directorio de datos de PostgreSQL; para esta instalación, la ubicación
esperada es
`C:/Program Files/PostgreSQL/17/data/log`. El nombre del archivo efectivo
incluye la fecha y la hora en que se creó.

Se revisó el archivo `postgresql-2026-10-06_154728.log`. En el fragmento
recuperado aparecen la lectura, la inserción y la actualización de la prueba,
además del intento de autenticación fallido. Se omiten entradas repetidas de la
misma secuencia. Para completar la evidencia de conexión, se consultó también
`postgresql-2026-10-07_075226.log`, informado por `pg_current_logfile()`.

```text
2026-10-06 17:25:56.789 -03 [PID-A] usuario_prueba@food_store_tp4 [ORIGEN_LOCAL] LOG: ejecutar <unnamed>: SELECT id, nombre, email FROM public.usuario LIMIT 5
2026-10-06 17:27:13.283 -03 [PID-A] usuario_prueba@food_store_tp4 [ORIGEN_LOCAL] LOG: ejecutar <unnamed>: INSERT INTO public.categoria (nombre, activo)
2026-10-06 17:27:20.176 -03 [PID-A] usuario_prueba@food_store_tp4 [ORIGEN_LOCAL] LOG: ejecutar <unnamed>: UPDATE public.producto
2026-10-06 17:31:31.164 -03 [PID-B] usuario_invalido@food_store_tp4 [ORIGEN_LOCAL] FATAL: la autentificación password falló para el usuario «usuario_invalido»
2026-10-06 17:31:31.164 -03 [PID-B] usuario_invalido@food_store_tp4 [ORIGEN_LOCAL] DETALLE: No existe el rol «usuario_invalido».
```

Evidencia adicional de una conexión válida y cierre normal, con PID y origen
local sustituidos por etiquetas:

```text
2026-10-07 10:53:00.074 -03 [PID-C] [DESCONOCIDO]@[DESCONOCIDO] [ORIGEN_LOCAL] LOG: conexión recibida
2026-10-07 10:53:00.095 -03 [PID-C] postgres@food_store_tp4 [ORIGEN_LOCAL] LOG: conexión autenticada: método=scram-sha-256
2026-10-07 10:53:00.095 -03 [PID-C] postgres@food_store_tp4 [ORIGEN_LOCAL] LOG: conexión autorizada: usuario=postgres base_de_datos=food_store_tp4 aplicación=psql
2026-10-07 10:53:00.156 -03 [PID-C] postgres@food_store_tp4 [ORIGEN_LOCAL] LOG: desconexión: duración de sesión 0:00:00.098
```

El servidor registró el usuario, la base de datos, el host y las sentencias
ejecutadas. La autenticación fallida se debió a que el rol de prueba no existe.
Los acentos del mensaje se presentan normalizados en este informe; la consola
mostró caracteres de reemplazo por la diferencia de páginas de código.
La salida filtrada no incluye la entrada de `ROLLBACK`; la reversión se comprobó
por el resultado de la ejecución informado durante la prueba.

## Alcance de la auditoría nativa

El prefijo del log permite asociar cada evento con hora, PID, usuario, base y origen
de conexión. Con `log_connections` y `log_disconnections` se registran aperturas y
cierres de sesión; con `log_statement = 'all'` se registran sentencias como lecturas
e inserciones/actualizaciones. En esta captura, la consulta de lectura, el `INSERT`,
el `UPDATE` y el rechazo de autenticación permiten reconstruir parte de la secuencia.

El log nativo no ofrece por sí solo una auditoría de negocio fila por fila: no
garantiza una descripción de los valores anteriores y nuevos de cada fila afectada,
el motivo de negocio del cambio ni la identidad de la persona detrás de una cuenta
compartida. Una sentencia SQL registrada no demuestra por sí sola qué filas cambiaron
ni si la transacción terminó confirmada. En esta prueba, la entrada de `ROLLBACK` no
aparece en el fragmento conservado; su ejecución se corroboró por separado. Para una
trazabilidad más granular pueden evaluarse mecanismos como `pgaudit` y auditoría
explícita a nivel de aplicación, según el requisito y el impacto operativo.

## Sensibilidad y acceso al log

El log es un activo sensible: puede revelar nombres de roles, bases, hosts o IPs,
sentencias SQL, patrones de acceso y, si se registran, valores incluidos en las
sentencias. Debe acceder solo el personal autorizado que lo necesite para operar o
investigar, como DBA y equipos de seguridad/operaciones designados. El acceso debe
limitarse mediante permisos del sistema operativo y controles administrativos del
motor; no debe publicarse ni compartirse en bruto. Antes de entregar fragmentos,
revisar y redactar credenciales, datos personales, direcciones y otros identificadores.

## Restauración del nivel de registro

Después de capturar el log, se ejecutó `ALTER SYSTEM SET log_statement = 'mod'`
y `SELECT pg_reload_conf()`. La recarga devolvió `true` y `SHOW log_statement`
confirmó el valor `mod`. Así se dejó de registrar toda sentencia y se restauró
el nivel requerido para registrar sentencias de modificación.

## Estado

La Parte B quedó completada: se verificó la configuración, se ejecutó y revirtió
la prueba SQL, se capturó evidencia de la conexión autenticada, su desconexión y
el intento fallido de autenticación; también se documentó la restauración de
`log_statement` a `mod`.
