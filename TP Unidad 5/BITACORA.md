# Bitácora de uso de IA - Trabajo Práctico Unidad 5

Los prompts de A, B y D se resumen fielmente a partir del intercambio de trabajo;
no se presentan como citas literales. En C se recibió y conservó la respuesta de
OpenCode que compartió el estudiante. Las validaciones humanas se contrastaron con
los archivos y salidas de PostgreSQL disponibles.

| Prompt enviado a la IA | Respuesta relevante recibida | Validación o corrección humana aplicada |
|---|---|---|
| **Parte A.** Revisar el informe y los permisos de roles; ayudar a cerrar lo pendiente de mínimo privilegio. | Copilot identificó que el script original concedía `ALL PRIVILEGES` a `admin_datos`, incluidos `TRUNCATE`, `TRIGGER` y `REFERENCES`, y que el `SELECT` de `rol_app_lectura` permitía a `app_web` leer todas las columnas de `usuario`. También detectó que los privilegios por defecto podían extender acceso a tablas futuras. | Se revisaron `\du`, `role_table_grants`, `role_column_grants` y `\ddp`. Se decidió limitar `admin_datos` a CRUD; reducir la lectura de `app_web` en `usuario` a `id`, `rol`, `activo` y `created_at`; y retirar los grants automáticos sobre tablas y secuencias futuras. Se aplicó el script y se verificó que `\ddp` quedó vacío y que el permiso efectivo de `app_web` no incluye `nombre`, `email` ni `SELECT` de tabla completa. |
| **Parte B.** Revisar el avance de auditoría PostgreSQL y determinar qué faltaba para completar la evidencia. | Copilot contrastó el informe específico con el general, observó que el informe general estaba desactualizado, eliminó nombres y correos personales del informe de B, completó el análisis de qué registra/no registra el log y quién debe acceder. También señaló que faltaba evidencia explícita de conexión autenticada y desconexión. | Se verificó la ruta del log y se ejecutó una conexión corta a `food_store_tp4`. El log mostró conexión recibida, autenticación SCRAM, autorización y desconexión con el mismo PID. Se anonimizó el origen y se añadió esa evidencia. Se mantuvo `log_statement = mod` tras la prueba. |
| **Parte C.** Revisar qué faltaba para cerrar el simulacro; reconstruir la secuencia, contrastar la respuesta de IA y documentar contención. | OpenCode reconstruyó el orden: sesión `app_web`, tres llamadas a `fn_autenticar`, lectura de `usuario` y `GRANT` rechazado. Separó el contenido del log de los resultados aportados por `psql` y advirtió que no se puede inferir identidad humana, origen, intención ni contenido exacto leído. | Se contrastó con `psql`: dos autenticaciones sintéticas fallidas y una exitosa; el `GRANT` fue rechazado y la consulta de membresías devolvió cero filas para `app_web` en `admin_datos`. El estudiante informó que la lectura devolvió 20.005 filas en 0,003 segundos; se registró como dato de `psql`, no del log. Se aclaró que no hay evidencia de exportación de datos y que los permisos actuales de `app_web` son posteriores al simulacro. Se eligió no aplicar contención de producción a un laboratorio; la decisión para un caso real queda condicionada a investigación y evidencia. La respuesta completa se conserva en `docs/respuesta_opencode_parte_c.md` y el contraste en `docs/analisis_incidente_parte_c.md`. |
| **Parte D.** Revisar si la anonimización y la verificación agregada estaban completas. | Copilot confirmó que el script se detiene si `usuario_anon` ya existe y que la consulta compara agregados reales y anonimizados, devolviendo diferencias. Señaló que faltaba responder explícitamente qué datos no deben compartirse con una IA. | Se contrastó `docs/verificacion_equivalencia.md`: 20.005 filas sintéticas, mismos grupos por rol/mes y cero filas en la consulta final de diferencias. Se añadió la respuesta sobre nombres, emails, direcciones, identificadores, credenciales, datos sensibles y combinaciones que permitan reidentificación. No se compartieron filas personales. |

## Caso significativo de recomendación insegura y corrección

Durante la revisión de A, Copilot propuso inicialmente conservar privilegios por
defecto para objetos futuros: `SELECT` a `rol_app_lectura` y CRUD a `admin_datos`
en todas las tablas nuevas del esquema `public`. Esa recomendación era demasiado
amplia: podía conceder acceso automáticamente a una tabla futura sensible sin
revisar su contenido ni su propósito.

El problema se detectó al revisar el alcance de `ALTER DEFAULT PRIVILEGES` y la
salida de `\ddp`, que mostró esos permisos por defecto (`r` para lectura y `arwd`
para CRUD). El estudiante eligió retirar los grants automáticos. Se actualizó
`roles.sql` para revocar esos defaults y exigir concesiones explícitas después de
revisar cada tabla o secuencia; la verificación posterior de `\ddp` devolvió cero
filas. Este fue el error de recomendación más significativo identificado: el
control de defaults debía priorizar mínimo privilegio en lugar de acceso
automático a objetos futuros.

## Revisión del historial de Git

La revisión realizada en la Parte E mostró este historial:

```text
e1f86ab Añadiendo TP5 y TP6 con las carpetas que faltaban
202f9f7 tp4
4e52c90 se agrega tp3
9e90287 Se agrega tp2
d791cbc Merge branch 'main' of https://github.com/fstoutn/bd2_tps
a95b267 Initial commit
2e4614a Primer commit: Estructura unificada de BD2
```

Al iniciar la Parte E, `main` estaba sincronizada con `origin/main` y toda la carpeta
`TP Unidad 5/` figuraba sin seguimiento. Para representar el avance por partes se
crearon commits separados:

```text
099295d Se realiza Parte A: roles y permisos
f1a54d7 Se realiza Parte B: auditoria de PostgreSQL
0f45264 Se realiza Parte C: simulacro y analisis de incidente
e0027fb Se realiza Parte D: anonimización y equivalencia
```

El commit de Parte E incluye esta bitácora, el informe general y la guía operativa
`Probar.txt`. Se dejaron fuera las guías `Parte A.txt` a `Parte E.txt`, el enunciado
`tp unidad 5.txt` y `Trabajo Practico Unidad 5.pdf`, según la decisión del estudiante.
Los archivos de entrega incluidos se revisaron selectivamente; no se agregó el log
original sin anonimizar.

Los commits se crean localmente primero y se publican en `origin` al terminar esta
revisión. Después del push, `git log --oneline --decorate --graph` debe mostrar los
cinco commits de A–E y `git status` debe confirmar que los cambios entregables están
sin modificar; los archivos de consignas excluidos pueden permanecer sin seguimiento.
