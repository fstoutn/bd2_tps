db.pedidos.insertMany([
  {
    "_id": 1,
    "fecha_hora": new Date("2026-09-05T20:14:42Z"),
    "estado": "ENTREGADO",
    "forma_pago": "EFECTIVO",
    "total": 2800.00,
    "cliente": { "usuario_id": 2, "nombre": "Ana Gómez", "email": "ana.gomez@mail.com" },
    "lineas": [
      { "detalle_id": 1, "producto_id": 1, "producto_nombre": "Muzzarella", "cantidad": 2, "precio_unitario": 1000.00, "subtotal": 2000.00 },
      { "detalle_id": 2, "producto_id": 7, "producto_nombre": "Coca 1.5L", "cantidad": 1, "precio_unitario": 800.00, "subtotal": 800.00 }
    ]
  },
  {
    "_id": 2,
    "fecha_hora": new Date("2026-09-05T20:14:42Z"),
    "estado": "EN_PREPARACION",
    "forma_pago": "TARJETA",
    "total": 1500.00,
    "cliente": { "usuario_id": 3, "nombre": "Luis Paz", "email": "luis.paz@mail.com" },
    "lineas": [
      { "detalle_id": 3, "producto_id": 2, "producto_nombre": "Napolitana", "cantidad": 1, "precio_unitario": 1500.00, "subtotal": 1500.00 }
    ]
  },
  {
    "_id": 3,
    "fecha_hora": new Date("2026-09-05T20:14:42Z"),
    "estado": "PENDIENTE",
    "forma_pago": "EFECTIVO",
    "total": 2800.00,
    "cliente": { "usuario_id": 4, "nombre": "Marta Ruiz", "email": "marta.ruiz@mail.com" },
    "lineas": [
      { "detalle_id": 4, "producto_id": 8, "producto_nombre": "Agua mineral", "cantidad": 4, "precio_unitario": 400.00, "subtotal": 1600.00 },
      { "detalle_id": 5, "producto_id": 9, "producto_nombre": "Flan casero", "cantidad": 2, "precio_unitario": 600.00, "subtotal": 1200.00 }
    ]
  },
  {
    "_id": 4,
    "fecha_hora": new Date("2026-09-05T20:14:42Z"),
    "estado": "CANCELADO",
    "forma_pago": "TRANSFERENCIA",
    "total": 1050.00,
    "cliente": { "usuario_id": 5, "nombre": "Juan Torres", "email": "juan.torres@mail.com" },
    "lineas": [
      { "detalle_id": 6, "producto_id": 4, "producto_nombre": "Carne", "cantidad": 3, "precio_unitario": 350.00, "subtotal": 1050.00 }
    ]
  },
  {
    "_id": 200005,
    "fecha_hora": new Date("2026-06-16T00:20:08Z"),
    "estado": "CANCELADO",
    "forma_pago": "TARJETA",
    "total": 8505.68,
    "cliente": { "usuario_id": 1, "nombre": "Admin Sistema", "email": "admin@foodstore.com" },
    "lineas": [
      { "detalle_id": 200007, "producto_id": 56628, "producto_nombre": "Producto Test #13237", "cantidad": 4, "precio_unitario": 2126.42, "subtotal": 8505.68 }
    ]
  }
]);

db.pedidos.find({}, { _id: 1, estado: 1 })

db.pedidos.find({ estado: "CANCELADO" })

db.pedidos.find({ "lineas.producto_nombre": "Carne" })

db.pedidos.find({ total: { $gt: 2000 } })