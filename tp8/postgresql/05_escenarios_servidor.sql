-- TP8 · Preparación MANUAL de instantáneas en PostgreSQL de pruebas.
-- Ejecutar cada bloque por separado y exportar nuevamente la vista.
-- No se deben confirmar pedidos ni descontar stock en PostgreSQL.
-- Restaurar valores iniciales antes de pasar al caso siguiente.

-- C2: antes de modificar, crear borrador SQLite de Muzzarella precio 100000.
-- UPDATE tp8_demo.producto SET precio=1100.00 WHERE id=1;
-- \copy (SELECT * FROM tp8_demo.v_snapshot_movil ORDER BY id) TO 'snapshot_c2.csv' CSV HEADER
-- Cargar nuevo CSV a snapshot_servidor en SQLite y ejecutar semaforo.sql.
-- UPDATE tp8_demo.producto SET precio=1000.00 WHERE id=1; -- restaurar

-- C3: antes de modificar, crear borrador SQLite de Napolitana por cantidad 9.
-- UPDATE tp8_demo.producto SET stock=8 WHERE id=2;
-- \copy (SELECT * FROM tp8_demo.v_snapshot_movil ORDER BY id) TO 'snapshot_c3.csv' CSV HEADER

-- C4: antes de modificar, crear borrador SQLite de Carne.
-- UPDATE tp8_demo.producto SET disponible=false,eliminado=true WHERE id=4;
-- \copy (SELECT * FROM tp8_demo.v_snapshot_movil ORDER BY id) TO 'snapshot_c4.csv' CSV HEADER
-- UPDATE tp8_demo.producto SET disponible=true,eliminado=false WHERE id=4; -- restaurar

-- C5: no cambiar datos; exportar la vista igual.
-- \copy (SELECT * FROM tp8_demo.v_snapshot_movil ORDER BY id) TO 'snapshot_c5.csv' CSV HEADER

-- C6: en SQLite reenviar exactamente el mismo solicitud_uuid. Debe dar error PK.
-- No hacer INSERT en PostgreSQL: el semaforo no confirma ventas.

-- Para registrar no mutacion: 04_control_no_mutacion.sql antes/despues.
-- El stock solo se modifica en una copia de PostgreSQL cuando se prepara un escenario,
-- NO como consecuencia de sincronizar desde SQLite.
