# Ejercicio de Lectura Crítica

## Script 1 — Desactivar funciones

### Script original

```sql
UPDATE funcion
SET activa = FALSE;

¿Qué hace este script?

El script modifica todas las filas de la tabla funcion y establece el campo activa en FALSE.

Como no posee una cláusula WHERE, afecta a todas las funciones existentes en la tabla.

¿Por qué puede ser peligroso?

El problema principal es que la consulta no especifica qué función o conjunto de funciones se desea modificar.

Al ejecutarla, todas las funciones quedan desactivadas, incluso aquellas que deberían continuar activas.

Esto puede producir una modificación masiva accidental de los datos.

¿Cómo podría corregirse?

Si se desea desactivar una función específica, se debe utilizar una condición que identifique el registro:

UPDATE funcion
SET activa = FALSE
WHERE id = 1;

También podría utilizarse otra condición más específica según la necesidad del sistema.

Por ejemplo:

UPDATE funcion
SET activa = FALSE
WHERE nombre = 'Registrar pedido';

La condición debe ser suficientemente específica para evitar modificar registros que no correspondan.

Conclusión

El script original es peligroso porque realiza una actualización masiva sin ningún filtro.

La corrección consiste en agregar una cláusula WHERE que determine exactamente qué registros deben modificarse.

Script 2 — Eliminar categorías
Script original
DELETE FROM categoria
WHERE id NOT IN (
    SELECT categoria_id
    FROM producto
);
¿Qué hace este script?

El script elimina todas las categorías cuyo id no aparece entre los categoria_id registrados en la tabla producto.

En otras palabras, intenta eliminar las categorías que actualmente no tienen productos asociados.

¿Por qué puede ser peligroso?

El principal problema es que se trata de una operación DELETE masiva.

Si la consulta se ejecuta sin verificar previamente qué registros serán eliminados, puede provocar la eliminación de varias categorías de manera permanente.

Además, el uso de NOT IN puede presentar problemas cuando la subconsulta devuelve valores NULL, ya que la lógica de comparación de SQL con NULL puede producir resultados inesperados.

También debe tenerse en cuenta la integridad referencial definida en la base de datos. Si existen otras tablas relacionadas con categoria, el DELETE puede ser rechazado por una clave foránea o, dependiendo de la configuración, producir eliminaciones relacionadas.

¿Cómo podría corregirse?

Una alternativa más segura es utilizar NOT EXISTS:

DELETE FROM categoria AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM producto AS p
    WHERE p.categoria_id = c.id
);

Esta versión expresa explícitamente que se deben eliminar las categorías para las cuales no existe ningún producto asociado.

Antes de ejecutar un DELETE de este tipo, también es recomendable verificar primero qué registros serían afectados utilizando un SELECT:

SELECT c.*
FROM categoria AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM producto AS p
    WHERE p.categoria_id = c.id
);

De esta manera se pueden revisar las categorías que serían eliminadas antes de ejecutar la operación definitiva.

Conclusión

El script original puede eliminar múltiples categorías de forma permanente.

La versión con NOT EXISTS resulta más clara para expresar la ausencia de registros relacionados y permite realizar previamente un SELECT para verificar los registros afectados.

En operaciones DELETE masivas se recomienda comprobar primero el conjunto de registros mediante un SELECT y ejecutar la eliminación solamente después de verificar que el resultado es correcto.

Conclusión general

Los dos ejercicios muestran un problema común en las operaciones de modificación de datos: ejecutar UPDATE o DELETE sin verificar correctamente el conjunto de registros que será afectado.

Para evitar modificaciones accidentales se recomienda:

Utilizar WHERE en las operaciones UPDATE y DELETE.
Verificar previamente los registros afectados mediante un SELECT.
Utilizar condiciones suficientemente específicas.
Tener en cuenta las restricciones de integridad referencial.
Utilizar NOT EXISTS cuando sea apropiado para comprobar la ausencia de registros relacionados.
Evitar operaciones masivas sin una revisión previa.