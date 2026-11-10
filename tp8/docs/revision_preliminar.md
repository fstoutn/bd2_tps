# Revisión preliminar y guía para review real en OpenCode Plan

**Alcance:** fuente TP7 adjunta, enunciado TP8, y nuevos scripts TP8. No hubo lectura exhaustiva de todos los scripts TP1-TP6 del repositorio (el servidor de archivos de GitHub no devolvió esos contenidos). Presentamos estos hallazgos a partir de nuestra revisión y pruebas locales; no los atribuimos a una ejecución de OpenCode.

| Unidad | Hallazgo | Decisión | Motivo y comprobación |
|---|---|---|---|
| U8 | Permitir cantidades cero en ítems de borrador dejaría solicitudes inválidas | Corregido | `CHECK(cantidad > 0)`; el intento en C7 arroja `CHECK constraint failed` y no aumenta filas. |
| U8 | Eliminar físicamente un producto cacheado al recibir baja lógica puede destruir referencias históricas | Corregido | Se preserva `producto_cache.eliminado=1`; en C4 la fila existe, pero la consulta del catálogo activo no la muestra. |
| U7 | Propuesta de eliminar los datos embebidos del cliente y líneas para normalizar MongoDB como tablas SQL | Descartado | El TP7 justifica el documento embebido para ticket/histórico: acceso de lectura conjunta y precios históricos. Se comprueba inspeccionando el documento `db.pedidos.findOne({_id:1})`; **esta consulta MongoDB de comprobación queda pendiente de ejecutar sobre una instancia real**. |
| U8 | Permitir a la tablet descontar stock ante `SIMULADO_APROBADO` | Descartado | Viola regla del enunciado. El semáforo solo escribe estado local; revisar script y control PostgreSQL antes/después en el servidor real (pendiente). |

La cátedra solicita **al menos tres hallazgos de dos unidades y uno descartado con fundamento**. Los proponemos como resultados preliminares; debemos contrastarlos con el **review real en OpenCode** y conservar las comprobaciones. La comprobación de U7 no fue ejecutada aquí.
