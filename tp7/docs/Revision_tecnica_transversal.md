# Revisión transversal estática de scripts U4–U8

**Alcance real:** inspección de archivos originales entregados, efectuada para preparar este integrador. **No equivale** a una ejecución del agente Plan de OpenCode sobre toda la cursada. Los hallazgos siguientes son reproducibles por inspección; las validaciones de PostgreSQL sugeridas no se ejecutaron aquí.

| Unidad | Hallazgo comprobable | Decisión del equipo propuesta | Fundamento y validación |
|---|---|---|---|
| U4 | `tp_fnbc_control_lote.sql` ejecuta `COMMIT` antes de comparar ambas diferencias `EXCEPT`. | **Corregir** para futuras migraciones. | Para reversión transaccional ante resultado distinto de cero, los controles deben ocurrir antes de `COMMIT`. Revisión textual y plan en `verificaciones/U4_plan_reversion.md`. |
| U4 | La auditoría de materializada hace `FULL OUTER JOIN`, pero `WHERE mv.fecha = CURRENT_DATE` puede filtrar filas que solo existen en el origen. | **Corregir** comprobación. | Se incluye `verificaciones/U4_auditoria_materializada_corregida.sql`; requiere ejecutar contra copia PostgreSQL. |
| U5 | Recomendación previa de `ALTER DEFAULT PRIVILEGES` con permisos automáticos para tablas futuras. | **Descartada** (decisión histórica registrada). | El equipo anuló concesiones automáticas tras revisar `\ddp`, conforme a `TP Unidad 5/BITACORA.md`. |
| U7 | Propuesta de convertir `lineas` embebidas de MongoDB en tablas SQL. | **Descartar** como regla general. | El acceso a ticket/historial justifica documentos con líneas embebidas; histórico no es fuente de verdad del stock. No hay benchmark que demuestre superioridad global de MongoDB. |
| U8 | `SIMULADO_APROBADO` debe permanecer como simulación y no vender ni descontar stock. | **Conservar**. | `tp8/movil/semaforo.sql` solo actualiza SQLite; validación en PostgreSQL real pendiente. |

El equipo debe contrastar cada decisión, ejecutar las pruebas faltantes en copia y completar la evidencia de revisión OpenCode requerida por la cátedra.
