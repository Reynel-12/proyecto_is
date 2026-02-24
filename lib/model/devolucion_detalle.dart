class DevolucionDetalle {
  final int? id;
  final int? devolucionId;
  final String productoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String estadoProducto; // 'BUENO', 'DEFECTUOSO', 'NO_REINGRESA'

  DevolucionDetalle({
    this.id,
    this.devolucionId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.estadoProducto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_detalle_devolucion': id,
      'devolucion_id': devolucionId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'estado_producto': estadoProducto,
    };
  }

  factory DevolucionDetalle.fromMap(Map<String, dynamic> map) {
    return DevolucionDetalle(
      id: map['id_detalle_devolucion'],
      devolucionId: map['devolucion_id'],
      productoId: map['producto_id'],
      cantidad: map['cantidad'],
      precioUnitario: map['precio_unitario'],
      subtotal: map['subtotal'],
      estadoProducto: map['estado_producto'],
    );
  }
}
