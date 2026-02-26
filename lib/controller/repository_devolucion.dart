import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/app_logger.dart';
import 'package:proyecto_is/model/caja.dart';
import 'package:proyecto_is/model/devolucion.dart';
import 'package:proyecto_is/model/devolucion_detalle.dart';
import 'package:proyecto_is/model/movimiento_caja.dart';

class RepositoryDevolucion {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;

  // Método transaccional para crear devolución
  Future<int> createDevolucion(
    Devolucion devolucion,
    List<DevolucionDetalle> detalles,
  ) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      try {
        // 1. Insertar Devolución
        final devolucionId = await txn.insert(
          'devoluciones',
          devolucion.toMap(),
        );

        // 2. Procesar Detalles
        for (var detalle in detalles) {
          final detalleMap = detalle.toMap();
          detalleMap['devolucion_id'] = devolucionId; // Asignar ID generado
          await txn.insert('devolucion_detalle', detalleMap);

          // 3. Actualizar Inventario (Si aplica)
          if (detalle.estadoProducto == 'BUENO') {
            await txn.rawUpdate(
              '''
              UPDATE ${DBHelper.productosTable}
              SET stock = stock + ?
              WHERE id_producto = ?
            ''',
              [detalle.cantidad, detalle.productoId],
            );
          } else {
            // Aquí se podría lógica para merma si existiera esa tabla
            _logger.log.i(
              'Producto ${detalle.productoId} devuelto como ${detalle.estadoProducto}. No reingresa a stock vendible.',
            );
          }
        }

        // 4. Generar Movimiento de Caja (Si aplica)
        // Necesitamos saber qué caja está abierta actualmente para asociar el movimiento
        // Buscamos la caja abierta del usuario o la última abierta general
        // OJO: Asumimos que hay una caja abierta. Si no, esto podría fallar o quedar huérfano.
        // Por simplicidad, buscamos caja 'Abierta'.
        final List<Map<String, dynamic>> cajasAbiertas = await txn.query(
          DBHelper.cajaTable,
          where: 'estado = ? AND usuario_id = ?',
          whereArgs: ['Abierta', devolucion.idUsuario],
          limit: 1,
        );

        int? cajaId;
        if (cajasAbiertas.isNotEmpty) {
          cajaId = cajasAbiertas.first['id_caja'];
        }
        if (cajaId == null) {
          _logger.log.e('No se encontró caja abierta para la devolución.');
          return devolucionId;
        }

        // Lógica de movimiento según tipo
        // if (devolucion.tipoReembolso == 'Efectivo') {
        // Si es REEMBOLSO o CAMBIO con devolución de dinero, es una SALIDA de caja.
        // Si el totalDevuelto > 0 implica salida de dinero.
        if (devolucion.totalDevuelto > 0) {
          final movimiento = MovimientoCaja(
            idCaja: cajaId,
            tipo: 'Devolucion',
            concepto: 'Devolución venta ${devolucion.numeroFactura}',
            monto: devolucion.totalDevuelto,
            metodoPago: devolucion.tipoReembolso,
            fecha: DateTime.now().toIso8601String(),
          );
          await txn.insert(DBHelper.movimientosCajaTable, movimiento.toMap());
          if (cajasAbiertas.isNotEmpty) {
            final caja = Caja.fromMap(cajasAbiertas.first);
            double nuevosIngresos = caja.ingresos;
            double nuevosEgresos = caja.egresos;
            double nuevoTotalEfectivo = caja.totalEfectivo;
            double nuevasVentas = caja.totalVentas;

            if (movimiento.tipo == 'Devolucion') {
              nuevosEgresos += movimiento.monto;
              if (movimiento.metodoPago == 'Efectivo') {
                nuevoTotalEfectivo -= movimiento.monto;
              }
            }

            await txn.update(
              DBHelper.cajaTable,
              {
                'ingresos': nuevosIngresos,
                'egresos': nuevosEgresos,
                'total_efectivo': nuevoTotalEfectivo,
                'total_ventas': nuevasVentas,
              },
              where: 'id_caja = ?',
              whereArgs: [caja.id],
            );
          }
        }
        // }
        // NOTA_CREDITO: No mueve caja, solo queda registro de la devolución.

        return devolucionId;
      } catch (e, st) {
        _logger.log.e('Error creando devolución: $e', stackTrace: st);
        throw Exception('Error al procesar la devolución: $e');
      }
    });
  }

  // Obtener devoluciones por venta
  Future<List<Devolucion>> getDevolucionesByVenta(int ventaId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'devoluciones',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
    );
    return List.generate(maps.length, (i) => Devolucion.fromMap(maps[i]));
  }

  // Obtener cantidad ya devuelta de un producto en una venta específica
  Future<int> getCantidadDevuelta(String facturaId, String productoId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      '''
        SELECT SUM(dd.cantidad) as total
        FROM devolucion_detalle dd
        INNER JOIN devoluciones d ON dd.devolucion_id = d.id_devolucion
        WHERE d.numero_factura = ? AND dd.producto_id = ?
      ''',
      [facturaId, productoId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  // Obtener todas las devoluciones con información de la venta
  Future<List<Map<String, dynamic>>> getAllDevolucionesDetalladas() async {
    final db = await dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        d.id_devolucion,
        d.fecha,
        d.total_devuelto,
        d.motivo,
        d.tipo_reembolso,
        d.estado,
        d.numero_factura,
        d.nombre_usuario,
        v.nombre_cliente
      FROM devoluciones d
      INNER JOIN ventas v ON d.venta_id = v.id_venta
      ORDER BY d.fecha DESC
    ''');
  }

  // Obtener los detalles de una devolución específica
  Future<List<Map<String, dynamic>>> getDetallesByDevolucion(
    int devolucionId,
  ) async {
    final db = await dbHelper.database;
    return await db.rawQuery(
      '''
      SELECT 
        dd.cantidad,
        dd.precio_unitario,
        dd.subtotal,
        dd.estado_producto,
        p.nombre AS producto_nombre,
        p.unidad_medida
      FROM devolucion_detalle dd
      INNER JOIN productos p ON dd.producto_id = p.id_producto
      WHERE dd.devolucion_id = ?
    ''',
      [devolucionId],
    );
  }
}
