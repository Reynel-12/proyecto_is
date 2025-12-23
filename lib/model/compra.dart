class Compra {
  final int? id;
  final int proveedorId;
  final String fecha;
  final double total;

  Compra({
    this.id,
    required this.proveedorId,
    required this.fecha,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proveedor_id': proveedorId,
      'fecha': fecha,
      'total': total,
    };
  }

  factory Compra.fromMap(Map<String, dynamic> map) {
    return Compra(
      id: map['id'],
      proveedorId: map['proveedor_id'],
      fecha: map['fecha'],
      total: map['total'],
    );
  }
}
