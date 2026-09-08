# Informe de Concurrencia

## Escenario 1 — Lectura no repetible

### Escenario

Se reprodujo una lectura no repetible utilizando dos sesiones concurrentes sobre PostgreSQL.

Primero se utilizó el nivel de aislamiento `READ COMMITTED` para demostrar que una misma consulta puede devolver resultados diferentes dentro de una misma transacción.

Luego se repitió el experimento utilizando `REPEATABLE READ` para verificar que la segunda lectura conserva el valor observado al comienzo de la transacción.

Producto utilizado:

- ID: 6
- Nombre: Producto Concurrencia 1

### Cómo se reprodujo — READ COMMITTED

#### Sesión A — primera lectura

```sql
BEGIN;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 6;

Resultado:

6 | Producto Concurrencia 1 | 100.00

La transacción de la Sesión A quedó abierta.

Sesión B — modificación
BEGIN;

UPDATE producto
SET precio_lista = 150.00
WHERE id = 6;

COMMIT;

La modificación fue confirmada correctamente.

Sesión A — segunda lectura
SELECT id, nombre, precio_lista
FROM producto
WHERE id = 6;

Resultado:

6 | Producto Concurrencia 1 | 150.00

La primera lectura había devuelto 100.00 y la segunda 150.00.

Qué se observó

Con READ COMMITTED, la misma consulta realizada dos veces dentro de una misma transacción devolvió valores diferentes porque la Sesión B confirmó una modificación entre ambas lecturas.

Esto demuestra una lectura no repetible.

Verificación con REPEATABLE READ

Se restauró previamente el precio del producto a 100.00.

Sesión A — primera lectura
BEGIN;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 6;

Resultado:

6 | Producto Concurrencia 1 | 100.00
Sesión B — modificación
BEGIN;

UPDATE producto
SET precio_lista = 150.00
WHERE id = 6;

COMMIT;

La modificación fue confirmada correctamente.

Sesión A — segunda lectura
SELECT id, nombre, precio_lista
FROM producto
WHERE id = 6;

Resultado:

6 | Producto Concurrencia 1 | 100.00

Aunque la Sesión B había confirmado el cambio a 150.00, la Sesión A continuó observando 100.00 durante su transacción.

Explicación de la IA

Con READ COMMITTED, cada sentencia obtiene una vista consistente de los datos en el momento en que comienza esa sentencia. Por eso, si otra transacción confirma un cambio entre dos consultas, la segunda consulta puede observar el nuevo valor.

Con REPEATABLE READ, la transacción mantiene una vista consistente de los datos correspondiente al inicio de la transacción. Por eso, aunque otra sesión confirme modificaciones posteriormente, las consultas realizadas por la primera sesión continúan observando el mismo valor.

Verificación en el motor

La explicación fue verificada repitiendo el experimento en PostgreSQL.

Los resultados fueron:

### Verificación en el motor

Se verificó el comportamiento utilizando dos sesiones concurrentes de PostgreSQL.

La Sesión A inició una transacción y ejecutó:

```sql
BEGIN;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 7
FOR UPDATE;

La consulta devolvió:

7 | Producto Concurrencia 2 | 200.00

La Sesión B inició otra transacción y ejecutó la misma consulta sobre el producto 7:

BEGIN;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 7
FOR UPDATE;

La Sesión B quedó esperando debido al bloqueo mantenido por la Sesión A.

Luego la Sesión A ejecutó:

COMMIT;

Después de liberar el bloqueo, la Sesión B continuó y obtuvo el producto 7 correctamente.

Finalmente, se ejecutó ROLLBACK en la Sesión B para cerrar la transacción.

El comportamiento observado confirmó la explicación proporcionada por la IA.


Guardá el archivo.

---

## 2. Actualizá también la DUIA Parte 2

En `duia_parte2.md`, buscá:

```text
### Verificación realizada

dentro de Escenario 3 y reemplazá esa sección por:

### Verificación realizada

La Sesión A obtuvo un bloqueo sobre el producto 7 mediante `SELECT ... FOR UPDATE`.

La Sesión B intentó obtener un bloqueo sobre la misma fila y quedó esperando.

Después de que la Sesión A realizó `COMMIT`, el bloqueo fue liberado y la Sesión B pudo continuar y obtener el producto 7.

Finalmente, se realizó `ROLLBACK` en la Sesión B para cerrar la transacción.

El comportamiento observado confirmó la explicación proporcionada por la IA.

Conclusión

La lectura no repetible se reprodujo correctamente con READ COMMITTED.

El experimento confirmó que READ COMMITTED permite que dos lecturas consecutivas dentro de una misma transacción observen versiones diferentes de una fila si otra transacción confirma una modificación entre ambas.

Al repetir el experimento con REPEATABLE READ, la segunda lectura mantuvo el valor observado al comienzo de la transacción, evitando la lectura no repetible.

Escenario 2 — Lectura fantasma
Escenario

Se reprodujo una lectura fantasma utilizando dos sesiones concurrentes sobre PostgreSQL.

Se utilizó el nivel de aislamiento READ COMMITTED. La Sesión A realizó un COUNT dentro de una transacción y luego la Sesión B insertó un nuevo producto que cumplía la condición del WHERE y confirmó la transacción.

Cómo se reprodujo
Sesión A — primera lectura
BEGIN;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT COUNT(*) AS cantidad_productos_activos
FROM producto
WHERE activo = TRUE;

Resultado:

cantidad_productos_activos
3
Sesión B — inserción
BEGIN;

INSERT INTO producto (
    nombre,
    precio_lista,
    stock,
    activo,
    categoria_id
)
VALUES (
    'Producto Fantasma',
    400.00,
    10,
    TRUE,
    (SELECT id FROM categoria WHERE nombre = 'Categoria Concurrencia')
);

COMMIT;

La inserción fue confirmada correctamente.

Sesión A — segunda lectura
SELECT COUNT(*) AS cantidad_productos_activos
FROM producto
WHERE activo = TRUE;

Resultado:

cantidad_productos_activos
4
Qué se observó

La primera consulta devolvió 3 productos activos.

Después de que la Sesión B insertó y confirmó un nuevo producto activo, la misma consulta realizada nuevamente desde la Sesión A devolvió 4.

El nuevo registro apareció en la segunda lectura porque cumplía la condición activo = TRUE.

Esto demuestra una lectura fantasma bajo READ COMMITTED.

Explicación de la IA

Con READ COMMITTED, cada sentencia obtiene una vista de los datos correspondiente al momento en que comienza esa sentencia. Por lo tanto, si otra transacción confirma una nueva fila que cumple la condición de la consulta entre dos ejecuciones, la segunda consulta puede incluir esa fila.

Verificación en el motor

La explicación fue verificada repitiendo el experimento en PostgreSQL.

La primera consulta devolvió 3 registros. La Sesión B insertó y confirmó un nuevo producto activo. La segunda consulta devolvió 4 registros.

El resultado confirmó la explicación proporcionada por la IA.

Conclusión

La lectura fantasma se reprodujo correctamente con READ COMMITTED.

La segunda ejecución de la consulta observó una fila nueva que no existía en el resultado de la primera consulta.

Al utilizar REPEATABLE READ, PostgreSQL mantiene una vista consistente durante la transacción, evitando que una segunda consulta observe nuevas filas confirmadas posteriormente.

Escenario 3 — Espera por bloqueo
Escenario

Se reprodujo una espera por bloqueo utilizando dos sesiones concurrentes sobre PostgreSQL.

La Sesión A tomó un bloqueo de actualización sobre una fila de la tabla producto mediante SELECT ... FOR UPDATE. Mientras la transacción de A permanecía abierta, la Sesión B intentó obtener un bloqueo de actualización sobre la misma fila.

Cómo se reprodujo
Sesión A
BEGIN;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 7
FOR UPDATE;

Resultado:

7 | Producto Concurrencia 2 | 200.00

La transacción permaneció abierta, manteniendo el bloqueo sobre la fila.

Sesión B
BEGIN;

SELECT id, nombre, precio_lista
FROM producto
WHERE id = 7
FOR UPDATE;

La Sesión B quedó esperando debido al bloqueo mantenido por la Sesión A.

Sesión A
COMMIT;

Al liberar el bloqueo mediante COMMIT, la Sesión B pudo continuar y obtener la fila.

Qué se observó

La segunda sesión no pudo obtener inmediatamente el bloqueo porque la fila ya estaba bloqueada por la primera sesión.

La espera finalizó cuando la Sesión A confirmó su transacción y liberó el bloqueo.

Explicación de la IA

SELECT ... FOR UPDATE solicita un bloqueo de actualización sobre las filas seleccionadas. Si otra transacción ya posee un bloqueo incompatible sobre la misma fila, la segunda transacción debe esperar hasta que el bloqueo sea liberado mediante COMMIT o ROLLBACK.

Verificación en el motor

La explicación fue verificada utilizando dos sesiones concurrentes.

La Sesión A obtuvo primero el bloqueo sobre el producto 7. La Sesión B quedó esperando al solicitar un bloqueo sobre la misma fila. Después del COMMIT de A, B pudo continuar.

El comportamiento observado coincidió con la explicación de la IA.

Conclusión

La espera por bloqueo se reprodujo correctamente.

El mecanismo SELECT ... FOR UPDATE permite bloquear una fila para operaciones concurrentes y PostgreSQL hace esperar a otra transacción cuando solicita un bloqueo incompatible sobre la misma fila.

La espera termina cuando la transacción que posee el bloqueo realiza COMMIT o ROLLBACK.


---

# 2. Reemplazá `duia_parte2.md` completo

Ahora reemplazá todo su contenido por:

```markdown
# DUIA — Parte 2: Concurrencia

## Escenario 1 — Lectura no repetible

### Herramienta

ChatGPT.

### Prompt utilizado

Se solicitó reproducir y verificar el escenario de lectura no repetible utilizando dos sesiones concurrentes sobre PostgreSQL.

### Qué generó

La IA indicó los comandos SQL necesarios para iniciar transacciones con diferentes niveles de aislamiento, realizar lecturas y modificaciones concurrentes y verificar el comportamiento de `READ COMMITTED` y `REPEATABLE READ`.

### Qué se aceptó

Se utilizaron los comandos propuestos por la IA para realizar el experimento en PostgreSQL.

### Qué se modificó o descartó, y por qué

No se modificaron los comandos propuestos para el experimento.

Se tuvo que crear previamente una categoría y tres productos de prueba porque la copia de trabajo no contenía datos.

### Verificación realizada

Con `READ COMMITTED`, la primera lectura del producto 6 mostró un precio de `100.00`. Luego la Sesión B modificó el precio a `150.00` y confirmó la transacción. La segunda lectura de la Sesión A mostró `150.00`.

Posteriormente se repitió el experimento con `REPEATABLE READ`. La primera lectura mostró `100.00`, la Sesión B modificó el precio a `150.00` y confirmó la transacción, pero la segunda lectura de la Sesión A continuó mostrando `100.00`.

El comportamiento observado en PostgreSQL confirmó la explicación proporcionada por la IA.


## Escenario 2 — Lectura fantasma

### Herramienta

ChatGPT.

### Prompt utilizado

Se solicitó reproducir y verificar una lectura fantasma utilizando dos sesiones concurrentes sobre PostgreSQL.

### Qué generó

La IA indicó los comandos SQL necesarios para realizar un `COUNT` dentro de una transacción, insertar una nueva fila desde una segunda sesión y repetir el `COUNT` para verificar el comportamiento de `READ COMMITTED`.

### Qué se aceptó

Se utilizaron los comandos propuestos por la IA para realizar el experimento.

### Qué se modificó o descartó, y por qué

No se modificaron los comandos utilizados para el experimento.

### Verificación realizada

La primera consulta de la Sesión A devolvió `3` productos activos. La Sesión B insertó un nuevo producto activo y confirmó la transacción. La segunda consulta de A devolvió `4` productos activos.

El resultado confirmó la existencia de una lectura fantasma bajo `READ COMMITTED`.


## Escenario 3 — Espera por bloqueo

### Herramienta

ChatGPT.

### Prompt utilizado

Se solicitó reproducir y verificar un escenario de espera por bloqueo utilizando dos sesiones concurrentes y `SELECT ... FOR UPDATE` en PostgreSQL.

### Qué generó

La IA indicó los comandos SQL necesarios para que una sesión obtuviera un bloqueo mediante `FOR UPDATE` y una segunda sesión solicitara un bloqueo sobre la misma fila.

### Qué se aceptó

Se utilizaron los comandos propuestos para reproducir el bloqueo y observar la espera de la segunda sesión.

### Qué se modificó o descartó, y por qué

No se modificaron los comandos utilizados para el experimento.

### Verificación realizada

La Sesión A obtuvo un bloqueo sobre el producto 7 mediante `SELECT ... FOR UPDATE`.

La Sesión B intentó obtener un bloqueo sobre la misma fila y quedó esperando.

Después de que la Sesión A realizó `COMMIT`, el bloqueo fue liberado y la Sesión B pudo continuar.

El comportamiento observado confirmó la explicación proporcionada por la IA.