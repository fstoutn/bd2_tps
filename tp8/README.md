# Food Store — TP8 Base de Datos II · UTN (2026)

**Integrantes:** Ponce De Leon Leonel · Storani Franco · Pinto Guillermo · Soto Matias.

**Objetivo del equipo:** diseñamos una tablet que opera offline con SQLite, prepara borradores y simula la resolución por semáforo frente a una instantánea PostgreSQL. Definimos PostgreSQL como autoridad sobre ventas/stock/precio; MongoDB conserva documentos de lectura histórica (TP7). `SIMULADO_APROBADO` **no crea una venta**.

## Contenido

- `movil/schema_sqlite.sql`: cuatro tablas STRICT de consigna + `snapshot_servidor`, restricciones e índices.
- `movil/servidor_snapshot.csv`: **CSV demostrativo del equipo** compatible con `postgresql/01_demo_postgresql.sql`. No corresponde a una exportación comprobada de nuestro PostgreSQL original.
- `movil/cargar_snapshot.sql`: UPSERT desde `snapshot_servidor` a `producto_cache`, preservando lápidas.
- `movil/pruebas_sqlite.sql`: transacciones, COMMIT, ROLLBACK y consulta offline C1.
- `movil/pruebas_errores_esperados.sql`: dos sentencias C7 **diseñadas para fallar**, ejecutar cada una por separado.
- `movil/semaforo.sql`: actualización SOLO de `cola_sync` en SQLite de PENDIENTE a rojo/amarillo/verde.
- `movil/foodstore_movil.db`: base generada por la batería de pruebas y con resultados de todos los casos.
- `postgresql/01_demo_postgresql.sql`: **copia demo independiente** con vista `tp8_demo.v_snapshot_movil`.
- `postgresql/02_inspeccionar_original.sql`: identificar columnas reales en PostgreSQL del proyecto.
- `postgresql/03_integracion_original_plantilla.sql`: guía comentada a adaptar a la base original.
- `postgresql/04_control_no_mutacion.sql`: comprobación de stock y cantidad de pedidos.
- `tests/verificar.py`: automatiza casos C1-C7 con Python estándar (se usa solo para pruebas; la solución es SQL).
- `tests/resultados_verificados.json` y `tests/salida_pruebas.txt`: resultados obtenidos en nuestra batería de pruebas con SQLite 3.46.1.
- `docs/informe.pdf`: informe de consignas 1.a, 2.c, 3.a, 3.b y 3.c (máximo seis páginas).
- `docs/kiro/`: spec EARS, diseño y tareas; `docs/bitacora_ia.md` y `docs/DUIA.md`.

## Requisitos
PostgreSQL 16+ para demo del servidor, SQLite 3.37+ (consola `sqlite3` o DB Browser for SQLite) y opcional Python 3.10+ para automatizar pruebas. En Windows usar `py tests/verificar.py` si no existe `python`.

## Desde cero: camino reproducible A (sin PostgreSQL, con CSV demo)

1. Abrir terminal en la carpeta `food-store/`.
2. **Más fácil:** ejecutar `python tests/verificar.py` (recrea **SOLO** `movil/foodstore_movil.db`, borrando su versión anterior; no ejecutarlo en una DB que quieran conservar). Ejecuta esquema, carga de CSV, casos y verificaciones. Mirar salida y JSON.
3. Para ver los resultados: abrir `movil/foodstore_movil.db` en DB Browser; consultar `SELECT solicitud_uuid,estado,motivo FROM cola_sync ORDER BY solicitud_uuid;`.
4. Para probar manualmente C7, ejecutar cada INSERT de `movil/pruebas_errores_esperados.sql` por separado: ambos deben dar error; no deben aparecer filas nuevas.

## Desde cero: camino reproducible B (SQL manual)

En terminal (desde `food-store/`; instalar `sqlite3` si falta):

```bash
sqlite3 movil/foodstore_movil_manual.db < movil/schema_sqlite.sql
sqlite3 -cmd '.mode csv' movil/foodstore_movil_manual.db ".import --skip 1 movil/servidor_snapshot.csv snapshot_servidor"
sqlite3 movil/foodstore_movil_manual.db < movil/cargar_snapshot.sql
sqlite3 movil/foodstore_movil_manual.db < movil/pruebas_sqlite.sql
sqlite3 movil/foodstore_movil_manual.db < movil/semaforo.sql
```

Nota: `sqlite3` puede interpretar de forma distinta `.import` según versión. En DB Browser usar **Importar CSV** a tabla existente `snapshot_servidor`, respetando columnas y cabecera, y activar FK para la conexión. No correr pruebas_sqlite.sql dos veces sobre la misma base por las PK.

## Desde cero: camino reproducible C (PostgreSQL de pruebas + exportación)

1. En una base **de pruebas**, ejecutar `postgresql/01_demo_postgresql.sql` con psql o DBeaver. Crea objetos únicamente en schema `tp8_demo`.
2. Exportar vista, por consola psql: `\copy (SELECT * FROM tp8_demo.v_snapshot_movil ORDER BY id) TO 'servidor_snapshot.csv' CSV HEADER`.
3. Abrir SQLite limpio, crear tablas, importar CSV a `snapshot_servidor` como en B, ejecutar `cargar_snapshot.sql`, `pruebas_sqlite.sql` y `semaforo.sql`.
4. Para usar el PostgreSQL del proyecto original, **primero** ejecutar `postgresql/02_inspeccionar_original.sql` y adaptar la vista de `03_integracion_original_plantilla.sql` según columnas reales. **No modificar la base de producción.**

## Cómo se reproducen C2-C6

`tests/verificar.py` implementa la secuencia completa y verifica los resultados con `assert`:
- **C2:** crear borrador de Muzzarella a 100000; actualizar `snapshot_servidor.precio_centavos` a 110000; ejecutar semáforo => CONFLICTO; cliente acepta precio en ítem y genera nueva `solicitud_uuid` => SIMULADO_APROBADO.
- **C3:** crear borrador de 9 Napolitanas con stock 8 => RECHAZADO.
- **C4:** crear borrador de Carne; marcar `disponible=0, eliminado=1` en snapshot, refrescar caché => RECHAZADO; la lápida sigue pero no aparece en catálogo.
- **C5:** crear borrador de Coca 1.5L sin cambios => SIMULADO_APROBADO.
- **C6:** repetir INSERT de la misma `solicitud_uuid` => UNIQUE constraint failed; correr semáforo otra vez, sin reevaluación.

En nuestra demostración modificamos la instantánea **SQLite** para representar sucesivas exportaciones del servidor; no realizamos esas exportaciones desde PostgreSQL. Para evidencia física de cada exportación con PostgreSQL real, preparar cada escenario en **copia** del servidor y exportar nuevamente. **Queda pendiente contrastar el flujo con nuestro PostgreSQL original.**

## Respaldo / control final

En PostgreSQL (copia): usar `pg_dump` y restaurar con `pg_restore` a una base temporal; validar tablas, filas y FK. En SQLite conservar copias de la BD si hay borradores sin sincronizar. Después de restaurar un backup viejo, las tablets bloquean sincronización hasta comparar versión/corte de datos y volver a descargar catálogo; pueden aparecer solicitudes sin confirmar que necesitan reconciliación.

**Control requerido sin mutaciones:** ejecutar `postgresql/04_control_no_mutacion.sql` **antes y después** de la simulación y comparar resultados. La demo declarada parte de 2 pedidos y stock total 67. No ejecutamos una instancia PostgreSQL original en esta preparación.

### Preparación manual de snapshots por caso en PostgreSQL

`postgresql/05_escenarios_servidor.sql` incluye bloques comentados para C2, C3, C4, C5 y C6. Ejecutarlos de a uno en una copia de prueba, exportar CSV específico y cargarlo a SQLite. Incluimos el script como guía de reproducción; todavía no lo ejecutamos en nuestra instancia PostgreSQL.
