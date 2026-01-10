class Empresa {
  final int id;
  final String rtn;
  final String razonSocial;
  final String nombreComercial;
  final String direccion;
  final String telefono;
  final String correo;
  final String monedaDefecto;
  final String fechaCreacion;

  Empresa({
    required this.id,
    required this.rtn,
    required this.razonSocial,
    required this.nombreComercial,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.monedaDefecto,
    required this.fechaCreacion,
  });

  factory Empresa.fromMap(Map<String, dynamic> map) {
    return Empresa(
      id: map['id_empresa'],
      rtn: map['rtn'],
      razonSocial: map['razon_social'],
      nombreComercial: map['nombre_comercial'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      correo: map['correo'],
      monedaDefecto: map['moneda_defecto'],
      fechaCreacion: map['fecha_creacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_empresa': id,
      'rtn': rtn,
      'razon_social': razonSocial,
      'nombre_comercial': nombreComercial,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'moneda_defecto': monedaDefecto,
      'fecha_creacion': fechaCreacion,
    };
  }
}
