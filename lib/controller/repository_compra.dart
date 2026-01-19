import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/app_logger.dart';
import 'package:proyecto_is/model/compra.dart';
import 'package:proyecto_is/model/detalle_compra.dart';

class CompraRepository {
  final DBHelper _dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;

  Future<int> registrarCompra(
    Compra compra,
    List<DetalleCompra> detalles,
  ) async {
    try {
      final db = await _dbHelper.database;

      return await db.transaction((txn) async {
        // 1. Insertar la compra
        int compraId = await txn.insert(DBHelper.comprasTable, compra.toMap());

        // 2. Insertar los detalles y actualizar stock
        for (var detalle in detalles) {
          // Insertar detalle con el ID de la compra recién creada
          await txn.insert(DBHelper.detalleComprasTable, {
            'compra_id': compraId,
            'producto_id': detalle.productoId,
            'cantidad': detalle.cantidad,
            'costo_unitario': detalle.costoUnitario,
            'subtotal': detalle.subtotal,
          });

          // 3. ACTUALIZAR STOCK DEL PRODUCTO
          await txn.execute(
            '''
          UPDATE ${DBHelper.productosTable}
          SET stock = stock + ?
          WHERE id_producto = ?
        ''',
            [detalle.cantidad, detalle.productoId],
          );
        }

        return compraId;
      });
    } catch (e, st) {
      _logger.log.e('Error al registrar compra', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getCompras() async {
    try {
      final db = await _dbHelper.database;
      return await db.query(DBHelper.comprasTable, orderBy: 'fecha DESC');
    } catch (e, st) {
      _logger.log.e('Error al obtener compras', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDetallesCompra(int compraId) async {
    try {
      final db = await _dbHelper.database;
      return await db.query(
        DBHelper.detalleComprasTable,
        where: 'compra_id = ?',
        whereArgs: [compraId],
      );
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener detalles de compra',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }
}
