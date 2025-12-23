import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/detalle_venta.dart';
import 'package:proyecto_is/model/venta.dart';

class VentaRepository {
  final dbHelper = DBHelper();

  Future<int> registrarVentaConDetalles(
    Venta venta,
    List<DetalleVenta> detalles,
  ) async {
    final db = await dbHelper.database;
    return await db.transaction<int>((txn) async {
      // 1. Verificar stock producto por producto
      for (final detalle in detalles) {
        final result = await txn.rawQuery(
          '''
        SELECT stock FROM productos WHERE id = ?
        ''',
          [detalle.productoId],
        );

        if (result.isEmpty) {
          throw Exception("El producto ${detalle.productoId} no existe.");
        }

        final int stockActual = result.first['stock'] as int;

        if (stockActual < detalle.cantidad) {
          throw Exception(
            "Stock insuficiente para el producto '${detalle.productoId}'. "
            "Stock actual: $stockActual, requerido: ${detalle.cantidad}",
          );
        }
      }

      // 2. Si todo ok, insertar venta
      final int ventaId = await txn.insert('ventas', venta.toMap());

      // 3. Insertar detalles + actualizar stock
      for (final detalle in detalles) {
        final detalleFix = detalle;
        detalleFix.ventaId = ventaId;

        // Insertar detalle
        await txn.insert('detalle_ventas', detalleFix.toMap());

        // Descontar stock
        await txn.rawUpdate(
          '''
        UPDATE productos
        SET stock = stock - ?
        WHERE id = ?
        ''',
          [detalle.cantidad, detalle.productoId],
        );
      }

      return ventaId;
    });
  }
}
