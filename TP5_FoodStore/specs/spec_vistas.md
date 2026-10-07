# spec: vistas_reportes_food_store
Objetivo: Crear 3 vistas SQL para simplificar reportes y aplicar criterios de seguridad.

1. Vista: vw_productos_vigentes
   - Descripción: Muestra los productos activos/vigentes junto con el nombre de su categoría.
   - Columnas: producto_id, producto_nombre, precio, categoria_nombre.
   - Filtro: Solo productos donde activo = TRUE (o estado equivalente).

2. Vista: vw_pedidos_usuario (Seguridad)
   - Descripción: Asocia cada pedido con su usuario comprador.
   - Columnas: pedido_id, fecha_hora, total, usuario_id, usuario_nombre, email.
   - Criterio de seguridad: Excluir explícitamente la columna 'contrasena' de la tabla usuario.

3. Vista: vw_detalle_pedido_producto
   - Descripción: Muestra los renglones del detalle de pedidos con el nombre del producto vendido.
   - Columnas: detalle_id, pedido_id, producto_id, producto_nombre, cantidad, precio_unitario, subtotal.