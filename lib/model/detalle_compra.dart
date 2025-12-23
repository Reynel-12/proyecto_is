class DetalleCompra {
  final int? id;
  final int? compraId;
  final String productoId;
  final int cantidad;
  final double costoUnitario;
  final double subtotal;

  DetalleCompra({
    this.id,
    this.compraId,
    required this.productoId,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'compra_id': compraId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'costo_unitario': costoUnitario,
      'subtotal': subtotal,
    };
  }

  factory DetalleCompra.fromMap(Map<String, dynamic> map) {
    return DetalleCompra(
      id: map['id'],
      compraId: map['compra_id'],
      productoId: map['producto_id'],
      cantidad: map['cantidad'],
      costoUnitario: map['costo_unitario'],
      subtotal: map['subtotal'],
    );
  }
}
