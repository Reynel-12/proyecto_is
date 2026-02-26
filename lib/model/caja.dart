class Caja {
  final int? id;
  final String cajeroAbre;
  final String cajeroCierra;
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
  final String? usuarioId;

  Caja({
    this.id,
    required this.cajeroAbre,
    required this.cajeroCierra,
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
    this.usuarioId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_caja': id,
      'cajero_abre': cajeroAbre,
      'cajero_cierra': cajeroCierra,
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
      'usuario_id': usuarioId,
    };
  }

  factory Caja.fromMap(Map<String, dynamic> map) {
    return Caja(
      id: map['id_caja'],
      cajeroAbre: map['cajero_abre'],
      cajeroCierra: map['cajero_cierra'],
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
      usuarioId: map['usuario_id'],
    );
  }

  Caja copyWith({
    int? id,
    String? cajeroAbre,
    String? cajeroCierra,
    String? fechaApertura,
    double? montoApertura,
    String? fechaCierre,
    double? montoCierre,
    double? totalVentas,
    double? totalEfectivo,
    double? ingresos,
    double? egresos,
    double? diferencia,
    String? estado,
    String? usuarioId,
  }) {
    return Caja(
      id: id ?? this.id,
      cajeroAbre: cajeroAbre ?? this.cajeroAbre,
      cajeroCierra: cajeroCierra ?? this.cajeroCierra,
      fechaApertura: fechaApertura ?? this.fechaApertura,
      montoApertura: montoApertura ?? this.montoApertura,
      fechaCierre: fechaCierre ?? this.fechaCierre,
      montoCierre: montoCierre ?? this.montoCierre,
      totalVentas: totalVentas ?? this.totalVentas,
      totalEfectivo: totalEfectivo ?? this.totalEfectivo,
      ingresos: ingresos ?? this.ingresos,
      egresos: egresos ?? this.egresos,
      diferencia: diferencia ?? this.diferencia,
      estado: estado ?? this.estado,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}
