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
      ORDER BY id_venta DESC
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
        if (detalle.productoId == 'N/A') {
          continue;
        }
        final result = await txn.rawQuery(
          '''
        SELECT stock FROM productos WHERE id_producto = ?
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
        WHERE id_producto = ?
        ''',
          [detalle.cantidad, detalle.productoId],
        );
      }

      // 4. Actualizar Caja si existe una abierta
      final cajaAbierta = await txn.query(
        DBHelper.cajaTable,
        where: 'estado = ?',
        whereArgs: ['Abierta'],
        orderBy: 'id_caja DESC',
        limit: 1,
      );

      if (cajaAbierta.isNotEmpty) {
        final caja = cajaAbierta.first;
        final int cajaId = caja['id_caja'] as int;
        final double currentTotalVentas = (caja['total_ventas'] as num)
            .toDouble();
        final double currentTotalEfectivo = (caja['total_efectivo'] as num)
            .toDouble();

        // Insertar movimiento
        await txn.insert(DBHelper.movimientosCajaTable, {
          'id_caja': cajaId,
          'id_venta': ventaId,
          'tipo': 'Venta',
          'concepto': 'Venta #$numeroFactura',
          'monto': venta.total,
          'metodo_pago': 'Efectivo', // Asumimos efectivo por ahora
          'fecha': DateTime.now().toIso8601String(),
        });

        // Actualizar totales caja
        await txn.update(
          DBHelper.cajaTable,
          {
            'total_ventas': currentTotalVentas + venta.total,
            'total_efectivo': currentTotalEfectivo + venta.total,
          },
          where: 'id_caja = ?',
          whereArgs: [cajaId],
        );
      }

      return ventaId;
    });
  }

  Future<List<Map<String, dynamic>>> getHistorialVentasDetallado() async {
    final db = await dbHelper.database; // Tu instancia de sqflite

    return await db.rawQuery('''
    SELECT 
      v.id_venta AS venta_id,
      v.fecha,
      v.total AS venta_total,
      v.estado_fiscal,
      v.cambio,
      v.monto_pagado,
      v.numero_factura,
      v.cai,
      v.rtn_cliente,
      v.nombre_cliente,
      v.rango_autorizado,
      v.rtn_emisor,
      v.razon_social_emisor,
      v.fecha_limite_cai,
      v.isv,
      v.subtotal,
      dv.cantidad,
      dv.precio_unitario,
      dv.subtotal,
      p.nombre AS producto_nombre,
      p.unidad_medida
    FROM ventas v
    INNER JOIN detalle_ventas dv ON v.id_venta = dv.venta_id
    INNER JOIN productos p ON dv.producto_id = p.id_producto
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
          estado: row['estado_fiscal'],
          cambio: row['cambio'],
          montoPagado: row['monto_pagado'],
          numeroFactura: row['numero_factura'],
          cai: row['cai'],
          rtnCliente: row['rtn_cliente'],
          nombreCliente: row['nombre_cliente'],
          rangoAutorizado: row['rango_autorizado'],
          rtnEmisor: row['rtn_emisor'],
          razonSocialEmisor: row['razon_social_emisor'],
          fechaLimiteCai: row['fecha_limite_cai'],
          isv: row['isv'],
          subtotal: row['subtotal'],
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

  Future<double> getTotalVentasByProducto(String productoId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(cantidad) as total
      FROM ${DBHelper.detalleVentasTable}
      WHERE producto_id = ?
    ''',
      [productoId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<List<Map<String, dynamic>>> getUltimasVentasByProducto(
    String productoId, {
    int limit = 5,
  }) async {
    final db = await dbHelper.database;
    return await db.rawQuery(
      '''
      SELECT 
        v.fecha,
        dv.cantidad,
        dv.precio_unitario,
        dv.subtotal
      FROM ${DBHelper.ventasTable} v
      INNER JOIN ${DBHelper.detalleVentasTable} dv ON v.id_venta = dv.venta_id
      WHERE dv.producto_id = ?
      ORDER BY v.fecha DESC
      LIMIT ?
    ''',
      [productoId, limit],
    );
  }
}
