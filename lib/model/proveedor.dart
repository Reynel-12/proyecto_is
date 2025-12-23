class Proveedor {
  final int? id; // null cuando todavía no se ha insertado
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final String? fechaRegistro;

  Proveedor({
    this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.correo,
    this.fechaRegistro,
  });

  // Convertir Map → Objeto
  factory Proveedor.fromMap(Map<String, dynamic> map) {
    return Proveedor(
      id: map['id'],
      nombre: map['nombre'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      correo: map['correo'],
      fechaRegistro: map['fecha_registro'],
    );
  }

  // Convertir Objeto → Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'fecha_registro': fechaRegistro,
    };
  }
}
