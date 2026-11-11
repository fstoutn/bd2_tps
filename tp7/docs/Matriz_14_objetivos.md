# Matriz de trazabilidad — TPI Food Store · Segunda entrega

Esta matriz indica el respaldo documental disponible para cada objetivo. **Un archivo de código o una especificación no demuestra por sí solo su ejecución.** Los informes previos son evidencia histórica aportada por el equipo.

| # | Objetivo | Archivo o respaldo | Alcance de la evidencia |
|---|---|---|---|
| 1 | Refactorización BCNF | Repositorio U4 `tp_fnbc_control_lote.sql` e informe U4 | Migración y comparación `EXCEPT` descritas en informe |
| 2 | Transacción reversible y Kiro | Script U4 e informe; `verificaciones/U4_plan_reversion.md` del paquete previo | Se documenta transacción; no se localizó spec Kiro U4 ni reversión integral comprobada |
| 3 | Desnormalización | U4 `tp_desnormalizacion_top_categorias.sql` | Vista materializada, tiempos y `REFRESH` documentados |
| 4 | Roles y permisos | U5 `sql/roles.sql`, especificaciones y verificación de roles | Roles de mínimo privilegio probados según informe |
| 5 | Auditoría de incidentes | U5 logs anonimizados e informe de incidente | Autenticaciones y escalamiento rechazado según informe |
| 6 | Auditoría asistida por IA | U5 `BITACORA.md`, respuesta OpenCode | Recomendación amplia descartada, corrección documentada |
| 7 | Mantenimiento automatizado | Informe U6; scripts y plan de operación aportados | Respaldo/restauración y `ANALYZE` documentados; programación automática no acreditada |
| 8 | Simulacro de desastre | Informe U6, pp. 1–4 | RTO 4:59,17; RPO ~12:29, verificación y análisis postincidente |
| 9 | Modelo documental | Informe U7 y `consultas_mongodb.js` | Cinco documentos y consultas documentadas |
| 10 | Comparación documental/relacional | Informe U7 y `consultas_postgresql.sql` | Comparación sobre los cinco IDs seleccionados |
| 11 | Base SQLite + specs | Repositorio `tp8/movil`, `tp8/docs/kiro` | Código y docs disponibles; ejecución de Kiro/OpenCode no acreditada |
| 12 | Semáforo y conflictos | Repositorio `tp8/movil`, `tp8/tests` e informe U8 | Casos SQLite comprobados; snapshot PostgreSQL original no acreditado |
| 13 | Code review integral IA | `docs/Revision_tecnica_transversal.md` y `tp8/docs/revision_preliminar.md` | Revisión estática documental, no equivale a sesión OpenCode Plan completa |
| 14 | Capa de datos integrada | Informe TPI, repositorio, README, DUIA y fuentes originales | Arquitectura consolidada; dependerá de la acreditación de pasos señalados |

## Referencia al repositorio

https://github.com/fstoutn/bd2_tps/tree/main

No se alteraron los scripts históricos del equipo. El ZIP original de GitHub está incluido en `material_de_respaldo/` para asegurar trazabilidad.
