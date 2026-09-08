# Spec de restricciones de integridad

## Regla 1 — Transición de estado del pedido

En la tabla `pedido`, el estado de un pedido no debe poder retroceder una vez que avanzó a un estado posterior. Un pedido en estado `ENTREGADO` o `CANCELADO` no debe poder volver a `PENDIENTE` ni pasar a otro estado.

## Regla 2 — Subtotal del detalle

En la tabla `detalle_pedido`, la columna `subtotal` debe ser siempre igual al resultado de multiplicar `cantidad` por `precio_unitario`.

## Regla 3 — Precio de productos activos

En la tabla `producto`, todo producto cuyo valor de `activo` sea `TRUE` debe tener un `precio_lista` estrictamente mayor que cero.
