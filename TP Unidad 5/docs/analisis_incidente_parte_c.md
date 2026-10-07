# Parte C - Análisis y decisión sobre el simulacro

## Respuesta de OpenCode

La respuesta completa recibida se conserva en
`respuesta_opencode_parte_c.md`. A continuación se valida contra la evidencia
ejecutada y se señalan los matices necesarios.

### Reconstrucción

1. La conexión de laboratorio se autenticó como `app_web` contra
   `food_store_tp4`, mediante SCRAM-SHA-256.
2. Desde esa sesión se consultó la identidad y la base de datos actuales.
3. Se invocó tres veces `fn_autenticar` con una identidad sintética. El extracto
   reemplaza los argumentos, así que el log por sí solo no permite saber cuáles
   fueron los resultados ni distinguir qué llamada tuvo éxito.
4. Luego se ejecutó una lectura ordenada de `public.usuario`.
5. Finalmente, la sesión intentó conceder a `app_web` el rol `admin_datos`.
   PostgreSQL rechazó el `GRANT`: el ejecutor no tenía la opción ADMIN necesaria.

### Hipótesis y límites de evidencia

La secuencia es compatible con una prueba controlada de autenticación, consulta de
usuarios y comprobación de los límites de privilegios. La lectura masiva seguida
del intento de escalamiento merece atención en un entorno real, pero el fragmento
no demuestra intención maliciosa ni una intrusión. Tampoco permite determinar
quién operaba la cuenta, el motivo de la consulta, el contenido devuelto por ella
ni el origen real de la conexión: el origen está anonimizado y los datos de usuario
no se incluyen.

La autenticación y el `GRANT` ocurren en la misma sesión identificada como
`app_web`; eso no demuestra que una persona concreta haya autenticado con la
identidad sintética mediante `fn_autenticar`. La clave y el usuario de laboratorio
son argumentos de una función dentro de PostgreSQL, separados de la autenticación
SCRAM de la conexión.

Como hipótesis de contención para un incidente real: preservar el log original con
acceso restringido, revisar actividad relacionada de la sesión y el alcance de
lectura de `app_web`, invalidar o rotar credenciales si existe sospecha fundada,
revocar cualquier membresía indebida si se hubiera concedido y evaluar notificación
según los datos posiblemente expuestos. No ejecutar estas medidas automáticamente
solo a partir de este fragmento.

## Contraste con lo ejecutado

La siguiente evidencia procede del resultado de `psql` y de las verificaciones
registradas en `Informe.txt`, no de los mensajes del log:

- Las dos llamadas con claves incorrectas devolvieron `false`; la tercera, con la
  credencial sintética válida, devolvió `true`.
- Según la salida de `psql` informada por el estudiante, la lectura masiva devolvió
  **20.005 filas** y tardó **0,003 segundos**. Estos datos no aparecen en el log.
  Los nombres y correos no se reproducen en esta entrega.
- `GRANT admin_datos TO app_web` falló por falta de autorización para conceder el
  rol. La consulta posterior de membresías devolvió cero filas para
  `app_web` como miembro de `admin_datos`.
- El log indica `food_store_tp4`, `app_web` y el orden de las sentencias. El origen
  fue reemplazado en el extracto, por lo que no es válido inferir una IP, ubicación
  o si era una red interna.
- El extracto muestra tres invocaciones a la función, pero no sus valores de retorno.
  Esos resultados se contrastaron con la salida de `psql`.
- La secuencia corresponde a un laboratorio con una función de autenticación
  reconstruida y una identidad sintética; no demuestra actividad de clientes reales
  ni que se haya accedido a una cuenta real.
- En el momento de la prueba, `app_web` podía leer la tabla `usuario` según el
  permiso configurado entonces. La política se revisó después: ahora el rol solo
  tiene SELECT de `id`, `rol`, `activo` y `created_at`, no de nombre ni email. Esto
  limita columnas, no filas, y no debe confundirse con el estado histórico del
  simulacro.

### Validación humana de la respuesta

OpenCode reconstruyó correctamente la secuencia principal, distinguió el log de los
resultados de `psql`, advirtió que se desconoce el orden de los resultados de
autenticación, no infirió la identidad humana ni el origen real, y dejó claro que el
intento de `GRANT` fue rechazado y no produjo la membresía verificada.

La expresión “lectura completa ordenada” describe la forma de la consulta
`SELECT * ... ORDER BY id`. La cantidad de 20.005 filas y el tiempo de 0,003 segundos
se agregaron después a partir de la salida de `psql`, no del log. Esto concreta el
volumen devuelto, pero no demuestra que los datos se exportaran, guardaran o usaran
fuera de la base; el contenido personal tampoco se incorpora a la entrega.

La recomendación de revisar permisos históricos también es pertinente: los permisos
se modificaron después del simulacro. La validación de Parte A posterior restringe
las columnas visibles actualmente para `app_web`, pero no puede usarse como evidencia
del estado exacto de permisos en el momento de C.

El contraste se apoya en las salidas de `psql` resumidas en `Informe.txt` y en el
log anonimizado; no se atribuye a OpenCode ninguna salida de ejecución que no aparezca
en esas evidencias.

## Decisión de contención del equipo

Para este simulacro no se realizará una acción de contención sobre producción ni se
bloquearán cuentas o direcciones: la prueba se ejecutó en `food_store_tp4` con una
identidad de laboratorio, y el intento de escalamiento fue rechazado. Se conserva
como evidencia que la membresía no se creó y que la política de lectura de
`app_web` fue posteriormente limitada por columna.

Ante un evento equivalente en un entorno real, el equipo preservaría el log original
con acceso restringido, investigaría la sesión y cualquier lectura de datos
personales, y decidiría si corresponde invalidar credenciales o sesiones y notificar
según el alcance confirmado. Solo se revocaría una membresía si la evidencia
demostrara que fue otorgada. La decisión se basa en las comprobaciones de `psql` y
en la revisión humana, no en una recomendación automática de IA.
