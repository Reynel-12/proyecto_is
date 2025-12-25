class MovimientoCaja {
  final int? id;
  final int idCaja;
  final int? idVenta;
  final String tipo; // 'Ingreso', 'Egreso', 'Venta'
  final String concepto;
  final double monto;
  final String metodoPago; // 'Efectivo', 'Tarjeta', etc.
  final String fecha;

  MovimientoCaja({
    this.id,
    required this.idCaja,
    this.idVenta,
    required this.tipo,
    required this.concepto,
    required this.monto,
    required this.metodoPago,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_movimiento': id,
      'id_caja': idCaja,
      'id_venta': idVenta,
      'tipo': tipo,
      'concepto': concepto,
      'monto': monto,
      'metodo_pago': metodoPago,
      'fecha': fecha,
    };
  }

  factory MovimientoCaja.fromMap(Map<String, dynamic> map) {
    return MovimientoCaja(
      id: map['id_movimiento'],
      idCaja: map['id_caja'],
      idVenta: map['id_venta'],
      tipo: map['tipo'],
      concepto: map['concepto'],
      monto: map['monto'],
      metodoPago: map['metodo_pago'],
      fecha: map['fecha'],
    );
  }
}
