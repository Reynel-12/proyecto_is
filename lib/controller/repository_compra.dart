import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/compra.dart';
import 'package:proyecto_is/model/detalle_compra.dart';

class CompraRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> registrarCompra(
    Compra compra,
    List<DetalleCompra> detalles,
  ) async {
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
          WHERE id = ?
        ''',
          [detalle.cantidad, detalle.productoId],
        );
      }

      return compraId;
    });
  }

  Future<List<Map<String, dynamic>>> getCompras() async {
    final db = await _dbHelper.database;
    return await db.query(DBHelper.comprasTable, orderBy: 'fecha DESC');
  }

  Future<List<Map<String, dynamic>>> getDetallesCompra(int compraId) async {
    final db = await _dbHelper.database;
    return await db.query(
      DBHelper.detalleComprasTable,
      where: 'compra_id = ?',
      whereArgs: [compraId],
    );
  }
}
