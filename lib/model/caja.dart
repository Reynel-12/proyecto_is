class Caja {
  final int? id;
  final String fechaApertura;
  final double montoApertura;
  final String? fechaCierre;
  final double? montoCierre;
  final double totalVentas;
  final double totalEfectivo;
  final double ingresos;
  final double egresos;
  final double? diferencia;
  final String estado; // 'Abierta', 'Cerrada'

  Caja({
    this.id,
    required this.fechaApertura,
    required this.montoApertura,
    this.fechaCierre,
    this.montoCierre,
    this.totalVentas = 0.0,
    this.totalEfectivo = 0.0,
    this.ingresos = 0.0,
    this.egresos = 0.0,
    this.diferencia,
    this.estado = 'Abierta',
  });

  Map<String, dynamic> toMap() {
    return {
      'id_caja': id,
      'fecha_apertura': fechaApertura,
      'monto_apertura': montoApertura,
      'fecha_cierre': fechaCierre,
      'monto_cierre': montoCierre,
      'total_ventas': totalVentas,
      'total_efectivo': totalEfectivo,
      'ingresos': ingresos,
      'egresos': egresos,
      'diferencia': diferencia,
      'estado': estado,
    };
  }

  factory Caja.fromMap(Map<String, dynamic> map) {
    return Caja(
      id: map['id_caja'],
      fechaApertura: map['fecha_apertura'],
      montoApertura: map['monto_apertura'],
      fechaCierre: map['fecha_cierre'],
      montoCierre: map['monto_cierre'],
      totalVentas: map['total_ventas'] ?? 0.0,
      totalEfectivo: map['total_efectivo'] ?? 0.0,
      ingresos: map['ingresos'] ?? 0.0,
      egresos: map['egresos'] ?? 0.0,
      diferencia: map['diferencia'],
      estado: map['estado'],
    );
  }
}
