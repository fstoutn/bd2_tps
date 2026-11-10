PRAGMA foreign_keys = ON;
-- Precondicion: cargar servidor_snapshot.csv y refrescar producto_cache
-- (ver movil/cargar_snapshot.sql). Se ejecuta una sola vez sobre base limpia.
BEGIN TRANSACTION;
INSERT INTO pedido_borrador VALUES ('00000000-0000-4000-8000-000000000001','usuario_ficticio_01','EFECTIVO','2026-11-10T10:00:00');
INSERT INTO item_borrador VALUES ('00000000-0000-4000-8000-000000000001',1,2,100000);
INSERT INTO cola_sync VALUES ('10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001','PENDIENTE','');
COMMIT;
SELECT 'TRANSACCION_CONFIRMADA' AS prueba, COUNT(*) AS filas FROM cola_sync;
BEGIN TRANSACTION;
INSERT INTO pedido_borrador VALUES ('00000000-0000-4000-8000-000000000099','usuario_ficticio_99','TARJETA','2026-11-10T10:01:00');
ROLLBACK;
SELECT 'ROLLBACK_NO_DEJA_FILA' AS prueba, COUNT(*) AS filas FROM pedido_borrador WHERE id_local='00000000-0000-4000-8000-000000000099';
-- C1: catalogo local sin conexion al servidor
SELECT id,nombre,precio_centavos,stock_visto FROM producto_cache
WHERE disponible=1 AND eliminado=0 ORDER BY id;
-- C7: ejecucion separada en pruebas_errores_esperados.sql y tests/verificar.py;
-- deben generar CHECK constraint failed y FOREIGN KEY constraint failed.
