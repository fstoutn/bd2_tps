PRAGMA foreign_keys = ON;
-- TP8: ejecutar sobre base nueva SQLite 3.37+.
CREATE TABLE IF NOT EXISTS producto_cache (
 id INTEGER PRIMARY KEY,
 nombre TEXT NOT NULL CHECK(length(trim(nombre)) > 0),
 precio_centavos INTEGER NOT NULL CHECK(precio_centavos >= 0),
 stock_visto INTEGER NOT NULL CHECK(stock_visto >= 0),
 disponible INTEGER NOT NULL CHECK(disponible IN (0,1)),
 eliminado INTEGER NOT NULL DEFAULT 0 CHECK(eliminado IN (0,1)),
 fecha_copia TEXT NOT NULL
) STRICT;
CREATE TABLE IF NOT EXISTS pedido_borrador (
 id_local TEXT PRIMARY KEY CHECK(length(id_local) = 36),
 usuario TEXT NOT NULL CHECK(length(trim(usuario)) > 0),
 forma_pago TEXT NOT NULL CHECK(forma_pago IN ('EFECTIVO','TARJETA','TRANSFERENCIA')),
 fecha TEXT NOT NULL
) STRICT;
CREATE TABLE IF NOT EXISTS item_borrador (
 id_local TEXT NOT NULL,
 producto_id INTEGER NOT NULL,
 cantidad INTEGER NOT NULL CHECK(cantidad > 0),
 precio_centavos_visto INTEGER NOT NULL CHECK(precio_centavos_visto >= 0),
 PRIMARY KEY(id_local, producto_id),
 FOREIGN KEY(id_local) REFERENCES pedido_borrador(id_local) ON DELETE CASCADE,
 FOREIGN KEY(producto_id) REFERENCES producto_cache(id)
) STRICT;
CREATE TABLE IF NOT EXISTS cola_sync (
 solicitud_uuid TEXT PRIMARY KEY CHECK(length(solicitud_uuid) = 36),
 id_local TEXT NOT NULL,
 estado TEXT NOT NULL DEFAULT 'PENDIENTE' CHECK(estado IN ('PENDIENTE','CONFLICTO','RECHAZADO','SIMULADO_APROBADO')),
 motivo TEXT NOT NULL DEFAULT '',
 FOREIGN KEY(id_local) REFERENCES pedido_borrador(id_local)
) STRICT;
-- Instantánea del servidor. Banderas normalizadas 0/1 y baja lógica conservada.
CREATE TABLE IF NOT EXISTS snapshot_servidor (
 id INTEGER PRIMARY KEY,
 nombre TEXT NOT NULL,
 precio_centavos INTEGER NOT NULL CHECK(precio_centavos >= 0),
 stock INTEGER NOT NULL CHECK(stock >= 0),
 disponible INTEGER NOT NULL CHECK(disponible IN (0,1)),
 eliminado INTEGER NOT NULL CHECK(eliminado IN (0,1)),
 fecha_copia TEXT NOT NULL
) STRICT;
CREATE INDEX IF NOT EXISTS ix_cola_estado ON cola_sync(estado);
CREATE INDEX IF NOT EXISTS ix_item_producto ON item_borrador(producto_id);
