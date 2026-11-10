PRAGMA foreign_keys=ON;
-- La tabla snapshot_servidor ya debe contener la importacion CSV.
-- UPSERT mantiene lapidas, pero no toca borradores ni pedidos.
BEGIN IMMEDIATE;
INSERT INTO producto_cache(id,nombre,precio_centavos,stock_visto,disponible,eliminado,fecha_copia)
SELECT id,nombre,precio_centavos,stock,disponible,eliminado,fecha_copia FROM snapshot_servidor WHERE 1
ON CONFLICT(id) DO UPDATE SET nombre=excluded.nombre,precio_centavos=excluded.precio_centavos,
stock_visto=excluded.stock_visto,disponible=excluded.disponible,eliminado=excluded.eliminado,
fecha_copia=excluded.fecha_copia;
COMMIT;
-- Solo catalogo visible; borradores antiguos siguen referenciando lapidas.
SELECT id,nombre FROM producto_cache WHERE disponible=1 AND eliminado=0 ORDER BY id;
