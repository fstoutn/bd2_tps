PRAGMA foreign_keys = ON;
-- No escribe en PostgreSQL, ni descuenta stock, ni confirma ventas.
-- Orden de prioridad: RECHAZADO (rojo) > CONFLICTO (amarillo) > SIMULADO_APROBADO (verde).
BEGIN IMMEDIATE;
WITH evaluacion AS (
 SELECT c.solicitud_uuid,
        COUNT(i.producto_id) AS n_items,
        SUM(CASE WHEN s.id IS NULL OR s.disponible <> 1 OR s.eliminado <> 0
                      OR i.cantidad > COALESCE(s.stock, -1) THEN 1 ELSE 0 END) AS errores_rojos,
        SUM(CASE WHEN s.id IS NOT NULL AND i.precio_centavos_visto <> s.precio_centavos
                      THEN 1 ELSE 0 END) AS precios_distintos
 FROM cola_sync c
 LEFT JOIN item_borrador i ON i.id_local = c.id_local
 LEFT JOIN snapshot_servidor s ON s.id = i.producto_id
 WHERE c.estado = 'PENDIENTE'
 GROUP BY c.solicitud_uuid
)
UPDATE cola_sync
SET estado = CASE
    WHEN (SELECT n_items FROM evaluacion WHERE solicitud_uuid = cola_sync.solicitud_uuid) = 0
      OR (SELECT errores_rojos FROM evaluacion WHERE solicitud_uuid = cola_sync.solicitud_uuid) > 0 THEN 'RECHAZADO'
    WHEN (SELECT precios_distintos FROM evaluacion WHERE solicitud_uuid = cola_sync.solicitud_uuid) > 0 THEN 'CONFLICTO'
    ELSE 'SIMULADO_APROBADO' END,
 motivo = CASE
    WHEN (SELECT n_items FROM evaluacion WHERE solicitud_uuid = cola_sync.solicitud_uuid) = 0 THEN 'Borrador sin items'
    WHEN (SELECT errores_rojos FROM evaluacion WHERE solicitud_uuid = cola_sync.solicitud_uuid) > 0 THEN 'Producto inexistente, no disponible, dado de baja o sin stock'
    WHEN (SELECT precios_distintos FROM evaluacion WHERE solicitud_uuid = cola_sync.solicitud_uuid) > 0 THEN 'Precio cambiado: requiere aceptacion y nueva solicitud UUID'
    ELSE 'Coinciden catalogo, precios y stock; NO es una venta' END
WHERE estado = 'PENDIENTE';
COMMIT;
SELECT solicitud_uuid, estado, motivo FROM cola_sync ORDER BY solicitud_uuid;
