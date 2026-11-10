# TP8 Food Store - Requirements (EARS)

Preparamos esta especificación para cargarla en Kiro y utilizarla antes de regenerar o modificar código. Construimos y probamos los scripts localmente; **todavía no ejecutamos la spec dentro de Kiro**.

- **REQ-01**: WHEN una solicitud PENDIENTE contenga un ítem cuyo precio visto difiere del precio en `snapshot_servidor`, y no exista una causa roja, THE SYSTEM SHALL marcar la solicitud como `CONFLICTO` sin confirmar la venta. **Prueba:** C2.
- **REQ-02**: WHEN una solicitud PENDIENTE contenga un producto inexistente, no disponible, eliminado o con cantidad mayor al stock actualizado, THE SYSTEM SHALL marcarla `RECHAZADO`, priorizando este resultado por sobre diferencias de precio. **Pruebas:** C3 y C4.
- **REQ-03**: WHEN una solicitud PENDIENTE tenga ítems válidos, precios sin cambios y stock suficiente, THE SYSTEM SHALL marcarla `SIMULADO_APROBADO` sin modificar el servidor. **Prueba:** C5.
- **REQ-04**: WHEN una solicitud ya procesada se evalúe nuevamente o se intente reinsertar su UUID, THE SYSTEM SHALL mantener el estado anterior y rechazar el UUID duplicado. **Prueba:** C6.

Requisitos complementarios comprobados: caché offline C1; claves foráneas, cantidad positiva y ROLLBACK C7/1.c.
