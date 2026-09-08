# Declaración de Uso de IA — Parte 1

## Herramienta

OpenCode — modelo/proveedor configurado en OpenCode.

## Spec o prompt utilizado

Se solicitó a OpenCode generar restricciones de integridad para tres reglas de negocio del proyecto Food Store:

1. Validar las transiciones permitidas del estado de un pedido.
2. Garantizar que el subtotal de un detalle de pedido sea igual a la cantidad multiplicada por el precio unitario.
3. Garantizar que un producto activo tenga un precio mayor que cero.

Se indicó utilizar OpenCode primero en modo Plan, revisar la propuesta y posteriormente implementarla.

## Qué generó

OpenCode propuso modificaciones sobre el archivo `schema`:

- Una función y un trigger para validar las transiciones del estado de `pedido`.
- Una restricción CHECK para validar el subtotal de `detalle_pedido`.
- Una restricción CHECK para validar el precio de los productos activos.

También propuso un archivo `test_restricciones.sql` con datos de prueba y casos válidos e inválidos.

## Qué se aceptó

Se aceptaron las tres reglas de negocio y los mecanismos propuestos:

- Trigger BEFORE UPDATE para controlar las transiciones de estado.
- CHECK para validar el subtotal.
- CHECK para validar el precio de los productos activos.

Las modificaciones fueron revisadas mediante `git diff` antes de aplicarse sobre la base.

## Qué se modificó o descartó, y por qué

El plan inicial de OpenCode proponía algunos UPDATE de prueba que podían afectar múltiples filas.

Se decidió utilizar registros específicos de prueba para evitar depender de datos existentes o modificar múltiples registros.

Además, debido a que OpenCode alcanzó el límite de uso antes de finalizar la generación del archivo de pruebas, `test_restricciones.sql` fue completado manualmente siguiendo el plan previamente revisado.

## Verificación realizada

Primero se realizó un backup de la base de trabajo `food_store_tp2_copia`.

Luego las modificaciones estructurales se probaron dentro de una transacción utilizando:

BEGIN;
...
ROLLBACK;

Se verificó posteriormente que las restricciones y el trigger no permanecieran después del ROLLBACK.

Luego se aplicaron definitivamente utilizando:

BEGIN;
...
COMMIT;

Se verificó la existencia de:

- `chk_producto_activo_precio`
- `chk_detalle_subtotal_calculado`
- `trg_validar_estado_pedido`

Finalmente se ejecutó `test_restricciones.sql` dentro de una transacción con ROLLBACK.

Las pruebas inválidas fueron rechazadas correctamente:

- Transición de ENTREGADO a PENDIENTE.
- Transición de ENTREGADO a EN_PREPARACION.
- Subtotal incorrecto.
- Producto activo con precio cero.
- Producto activo con precio negativo.

También se verificó que los datos de prueba fueran eliminados después del ROLLBACK, obteniendo 0 registros para los datos temporales.