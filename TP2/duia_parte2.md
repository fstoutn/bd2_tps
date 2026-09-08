# DUIA — Parte 2: Concurrencia

## Escenario 1 — Lectura no repetible

### Herramienta

ChatGPT.

### Prompt utilizado

Se solicitó reproducir y verificar el escenario de lectura no repetible utilizando dos sesiones concurrentes sobre PostgreSQL.

### Qué generó

La IA indicó los comandos SQL necesarios para:

- iniciar una transacción con `READ COMMITTED`;
- realizar una primera lectura;
- modificar y confirmar el mismo registro desde una segunda sesión;
- repetir la lectura desde la primera sesión;
- repetir posteriormente el experimento utilizando `REPEATABLE READ`.

### Qué se aceptó

Se utilizaron los comandos propuestos por la IA para realizar el experimento en PostgreSQL.

### Qué se modificó o descartó, y por qué

No se modificaron los comandos propuestos para el experimento.

Se tuvo que crear previamente una categoría y tres productos de prueba porque la copia de trabajo no contenía datos.

### Verificación realizada

Con `READ COMMITTED`, la primera lectura del producto 6 mostró un precio de `100.00`. Luego la Sesión B modificó el precio a `150.00` y confirmó la transacción. La segunda lectura de la Sesión A mostró `150.00`.

Posteriormente se repitió el experimento con `REPEATABLE READ`. La primera lectura mostró `100.00`, la Sesión B modificó el precio a `150.00` y confirmó la transacción, pero la segunda lectura de la Sesión A continuó mostrando `100.00`.

El comportamiento observado en PostgreSQL confirmó la explicación proporcionada por la IA.