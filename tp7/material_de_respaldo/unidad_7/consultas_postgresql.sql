-- b) Filtrar pedidos por estado CANCELADO
SELECT id, estado 
FROM pedido 
WHERE estado = 'CANCELADO';

-- c) Buscar pedidos que contengan el producto Carne
SELECT DISTINCT p.id, p.estado
FROM pedido p
JOIN detalle_pedido dp ON p.id = dp.pedido_id
JOIN producto pr ON dp.producto_id = pr.id
WHERE pr.nombre = 'Carne';