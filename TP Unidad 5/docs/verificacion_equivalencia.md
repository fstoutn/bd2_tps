# Parte D: verificación de equivalencia de `usuario_anon`

Base probada: `food_store_tp4`  
Motor: PostgreSQL 17.11

## Creación de la tabla

La consulta inicial `SELECT to_regclass('public.usuario_anon')` devolvió `NULL`
(celda vacía), confirmando que la tabla todavía no existía.

Se ejecutó `sql/usuario_anon.sql`. PostgreSQL informó:

```text
BEGIN
DO
SELECT 20005
ALTER TABLE
ALTER TABLE
COMMIT
```

La tabla anónima se creó con 20.005 filas.

## Resultados de las agregaciones

| rol | mes_alta | cantidad en `usuario` | cantidad en `usuario_anon` |
|---|---|---:|---:|
| CLIENTE | 2026-09-01 00:00:00-03 | 20004 | 20004 |
| ADMIN | 2026-09-01 00:00:00-03 | 1 | 1 |

La consulta final de diferencias devolvió `(0 rows)`.

## Conclusión

Los agregados por rol y mes de alta coinciden: las dos tablas tienen los mismos dos
grupos, los mismos conteos y 20.005 usuarios en total. La anonimización preservó la
información necesaria para esta agregación sin copiar los IDs, nombres ni emails reales.

## Datos que no deben compartirse con una IA

No deben enviarse nombres completos, emails reales, direcciones, identificadores
personales, credenciales, ni información sensible de clientes o pedidos. También se
deben excluir combinaciones de atributos que permitan identificar o reidentificar a
una persona, aunque cada atributo aislado parezca inocuo. Antes de compartir evidencia,
hay que anonimizarla dentro del entorno controlado, conservar solo los datos mínimos
necesarios para el análisis y comprobar que los reemplazos no permitan reconstruir la
identidad.
