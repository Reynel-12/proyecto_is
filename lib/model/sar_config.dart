class SarConfig {
  final int? id;
  final String cai;
  final String rangoInicial;
  final String rangoFinal;
  final String fechaLimite;
  final int numeroActual;
  final bool activo;

  SarConfig({
    this.id,
    required this.cai,
    required this.rangoInicial,
    required this.rangoFinal,
    required this.fechaLimite,
    required this.numeroActual,
    this.activo = true,
  });

  factory SarConfig.fromMap(Map<String, dynamic> map) {
    return SarConfig(
      id: map['id_config'],
      cai: map['cai'],
      rangoInicial: map['rango_inicial'],
      rangoFinal: map['rango_final'],
      fechaLimite: map['fecha_limite'],
      numeroActual: map['numero_actual'],
      activo: map['activo'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_config': id,
      'cai': cai,
      'rango_inicial': rangoInicial,
      'rango_final': rangoFinal,
      'fecha_limite': fechaLimite,
      'numero_actual': numeroActual,
      'activo': activo ? 1 : 0,
    };
  }
}
