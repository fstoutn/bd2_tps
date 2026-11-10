#!/usr/bin/env python3
"""Suite reproducible de TP8; usa solo la libreria estandar.
No implementa una app movil: orquesta ejecuciones y verifica errores esperados.
"""
import csv, sqlite3, pathlib, json, shutil
ROOT = pathlib.Path(__file__).resolve().parents[1]
M = ROOT/'movil'; OUT = ROOT/'tests'; db_path=M/'foodstore_movil.db'
if db_path.exists(): db_path.unlink()
con=sqlite3.connect(db_path)
con.execute('PRAGMA foreign_keys=ON')
con.executescript((M/'schema_sqlite.sql').read_text())
assert con.execute('PRAGMA foreign_keys').fetchone()[0] == 1
assert all(row[0] in ('producto_cache','pedido_borrador','item_borrador','cola_sync','snapshot_servidor') for row in con.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))
assert all(con.execute("SELECT sql FROM sqlite_master WHERE type='table' AND name=?",(t,)).fetchone()[0].rstrip().endswith('STRICT') for t in ('producto_cache','pedido_borrador','item_borrador','cola_sync'))
with (M/'servidor_snapshot.csv').open(newline='',encoding='utf-8') as f:
    rows=list(csv.DictReader(f))
con.executemany('INSERT INTO snapshot_servidor VALUES (?,?,?,?,?,?,?)',[(int(r['id']),r['nombre'],int(r['precio_centavos']),int(r['stock']),int(r['disponible']),int(r['eliminado']),r['fecha_copia']) for r in rows]);con.commit()
con.executescript((M/'cargar_snapshot.sql').read_text())
con.executescript((M/'pruebas_sqlite.sql').read_text())
assert con.execute("SELECT count(*) FROM pedido_borrador WHERE id_local LIKE '%0099'").fetchone()[0]==0
assert con.execute("SELECT count(*) FROM producto_cache WHERE disponible=1 AND eliminado=0").fetchone()[0]==6
log=[]
def record(case, state, detail):
    log.append({'caso':case,'resultado':state,'detalle':detail})
def neworder(num, product, count, price, uuidnum=None):
    id_local=f'00000000-0000-4000-8000-{num:012d}'
    req=f'10000000-0000-4000-8000-{(uuidnum if uuidnum is not None else num):012d}'
    con.execute('INSERT INTO pedido_borrador VALUES (?,?,?,?)',(id_local,'usuario_ficticio','EFECTIVO','2026-11-10T10:15:00'))
    con.execute('INSERT INTO item_borrador VALUES (?,?,?,?)',(id_local,product,count,price))
    con.execute("INSERT INTO cola_sync VALUES (?,?,'PENDIENTE','')",(req,id_local))
    con.commit()
    return id_local,req
def semaforo():
    con.executescript((M/'semaforo.sql').read_text())
def check(req,expect):
    state=con.execute('SELECT estado FROM cola_sync WHERE solicitud_uuid=?',(req,)).fetchone()[0]
    assert state==expect,(req,state,expect)
    return state
# C1 and transaction/rollback
record('1.c / C1','OK','6 productos visibles localmente, COMMIT guarda 1 pedido e items; ROLLBACK deja 0 filas')
# C7: check and FK truly throw errors, no rows added
before=con.execute('SELECT COUNT(*) FROM item_borrador').fetchone()[0]
for qty,pid,expected in [(0,2,'CHECK'),(1,999999,'FOREIGN KEY')]:
    try:
        con.execute('INSERT INTO item_borrador VALUES (?,?,?,?)',('00000000-0000-4000-8000-000000000001',pid,qty,1000))
    except sqlite3.IntegrityError as e:
        assert expected in str(e).upper(),str(e)
        con.rollback()
    else: raise AssertionError('Se acepto un item invalido')
assert con.execute('SELECT COUNT(*) FROM item_borrador').fetchone()[0]==before
record('C7','OK','Cantidad 0: CHECK constraint failed; ID 999999: FOREIGN KEY constraint failed; sin filas nuevas')
# Existing initial borrador is green, keep it for transparency
semaforo(); check('10000000-0000-4000-8000-000000000001','SIMULADO_APROBADO')
# C2: stale price -> conflict, client accepts, NEW UUID -> approved
order, req = neworder(2,1,1,100000)
con.execute('UPDATE snapshot_servidor SET precio_centavos=110000 WHERE id=1');con.commit()
semaforo();check(req,'CONFLICTO')
con.execute('UPDATE item_borrador SET precio_centavos_visto=110000 WHERE id_local=?',(order,))
new_req='10000000-0000-4000-8000-000000000020'
con.execute("INSERT INTO cola_sync VALUES (?,?,'PENDIENTE','')",(new_req,order));con.commit()
semaforo();check(new_req,'SIMULADO_APROBADO');check(req,'CONFLICTO')
record('C2','OK','Precio 100000 -> 110000: CONFLICTO; aceptación + nueva solicitud UUID: SIMULADO_APROBADO; solicitud vieja sigue CONFLICTO')
# restore current price only in local snapshot for other cases
con.execute('UPDATE snapshot_servidor SET precio_centavos=100000 WHERE id=1');con.commit()
# C3
_,req=neworder(3,2,9,150000)
semaforo();check(req,'RECHAZADO')
record('C3','OK','Se piden 9 Napolitanas con stock servidor 8: RECHAZADO')
# C4: tombstone retained, hidden on cache refresh
_,req=neworder(4,4,1,35000)
con.execute('UPDATE snapshot_servidor SET disponible=0, eliminado=1 WHERE id=4');con.commit()
con.executescript((M/'cargar_snapshot.sql').read_text())
semaforo();check(req,'RECHAZADO')
assert con.execute('SELECT COUNT(*) FROM producto_cache WHERE id=4').fetchone()[0]==1
assert con.execute('SELECT COUNT(*) FROM producto_cache WHERE id=4 AND disponible=1 AND eliminado=0').fetchone()[0]==0
record('C4','OK','Carne tombstone: RECHAZADO; conservada en cache pero oculta en catalogo')
# C5
_,req=neworder(5,7,1,80000)
semaforo();check(req,'SIMULADO_APROBADO')
record('C5','OK','Coca 1.5L, mismo precio, disponible, stock suficiente: SIMULADO_APROBADO (no venta)')
# C6: reuse UUID fails, rerun semaforo does not change states
_,req=neworder(6,8,1,40000)
semaforo();check(req,'SIMULADO_APROBADO')
prior=dict(con.execute('SELECT solicitud_uuid,estado FROM cola_sync').fetchall())
try:
    con.execute("INSERT INTO cola_sync VALUES (?,?,'PENDIENTE','')",(req,'00000000-0000-4000-8000-000000000006'))
except sqlite3.IntegrityError as e:
    assert 'UNIQUE' in str(e).upper()
    con.rollback()
else: raise AssertionError('UUID duplicado aceptado')
semaforo()
assert prior==dict(con.execute('SELECT solicitud_uuid,estado FROM cola_sync').fetchall())
record('C6','OK','UUID duplicado: UNIQUE constraint failed; segunda evaluacion no cambia estados')
# Extra: empty order rejection
con.execute("INSERT INTO pedido_borrador VALUES ('00000000-0000-4000-8000-000000000007','prueba','EFECTIVO','2026-11-10')")
con.execute("INSERT INTO cola_sync VALUES ('10000000-0000-4000-8000-000000000007','00000000-0000-4000-8000-000000000007','PENDIENTE','')")
con.commit();semaforo()
check('10000000-0000-4000-8000-000000000007','RECHAZADO')
record('EXTRA','OK','Borrador sin items: RECHAZADO')
# Cannot claim live PostgreSQL evidence: demo SQL baseline is two pedidos, stock 67.
assert sum(int(r['stock']) for r in rows)==67
assert con.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
assert con.execute('PRAGMA foreign_key_check').fetchall()==[]
record('INTEGRIDAD','OK','PRAGMA integrity_check=ok y foreign_key_check=vacío')
(OUT/'resultados_verificados.json').write_text(json.dumps({'motor':'Python sqlite3 / SQLite '+sqlite3.sqlite_version,'fecha_ejecucion':'generado al ejecutar tests/verificar.py','pruebas':log,'nota':'PostgreSQL no fue ejecutado contra una instancia real. CSV es una muestra de demostración declarada, no exportación comprobada.'},ensure_ascii=False,indent=2),encoding='utf-8')
con.close()
print('SQLite:',sqlite3.sqlite_version,'| CASOS OK:',len(log))
for r in log: print(r['caso'],r['resultado'],r['detalle'])
print('BASE:',db_path)
