-- ANTES Y DESPUES de los casos de SQLite, ejecutar y comparar ambas cifras.
SELECT COUNT(*) AS pedidos_en_servidor FROM tp8_demo.pedido;
SELECT id,stock,precio,eliminado FROM tp8_demo.producto ORDER BY id;
SELECT SUM(stock) AS stock_total_en_servidor FROM tp8_demo.producto;
-- Para la base real, adaptar schema/tabla con 02_inspeccionar_original.sql.
-- Modificar precio/stock/baja en PostgreSQL SOLO para preparar escenarios en una COPIA.
