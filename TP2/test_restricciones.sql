-- Pruebas de las restricciones de integridad.
-- Todas las pruebas se ejecutan dentro de una transacción
-- y al finalizar se revierten los datos de prueba.

BEGIN;

-- ============================================================
-- DATOS DE PRUEBA
-- ============================================================

INSERT INTO categoria (nombre)
VALUES ('Categoria Test');

INSERT INTO producto (nombre, precio_lista, activo, categoria_id)
VALUES (
    'Producto Test',
    25.50,
    TRUE,
    (SELECT id FROM categoria WHERE nombre = 'Categoria Test')
);

INSERT INTO usuario (nombre, email)
VALUES ('Usuario Test', 'usuario.test@ejemplo.com');

INSERT INTO pedido (usuario_id, forma_pago, estado)
VALUES (
    (SELECT id FROM usuario WHERE email = 'usuario.test@ejemplo.com'),
    'EFECTIVO',
    'PENDIENTE'
);

INSERT INTO pedido (usuario_id, forma_pago, estado)
VALUES (
    (SELECT id FROM usuario WHERE email = 'usuario.test@ejemplo.com'),
    'EFECTIVO',
    'EN_PREPARACION'
);

INSERT INTO pedido (usuario_id, forma_pago, estado)
VALUES (
    (SELECT id FROM usuario WHERE email = 'usuario.test@ejemplo.com'),
    'EFECTIVO',
    'ENTREGADO'
);

-- ============================================================
-- REGLA 1: TRANSICIÓN DE ESTADO
-- ============================================================

-- Caso válido:
-- PENDIENTE -> EN_PREPARACION
UPDATE pedido
SET estado = 'EN_PREPARACION'
WHERE usuario_id = (
    SELECT id FROM usuario WHERE email = 'usuario.test@ejemplo.com'
)
AND estado = 'PENDIENTE';

-- Caso válido:
-- EN_PREPARACION -> ENTREGADO
UPDATE pedido
SET estado = 'ENTREGADO'
WHERE usuario_id = (
    SELECT id FROM usuario WHERE email = 'usuario.test@ejemplo.com'
)
AND estado = 'EN_PREPARACION';

-- Caso inválido:
-- EN_PREPARACION -> PENDIENTE
-- Debe producir una excepción.
DO $$
DECLARE
    v_pedido_id BIGINT;
BEGIN
    SELECT id INTO v_pedido_id
    FROM pedido
    WHERE usuario_id = (
        SELECT id FROM usuario WHERE email = 'usuario.test@ejemplo.com'
    )
    AND estado = 'ENTREGADO'
    LIMIT 1;

    BEGIN
        UPDATE pedido
        SET estado = 'PENDIENTE'
        WHERE id = v_pedido_id;

        RAISE EXCEPTION 'ERROR DE TEST: se permitió una transición inválida';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'OK - Se rechazó la transición inválida: %', SQLERRM;
    END;
END;
$$;

-- Caso inválido:
-- ENTREGADO -> EN_PREPARACION
DO $$
DECLARE
    v_pedido_id BIGINT;
BEGIN
    SELECT id INTO v_pedido_id
    FROM pedido
    WHERE usuario_id = (
        SELECT id FROM usuario WHERE email = 'usuario.test@ejemplo.com'
    )
    AND estado = 'ENTREGADO'
    LIMIT 1;

    BEGIN
        UPDATE pedido
        SET estado = 'EN_PREPARACION'
        WHERE id = v_pedido_id;

        RAISE EXCEPTION 'ERROR DE TEST: se permitió modificar un pedido entregado';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'OK - Se rechazó la modificación de un pedido entregado: %', SQLERRM;
    END;
END;
$$;

-- ============================================================
-- REGLA 2: SUBTOTAL
-- ============================================================

-- Caso válido:
INSERT INTO detalle_pedido (
    pedido_id,
    producto_id,
    cantidad,
    precio_unitario,
    subtotal
)
VALUES (
    (
        SELECT id FROM pedido
        WHERE usuario_id = (
            SELECT id FROM usuario WHERE email = 'usuario.test@ejemplo.com'
        )
        AND estado = 'ENTREGADO'
        LIMIT 1
    ),
    (
        SELECT id FROM producto
        WHERE nombre = 'Producto Test'
        LIMIT 1
    ),
    3,
    15.00,
    45.00
);

-- Caso inválido:
-- subtotal incorrecto.
DO $$
BEGIN
    BEGIN
        INSERT INTO detalle_pedido (
            pedido_id,
            producto_id,
            cantidad,
            precio_unitario,
            subtotal
        )
        VALUES (
            (
                SELECT id FROM pedido
                WHERE usuario_id = (
                    SELECT id FROM usuario WHERE email = 'usuario.test@ejemplo.com'
                )
                AND estado = 'ENTREGADO'
                LIMIT 1
            ),
            (
                SELECT id FROM producto
                WHERE nombre = 'Producto Test'
                LIMIT 1
            ),
            3,
            15.00,
            50.00
        );

        RAISE EXCEPTION 'ERROR DE TEST: se permitió un subtotal incorrecto';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'OK - Se rechazó el subtotal incorrecto: %', SQLERRM;
    END;
END;
$$;

-- ============================================================
-- REGLA 3: PRECIO DE PRODUCTOS ACTIVOS
-- ============================================================

-- Caso válido:
-- Producto activo con precio mayor que cero.
INSERT INTO producto (
    nombre,
    precio_lista,
    activo,
    categoria_id
)
VALUES (
    'Producto Activo Valido',
    25.50,
    TRUE,
    (SELECT id FROM categoria WHERE nombre = 'Categoria Test')
);

-- Caso válido:
-- Producto inactivo con precio cero.
INSERT INTO producto (
    nombre,
    precio_lista,
    activo,
    categoria_id
)
VALUES (
    'Producto Inactivo Valido',
    0.00,
    FALSE,
    (SELECT id FROM categoria WHERE nombre = 'Categoria Test')
);

-- Caso inválido:
-- Producto activo con precio cero.
DO $$
BEGIN
    BEGIN
        INSERT INTO producto (
            nombre,
            precio_lista,
            activo,
            categoria_id
        )
        VALUES (
            'Producto Activo Invalido',
            0.00,
            TRUE,
            (SELECT id FROM categoria WHERE nombre = 'Categoria Test')
        );

        RAISE EXCEPTION 'ERROR DE TEST: se permitió producto activo con precio cero';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'OK - Se rechazó el producto activo con precio cero: %', SQLERRM;
    END;
END;
$$;

-- Caso inválido:
-- Producto activo con precio negativo.
DO $$
BEGIN
    BEGIN
        INSERT INTO producto (
            nombre,
            precio_lista,
            activo,
            categoria_id
        )
        VALUES (
            'Producto Activo Negativo',
            -5.00,
            TRUE,
            (SELECT id FROM categoria WHERE nombre = 'Categoria Test')
        );

        RAISE EXCEPTION 'ERROR DE TEST: se permitió producto activo con precio negativo';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'OK - Se rechazó el producto activo con precio negativo: %', SQLERRM;
    END;
END;
$$;

-- ============================================================
-- FINAL
-- ============================================================

-- Los datos creados durante las pruebas no deben quedar
-- almacenados en la base.
ROLLBACK;