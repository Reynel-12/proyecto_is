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

  Future<List<Map<String, dynamic>>> getHistorialVentasDetallado() async {
    final db = await dbHelper.database; // Tu instancia de sqflite

    return await db.rawQuery('''
    SELECT 
      v.id AS venta_id,
      v.fecha,
      v.total AS venta_total,
      v.estado,
      dv.cantidad,
      dv.precio_unitario,
      dv.subtotal,
      p.nombre AS producto_nombre,
      p.unidad_medida
    FROM ventas v
    INNER JOIN detalle_ventas dv ON v.id = dv.venta_id
    INNER JOIN productos p ON dv.producto_id = p.id
    ORDER BY v.fecha DESC
  ''');
  }

  Future<List<VentaCompleta>> getVentasAgrupadas() async {
    final res = await getHistorialVentasDetallado();

    // Usamos un Map para agrupar detalles por ID de venta
    Map<int, VentaCompleta> ventasMap = {};

    for (var row in res) {
      int idVenta = row['venta_id'];

      if (!ventasMap.containsKey(idVenta)) {
        ventasMap[idVenta] = VentaCompleta(
          id: idVenta,
          fecha: row['fecha'],
          total: row['venta_total'],
          estado: row['estado'],
          detalles: [],
        );
      }

      ventasMap[idVenta]!.detalles.add(
        DetalleItem(
          producto: row['producto_nombre'],
          cantidad: row['cantidad'],
          precio: row['precio_unitario'],
          subtotal: row['subtotal'],
        ),
      );
    }

    return ventasMap.values.toList();
  }
}
