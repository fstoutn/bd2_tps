# Respuesta recibida de OpenCode - Parte C

La siguiente respuesta fue proporcionada por el estudiante como salida de
OpenCode. Se conserva para la entrega y se contrasta con la ejecución real en
`analisis_incidente_parte_c.md`.

---

## 1. Secuencia observada

La secuencia temporal del simulacro es la siguiente:

1. **08:39:31** — Se establece una conexión autenticada a PostgreSQL sobre `food_store_tp4` utilizando el rol `app_web` mediante **SCRAM-SHA-256**.
2. **08:39:46** — Desde esa sesión se ejecuta:

```sql
SELECT current_user, current_database();
```

Esto corresponde a una consulta de identificación del usuario y de la base de datos activa.

3. **08:39:58, 08:40:05 y 08:40:10** — Se realizan tres llamadas a:

```sql
SELECT public.fn_autenticar(...);
```

Según el contexto proporcionado, fueron **dos autenticaciones sintéticas fallidas y una exitosa**. Sin embargo, el extracto del log no registra los valores retornados por las funciones.

4. **08:40:23** — Se ejecuta una lectura completa ordenada de `public.usuario`:

```sql
SELECT * FROM public.usuario ORDER BY id;
```

La consulta devolvió filas, pero los datos personales fueron omitidos del extracto.

**Aclaración posterior del estudiante, basada en la salida de `psql`:** la consulta
devolvió **20.005 filas** y el tiempo informado fue **0,003 segundos**. Estos valores
provienen de la salida de ejecución, no del fragmento de log anonimizado.

5. **08:40:35** — La sesión intenta concederse a sí misma el rol `admin_datos`:

```sql
GRANT admin_datos TO app_web;
```

PostgreSQL rechaza la operación porque `app_web` no tiene autorización para otorgar ese rol.

6. Inmediatamente después queda registrado el error correspondiente:

```text
permiso denegado para otorgar el rol admin_datos
```

y se indica que solamente roles con la opción `ADMIN` sobre `admin_datos` pueden otorgarlo.

7. Según el contexto proporcionado, una consulta posterior sobre las membresías confirmó **cero filas** para `app_web` como miembro de `admin_datos`.

Por lo tanto, el incidente observado puede resumirse como:

**autenticación de la sesión → consultas de identificación → tres intentos de autenticación sintética → lectura de `usuario` → intento fallido de elevación de privilegios → verificación posterior de que no se obtuvo la membresía.**

---

## 2. Qué está confirmado por el log y qué depende del contexto/resultado de psql

### Confirmado directamente por el log

El log permite afirmar que:

- La sesión correspondía al rol `app_web`.
- La base utilizada era `food_store_tp4`.
- La autenticación de la sesión utilizó `scram-sha-256`.
- Se ejecutaron tres llamadas a `public.fn_autenticar`.
- Se ejecutó una lectura mediante `SELECT * FROM public.usuario ORDER BY id`.
- Se intentó ejecutar `GRANT admin_datos TO app_web`.
- PostgreSQL rechazó ese `GRANT` por falta de autorización.
- La sesión no consiguió ejecutar ese otorgamiento de rol.

También está confirmado temporalmente que las operaciones ocurrieron en el orden mostrado y dentro de la misma sesión identificada como `[PID-A]`.

### Respaldado por el contexto y la salida de psql

El contexto adicional permite establecer que:

- De las tres llamadas a `fn_autenticar`, **dos fueron fallidas y una exitosa**.
- `fn_autenticar` es una reconstrucción aislada de laboratorio y **no representa autenticación real de clientes**.
- La consulta sobre `public.usuario` **devolvió filas**.
- Una consulta posterior de membresías mostró **cero filas** para `app_web` como miembro de `admin_datos`.

Esto último es especialmente importante: el intento de `GRANT` **no produjo la elevación de privilegios simulada**.

---

## 3. Qué no puede inferirse

Hay varias conclusiones que sería incorrecto sacar de este material.

### No puede determinarse quién realizó las acciones

`app_web` identifica el **rol de PostgreSQL**, no a una persona concreta.

No puede inferirse:

- identidad humana;
- nombre del alumno;
- operador concreto;
- cuenta personal utilizada;
- intención del operador.

### No puede determinarse el origen real de la conexión

`[ORIGEN_LOCAL]` es una etiqueta anonimizada.

Por lo tanto, no puede afirmarse:

- una dirección IP;
- una máquina concreta;
- una ubicación geográfica;
- si realmente se trató de una conexión local en sentido técnico;
- desde qué dispositivo se realizó.

### No pueden conocerse los valores de las autenticaciones sintéticas

El log muestra:

```text
[USUARIO_SINTETICO]
[CLAVE_REDACTADA]
```

Por lo tanto, no puede saberse qué credenciales sintéticas concretas fueron utilizadas.

Además, aunque el contexto indica que hubo dos fallos y un éxito, el **orden de esos resultados no está indicado**. No sería correcto afirmar, por ejemplo, que las primeras dos fueron fallidas y la tercera exitosa.

### No puede determinarse qué datos concretos fueron leídos

Sabemos que:

```sql
SELECT * FROM public.usuario ORDER BY id;
```

se ejecutó y devolvió filas.

Pero el extracto no contiene esas filas. Por lo tanto, no podemos afirmar:

- qué usuarios fueron devueltos;
- qué nombres tenían;
- qué correos tenían;
- qué otros datos personales contenían;
- si algún dato concreto fue copiado, almacenado o utilizado posteriormente.

El resultado comunicado por el estudiante establece que se devolvieron 20.005 filas
en 0,003 segundos, pero no revela el contenido de esas filas ni demuestra si fueron
copiadas, almacenadas o utilizadas posteriormente. La cantidad y duración se
corroboran con la salida de `psql`, no con el extracto del log.

### No puede afirmarse que hubo escalada de privilegios

El intento de:

```sql
GRANT admin_datos TO app_web;
```

falló.

La consulta posterior de membresías, según el contexto, devolvió cero filas.

Por lo tanto, la evidencia disponible apunta a un **intento fallido de modificación de privilegios**, no a una escalada exitosa.

### Tampoco puede afirmarse una intención maliciosa

La secuencia podría ser compatible con una prueba de seguridad, una práctica de laboratorio, una prueba funcional o una acción no autorizada. El log por sí solo no permite distinguirlas.

En este caso, además, el contexto establece explícitamente que se trata de un **simulacro de laboratorio**.

---

## 4. Riesgos relevantes

Aunque sea un laboratorio y no producción, la secuencia permite identificar varios riesgos que serían relevantes en un sistema real.

### 1. Acceso de lectura a `public.usuario`

Es el riesgo más concreto observado.

La cuenta `app_web` pudo ejecutar:

```sql
SELECT * FROM public.usuario ORDER BY id;
```

y obtener filas.

Si `usuario` contuviera información personal o sensible en un entorno real, una aplicación que solamente necesitara determinadas columnas o registros podría estar teniendo **más acceso del necesario**.

### 2. Riesgo de exceso de privilegios de `app_web`

El hecho de que `app_web` pudiera consultar directamente `public.usuario` merece revisión.

La aplicación debería disponer únicamente de los permisos necesarios para sus operaciones. Una cuenta de aplicación con acceso amplio aumenta el impacto potencial de una vulnerabilidad de la aplicación o del compromiso de sus credenciales.

### 3. Intento de modificación de membresías

El:

```sql
GRANT admin_datos TO app_web;
```

fue rechazado, lo cual es positivo desde el punto de vista del control de privilegios.

Sin embargo, en un caso real, un intento de modificar roles debería considerarse un evento relevante y verificarse en los registros para determinar si hubo otros intentos similares.

### 4. Uso de una función de autenticación desde la sesión de aplicación

Las tres llamadas a `fn_autenticar` no demuestran por sí mismas un problema, especialmente porque en este laboratorio se trata de una reconstrucción aislada.

En un sistema real habría que verificar cuidadosamente qué permisos tiene una cuenta de aplicación sobre funciones de autenticación y qué información pueden revelar sus resultados.

---

## 5. Medidas de contención recomendadas para un caso real

Las medidas deberían ser **proporcionales a la evidencia**. No sería apropiado asumir automáticamente un compromiso completo de la base cuando lo observado es una lectura y un intento fallido de elevación.

### Acciones inmediatas

**1. Preservar la evidencia**

Antes de modificar innecesariamente el entorno:

- conservar los logs;
- conservar los registros de PostgreSQL correspondientes al período;
- preservar los eventos relacionados con `app_web`;
- registrar los horarios de interés: aproximadamente **08:39:31–08:40:35**.

Esto permite investigar sin destruir evidencia.

**2. Revisar temporalmente los permisos de `app_web`**

Determinar exactamente:

- qué privilegios tiene sobre `public.usuario`;
- qué otros objetos puede consultar;
- qué roles posee;
- qué roles puede asumir;
- qué privilegios indirectos tiene mediante membresías.

Si se detectan permisos que no son necesarios para la aplicación, revocarlos de forma controlada.

**3. Verificar la membresía de `admin_datos`**

Confirmar que `app_web` no sea miembro de `admin_datos` y que tampoco tenga una vía indirecta para obtener esa membresía.

En el simulacro, el contexto ya indica que la comprobación posterior dio **cero filas**, por lo que no hay evidencia de que esa elevación haya ocurrido.

**4. Si fuera necesario, limitar temporalmente la cuenta**

Si durante una investigación real aparecieran indicios adicionales de compromiso, podría justificarse restringir temporalmente `app_web` o rotar sus credenciales.

Pero **no sería proporcional hacerlo únicamente porque apareció el `GRANT` fallido** sin analizar primero el resto de la evidencia.

### Verificaciones posteriores

**5. Revisar actividad adicional de `app_web`**

Buscar en los logs del período:

- otros `GRANT` o `REVOKE`;
- cambios de membresías;
- `ALTER ROLE`;
- accesos a tablas adicionales;
- intentos repetidos de autenticación;
- otras consultas administrativas.

**6. Revisar exactamente qué permisos tenía históricamente**

Esto es importante porque el contexto advierte que los permisos fueron revisados **después del simulacro**.

Por lo tanto, los permisos actuales no deberían utilizarse automáticamente como prueba de cuáles existían durante el evento.

**7. Determinar el alcance real de la lectura de `usuario`**

Si los logs, auditoría o mecanismos complementarios disponibles lo permiten, comprobar:

- cuántas filas fueron devueltas;
- qué columnas estuvieron disponibles;
- si hubo consultas posteriores sobre esos datos;
- si existieron exportaciones o copias fuera de PostgreSQL.

Con el extracto presentado, esto **no puede determinarse**.

**8. Revisar el principio de mínimo privilegio**

Finalmente, para un entorno real sería recomendable que `app_web` tuviera únicamente los permisos indispensables y que las operaciones administrativas, especialmente la gestión de roles, estuvieran separadas de la cuenta utilizada por la aplicación.

---

### Conclusión

La evidencia muestra **una sesión autenticada como `app_web` que realizó tres autenticaciones sintéticas, posteriormente leyó `public.usuario` y finalmente intentó obtener el rol `admin_datos`, pero PostgreSQL rechazó la operación**.

Lo más importante es no sobredimensionar el incidente: **sí está respaldado un acceso de lectura y un intento fallido de elevación de privilegios; no está respaldada una escalada exitosa, una identidad humana, un origen concreto, una intención maliciosa ni el contenido exacto de los datos leídos.**
