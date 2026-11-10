-- Ejecutar CADA INSERT por separado en una copia o en sqlite3 interactivo.
-- Ambos DEBEN fallar, no son parte del flujo feliz.
PRAGMA foreign_keys = ON;
-- C7a: CHECK constraint failed: cantidad > 0
INSERT INTO item_borrador VALUES('00000000-0000-4000-8000-000000000001',2,0,150000);
-- C7b: FOREIGN KEY constraint failed: producto inexistente
INSERT INTO item_borrador VALUES('00000000-0000-4000-8000-000000000001',999999,1,1000);
-- Evidencia a consultar luego de intentar ambas inserciones:
SELECT COUNT(*) AS filas_invalidas FROM item_borrador WHERE producto_id IN (2,999999);
