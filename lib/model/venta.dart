class Venta {
  final int? id; // null antes de insertarse
  final String fecha;
  final double total;
  final double? montoPagado;
  final double? cambio;
  final String? estado; // 'PENDIENTE', 'COMPLETADA', etc.

  Venta({
    this.id,
    required this.fecha,
    required this.total,
    this.montoPagado,
    this.cambio,
    this.estado,
  });

  // Map → Venta
  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'],
      fecha: map['fecha'],
      total: map['total'],
      montoPagado: map['monto_pagado'],
      cambio: map['cambio'],
      estado: map['estado'],
    );
  }

  // Venta → Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha,
      'total': total,
      'monto_pagado': montoPagado,
      'cambio': cambio,
      'estado': estado,
    };
  }
}

class VentaCompleta {
  final int id;
  final String fecha;
  final double total;
  final String estado;
  final List<DetalleItem> detalles;

  VentaCompleta({
    required this.id,
    required this.fecha,
    required this.total,
    required this.estado,
    required this.detalles,
  });
}

class DetalleItem {
  final String producto;
  final int cantidad;
  final double precio;
  final double subtotal;

  DetalleItem({
    required this.producto,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });
}
