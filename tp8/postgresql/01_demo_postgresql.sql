-- PostgreSQL 16+: demo INDEPENDIENTE. No modifica tablas del Food Store original.
BEGIN;
CREATE SCHEMA IF NOT EXISTS tp8_demo;
CREATE TABLE IF NOT EXISTS tp8_demo.producto (
 id INTEGER PRIMARY KEY, nombre TEXT NOT NULL,
 precio NUMERIC(12,2) NOT NULL CHECK(precio>=0),
 stock INTEGER NOT NULL CHECK(stock>=0),
 disponible BOOLEAN NOT NULL DEFAULT true,
 eliminado BOOLEAN NOT NULL DEFAULT false
);
CREATE TABLE IF NOT EXISTS tp8_demo.pedido (
 id INTEGER PRIMARY KEY, descripcion TEXT NOT NULL
);
TRUNCATE tp8_demo.producto, tp8_demo.pedido;
INSERT INTO tp8_demo.producto VALUES
(1,'Muzzarella',1000.00,10,true,false),
(2,'Napolitana',1500.00,8,true,false),
(4,'Carne',350.00,9,true,false),
(7,'Coca 1.5L',800.00,15,true,false),
(8,'Agua mineral',400.00,20,true,false),
(9,'Flan casero',600.00,5,true,false);
INSERT INTO tp8_demo.pedido VALUES (101,'Pedido historico ficticio'),(102,'Pedido historico ficticio');
CREATE OR REPLACE VIEW tp8_demo.v_snapshot_movil AS
SELECT id,nombre,(precio*100)::BIGINT AS precio_centavos,stock,
       CASE WHEN disponible THEN 1 ELSE 0 END AS disponible,
       CASE WHEN eliminado THEN 1 ELSE 0 END AS eliminado,
       CURRENT_TIMESTAMP::DATE::TEXT AS fecha_copia
FROM tp8_demo.producto;
COMMIT;
-- psql: \copy (SELECT * FROM tp8_demo.v_snapshot_movil ORDER BY id) TO 'servidor_snapshot.csv' CSV HEADER
-- DBeaver: exportar SELECT * FROM tp8_demo.v_snapshot_movil ORDER BY id a CSV con cabecera.
