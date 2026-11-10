# Design - base de tablet y simulación

## Límites y responsabilidad
PostgreSQL = fuente de verdad de productos, precios, stock, pedidos confirmados. MongoDB = documentos de lectura histórica de pedidos (Unidad 7), alimentados desde transacciones confirmadas. SQLite = catálogo cacheado, borradores y cola de solicitudes. La tablet no confirma ventas.

## Modelo SQLite (STRICT)
- `producto_cache(id PK, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia)`
- `pedido_borrador(id_local PK UUID, usuario, forma_pago, fecha)`
- `item_borrador(id_local FK, producto_id FK, cantidad CHECK > 0, precio_centavos_visto, PK compuesta)`
- `cola_sync(solicitud_uuid PK, id_local FK, estado CHECK, motivo)`
- `snapshot_servidor(...)`: instantánea CSV proveniente de PostgreSQL; conserva lápidas de baja lógica.

## Flujo
`v_snapshot_movil` -> CSV -> `snapshot_servidor` -> UPSERT `producto_cache` -> borrador en BEGIN/COMMIT -> `cola_sync` PENDIENTE -> semáforo local -> estado y motivo. Rojo prevalece sobre amarillo; verde solo indica plausibilidad, no venta. Si el cliente acepta un precio diferente, crea nuevo UUID para una nueva evaluación; la solicitud previa conserva su estado.

## Decisiones
Enteros en centavos para evitar errores de punto flotante; booleans normalizados como 0/1 para importar CSV sin t/f; claves foráneas habilitadas por conexión; protección idempotente local por UUID. En producción, idempotencia y transacción de stock se implementarían también en API/PostgreSQL.
