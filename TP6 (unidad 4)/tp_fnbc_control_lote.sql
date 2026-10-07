-- ============================================================================
-- TRABAJO PRÁCTICO N° 4 - PARTE 1: FNBC (Ajustado para IDs de usuario)
-- Archivo: tp_fnbc_control_lote.sql
-- ============================================================================

-- Cancela cualquier bloque de transacción bloqueado anteriormente
ROLLBACK;

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. TABLAS AUXILIARES MAESTRAS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lote (
    id BIGINT PRIMARY KEY,
    descripcion VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS deposito (
    id BIGINT PRIMARY KEY,
    nombre VARCHAR(100)
);

-- Carga inicial de maestras auxiliares
INSERT INTO lote (id, descripcion) VALUES 
(501, 'Lote Muzzarella'), (502, 'Lote Tomate'), (503, 'Lote Harina')
ON CONFLICT (id) DO NOTHING;

INSERT INTO deposito (id, nombre) VALUES 
(30, 'Depósito Central'), (31, 'Depósito Norte')
ON CONFLICT (id) DO NOTHING;

-- Carga de usuarios permitiendo forzar los ID 801 y 802
INSERT INTO usuario (id, nombre, email) 
OVERRIDING SYSTEM VALUE 
VALUES 
(801, 'Carlos Perez', 'carlos@foodstore.com'),
(802, 'Ana Gomez', 'ana@foodstore.com')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. ESQUEMA ORIGINAL CON VIOLACIÓN DE FNBC
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS control_lote_almacen CASCADE;

CREATE TABLE control_lote_almacen (
    lote_id BIGINT NOT NULL REFERENCES lote(id),
    deposito_id BIGINT NOT NULL REFERENCES deposito(id),
    responsable_control_id BIGINT NOT NULL REFERENCES usuario(id),
    PRIMARY KEY (lote_id, deposito_id)
);

INSERT INTO control_lote_almacen (lote_id, deposito_id, responsable_control_id) VALUES
(501, 30, 801),
(502, 30, 801),
(503, 31, 802);

-- ----------------------------------------------------------------------------
-- 3. DESCOMPOSICIÓN SIN PÉRDIDA (ALGORITMO FNBC)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS control_lote CASCADE;
DROP TABLE IF EXISTS responsable_deposito CASCADE;

-- Tabla 1: Captura la DF responsable_control_id -> deposito_id
CREATE TABLE responsable_deposito (
    responsable_control_id BIGINT PRIMARY KEY REFERENCES usuario(id),
    deposito_id BIGINT NOT NULL REFERENCES deposito(id)
);

-- Tabla 2: Captura la relación entre el lote y su responsable
CREATE TABLE control_lote (
    lote_id BIGINT NOT NULL REFERENCES lote(id),
    responsable_control_id BIGINT NOT NULL REFERENCES responsable_deposito(responsable_control_id),
    PRIMARY KEY (lote_id, responsable_control_id)
);

-- ----------------------------------------------------------------------------
-- 4. MIGRACIÓN DE DATOS
-- ----------------------------------------------------------------------------
INSERT INTO responsable_deposito (responsable_control_id, deposito_id)
SELECT DISTINCT responsable_control_id, deposito_id
FROM control_lote_almacen;

INSERT INTO control_lote (lote_id, responsable_control_id)
SELECT lote_id, responsable_control_id
FROM control_lote_almacen;

-- ----------------------------------------------------------------------------
-- 5. VISTA DE COMPATIBILIDAD (REUNIÓN NATURAL)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_control_lote_almacen AS
SELECT 
    cl.lote_id,
    rd.deposito_id,
    cl.responsable_control_id
FROM control_lote cl
JOIN responsable_deposito rd ON cl.responsable_control_id = rd.responsable_control_id;

COMMIT;

-- ----------------------------------------------------------------------------
-- 6. VERIFICACIÓN DE EQUIVALENCIA Y REUNIÓN SIN PÉRDIDA
-- ----------------------------------------------------------------------------
-- Ambas consultas EXCEPT deben devolver 0 filas para demostrar equivalencia total.
SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen
EXCEPT
SELECT lote_id, deposito_id, responsable_control_id FROM vw_control_lote_almacen;

SELECT lote_id, deposito_id, responsable_control_id FROM vw_control_lote_almacen
EXCEPT
SELECT lote_id, deposito_id, responsable_control_id FROM control_lote_almacen;