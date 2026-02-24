class AuditLog {
  final int? id;
  final String tabla;
  final String registroId;
  final String accion;
  final String? usuarioId;
  final String? nombreUsuario;
  final String fecha;
  final String? detalles;

  AuditLog({
    this.id,
    required this.tabla,
    required this.registroId,
    required this.accion,
    this.usuarioId,
    this.nombreUsuario,
    required this.fecha,
    this.detalles,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id_audit_log'],
      tabla: map['tabla'],
      registroId: map['registro_id'],
      accion: map['accion'],
      usuarioId: map['usuario_id'],
      nombreUsuario: map['nombre_usuario'],
      fecha: map['fecha'],
      detalles: map['detalles'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_audit_log': id,
      'tabla': tabla,
      'registro_id': registroId,
      'accion': accion,
      'usuario_id': usuarioId,
      'nombre_usuario': nombreUsuario,
      'fecha': fecha,
      'detalles': detalles,
    };
  }
}
