import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/detalle_venta.dart';
import 'package:proyecto_is/model/venta.dart';
import 'package:sqflite/sqflite.dart';

class VentaRepository {
  final dbHelper = DBHelper();

  Future<String> _generarNumeroFactura(Transaction txn) async {
    try {
      final now = DateTime.now();
      final datePart =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final query =
          '''
      SELECT numero_factura 
      FROM ${DBHelper.ventasTable}
      WHERE numero_factura LIKE 'FAC-$datePart-%'
      ORDER BY id DESC
      LIMIT 1
    ''';

      final List<Map<String, dynamic>> result = await txn.rawQuery(query);

      int correlativo = 1;

      if (result.isNotEmpty) {
        final lastInvoice = result.first['numero_factura']?.toString();

        if (lastInvoice != null && lastInvoice.contains('-')) {
          final parts = lastInvoice.split('-');

          if (parts.length == 3) {
            final parsed = int.tryParse(parts[2]);
            if (parsed != null) {
              correlativo = parsed + 1;
            } else {}
          } else {}
        }
      }

      return 'FAC-$datePart-${correlativo.toString().padLeft(4, '0')}';
    } catch (e) {
      // 🔥 fallback seguro para evitar romper la transacción
      final fallback = DateTime.now().millisecondsSinceEpoch;
      return 'FAC-ERR-$fallback';
    }
  }

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

      final numeroFactura = await _generarNumeroFactura(txn);
      venta.numeroFactura = numeroFactura;

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
      v.cambio,
      v.monto_pagado,
      v.numero_factura,
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
          cambio: row['cambio'],
          montoPagado: row['monto_pagado'],
          numeroFactura: row['numero_factura'],
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
