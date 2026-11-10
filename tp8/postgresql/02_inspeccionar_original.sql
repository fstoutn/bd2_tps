-- Ejecutar en el PostgreSQL de PRUEBAS original para adaptar la vista, sin escrituras.
SELECT table_schema,table_name,column_name,data_type
FROM information_schema.columns
WHERE table_name IN ('producto','pedido','detalle_pedido','usuario')
ORDER BY table_schema,table_name,ordinal_position;
SELECT table_schema, table_name FROM information_schema.tables
WHERE table_name IN ('producto','pedido','detalle_pedido','usuario');
-- Comprobar nombres/tipos reales de precio, stock, disponible y baja logica antes de adaptar.
