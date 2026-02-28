class Permission {
  static const String caja = 'caja';
  static const String ventas = 'ventas';
  static const String historial = 'historial';
  static const String devoluciones = 'devoluciones';
  static const String estadisticas = 'estadisticas';
  static const String inventario = 'inventario';
  static const String adquisiciones = 'adquisiciones';
  static const String proveedores = 'proveedores';
  static const String usuarios = 'usuarios';
  static const String configuracionSar = 'configuracion_sar';
  static const String categorias = 'categorias';
  static const String auditoria = 'auditoria';
  static List<String> get allPermissions => [
        caja,
        ventas,
        historial,
        devoluciones,
        estadisticas,
        inventario,
        adquisiciones,
        proveedores,
        usuarios,
        configuracionSar,
        categorias,
        auditoria,
      ];

  // Agrega más permisos según sea necesario
}

class Role {
  static const String administrador = 'Administrador';
  static const String vendedor = 'Vendedor';
  static const String cajero = 'Cajero';
  static const String inventarista = 'Inventarista';
  static const String contable = 'Contable';

  static List<String> getPermissions(String role) {
    switch (role) {
      case administrador:
        return [
          Permission.caja,
          Permission.ventas,
          Permission.historial,
          Permission.devoluciones,
          Permission.estadisticas,
          Permission.inventario,
          Permission.adquisiciones,
          Permission.proveedores,
          Permission.usuarios,
          Permission.configuracionSar,
          Permission.categorias,
          Permission.auditoria,
        ];
      case vendedor:
        return [
          Permission.ventas,
          Permission.historial,
          Permission.devoluciones,
          Permission.caja,
        ];
      case cajero:
        return [
          Permission.caja,
          Permission.historial,
        ];
      case inventarista:
        return [
          Permission.inventario,
          Permission.proveedores,
        ];
      case contable:
        return [
          Permission.estadisticas,
          Permission.adquisiciones,
        ];
      default:
        return [];
    }
  }
}
