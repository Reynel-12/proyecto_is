class Devolucion {
  final int? id;
  final int ventaId;
  final String numeroFactura;
  final String fecha;
  final String? nombreUsuario;
  final String? motivo;
  final double totalDevuelto;
  final String tipoReembolso; // 'EFECTIVO', 'NOTA_CREDITO', 'CAMBIO'
  final String estado; // 'PARCIAL', 'TOTAL'
  final String idUsuario;

  Devolucion({
    this.id,
    required this.ventaId,
    required this.numeroFactura,
    required this.fecha,
    this.nombreUsuario,
    this.motivo,
    required this.totalDevuelto,
    required this.tipoReembolso,
    required this.estado,
    this.idUsuario = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id_devolucion': id,
      'venta_id': ventaId,
      'numero_factura': numeroFactura,
      'fecha': fecha,
      'nombre_usuario': nombreUsuario,
      'motivo': motivo,
      'total_devuelto': totalDevuelto,
      'tipo_reembolso': tipoReembolso,
      'estado': estado,
    };
  }

  factory Devolucion.fromMap(Map<String, dynamic> map) {
    return Devolucion(
      id: map['id_devolucion'],
      ventaId: map['venta_id'],
      numeroFactura: map['numero_factura'],
      fecha: map['fecha'],
      nombreUsuario: map['nombre_usuario'],
      motivo: map['motivo'],
      totalDevuelto: map['total_devuelto'],
      tipoReembolso: map['tipo_reembolso'],
      estado: map['estado'],
    );
  }
}
