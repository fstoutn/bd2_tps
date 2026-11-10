# Bitácora de IA — TP8 Food Store

**Equipo:** Ponce De Leon Leonel, Storani Franco, Pinto Guillermo, Soto Matias.
**Herramienta utilizada por el equipo para preparar esta entrega:** ChatGPT (GPT-6), 10/11/2026. **Todavía no ejecutamos la spec en Kiro ni la revisión en OpenCode.**

| Entrada | Solicitud a la IA | Propuesta aceptada / comprobación | Propuesta descartada y motivo |
|---|---|---|---|
| 1 | Diseñar cache y borradores SQLite con integridad | Tablas STRICT, FK, PK, CHECK y centavos. Verificado con SQLite 3.46.1 y C7. | Usar REAL para precios: introduce riesgos de representación decimal. |
| 2 | Diseñar semáforo e idempotencia local | Prioridad RECHAZADO antes que CONFLICTO; solo PENDIENTE. Verificado con C2-C6. | Modificar stock en SQLite para autorizar ventas: el servidor es la autoridad. |
| 3 | Revisar casos límite y borrado lógico | Conservar lápida y ocultarla del catálogo; probado C4. | Borrar físicamente `producto_cache`: rompe FK del borrador anterior. |
| 4 | Preparar guía de integración de PostgreSQL | Demo aislada en `tp8_demo` y script de introspección. | Afirmar que se exportó el PostgreSQL original: no hay conexión al servidor real. |

## Actividad requerida pendiente de las herramientas docentes
El enunciado exige una spec en **Kiro ANTES de generar código** y un **code review con OpenCode en agente Plan** de *todos los scripts de la cursada*. Adjuntamos la especificación y una revisión preliminar; **todavía debemos ejecutar esas actividades en las herramientas indicadas**, guardar el registro real y actualizar nuestra bitácora.

Prompt sugerido para OpenCode Plan: "Revisá los scripts de los TP1-TP7 y TP8 de Food Store. Sin modificar archivos, reportá vulnerabilidades, claves e integridad, posibles alteraciones de stock en tablet, tipos de precios, borrado lógico y riesgos de migración PostgreSQL/MongoDB/SQLite. Para cada hallazgo indicá archivo, línea, severidad, corrección y prueba SQL sugerida. No inventes hallazgos si no tenés acceso al archivo.".
