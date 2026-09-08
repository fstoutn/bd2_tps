# Protocolo de Seguridad

## Entorno de trabajo

El proyecto utiliza PostgreSQL como motor de base de datos y DBeaver como cliente para administrar y ejecutar consultas.

Para este trabajo práctico se utiliza una base de datos de trabajo separada de la base original:

* Base original: `food_store_tp2`
* Base de trabajo: `food_store_tp2_copia`
* Carpeta de respaldos: `backups/`

Todas las pruebas y modificaciones del TP se realizan sobre `food_store_tp2_copia`.

## 1. Copia

Antes de realizar pruebas o modificaciones sobre la base, se trabaja sobre una copia de desarrollo y no sobre la base original.

La copia utilizada para este TP fue creada mediante PostgreSQL con:

```sql
CREATE DATABASE food_store_tp2_copia
WITH TEMPLATE food_store_tp2;
```

La base `food_store_tp2` se conserva como base original y `food_store_tp2_copia` se utiliza para realizar las pruebas del trabajo práctico.

## 2. Transacción

Toda operación que modifique datos se prueba primero dentro de una transacción.

Se utiliza la siguiente estructura:

```sql
BEGIN;

-- operación a probar

-- verificar el resultado

ROLLBACK;
```

El `ROLLBACK` permite comprobar el efecto de la operación sin confirmar los cambios.

Una vez verificado que el resultado es correcto, la operación puede ejecutarse nuevamente y confirmarse mediante:

```sql
BEGIN;

-- operación verificada

COMMIT;
```

No se confirma una modificación antes de haber revisado su efecto.

## 3. Respaldo

Antes de realizar cambios estructurales sobre la base de trabajo, como `ALTER TABLE`, `DROP` o migraciones, se genera un respaldo mediante `pg_dump`.

El respaldo se almacena en la carpeta `backups/` del proyecto.

Comando utilizado:

```powershell
pg_dump -Fc -d food_store_tp2_copia -f "backups\food_store_tp2_copia.backup"
```

El formato `-Fc` genera un archivo de respaldo en formato personalizado de PostgreSQL.

El respaldo se realiza antes de aplicar cambios estructurales para poder recuperar la base en caso de que una modificación produzca un resultado incorrecto.

## Aplicación del protocolo

El protocolo se aplica a todas las operaciones realizadas sobre la base durante el trabajo práctico:

1. Trabajar sobre `food_store_tp2_copia`.
2. Probar las operaciones de escritura dentro de una transacción.
3. Utilizar `ROLLBACK` durante la etapa de prueba.
4. Revisar el resultado antes de confirmar.
5. Generar un respaldo antes de cambios estructurales.
6. Confirmar mediante `COMMIT` solamente después de verificar que la operación es correcta.
