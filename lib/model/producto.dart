import 'package:proyecto_is/model/proveedor.dart';

class Producto {
  final String id; // UUID
  final String nombre;
  final int? proveedorId; // FK a proveedores
  final String? unidadMedida;
  final double precio;
  final double costo;
  final int stock;
  final String? fechaCreacion;
  final String? fechaActualizacion;
  int cantidad;

  Producto({
    required this.id,
    required this.nombre,
    this.proveedorId,
    this.unidadMedida,
    required this.precio,
    required this.costo,
    this.stock = 0,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.cantidad = 0,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      proveedorId: map['proveedor_id'],
      unidadMedida: map['unidad_medida'],
      precio: map['precio'],
      costo: map['costo'],
      stock: map['stock'],
      fechaCreacion: map['fecha_creacion'],
      fechaActualizacion: map['fecha_actualizacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'proveedor_id': proveedorId,
      'unidad_medida': unidadMedida,
      'precio': precio,
      'costo': costo,
      'stock': stock,
      'fecha_creacion': fechaCreacion,
      'fecha_actualizacion': fechaActualizacion,
    };
  }
}

class ProductoProveedor {
  Producto producto;
  Proveedor proveedor;

  ProductoProveedor({required this.producto, required this.proveedor});

  factory ProductoProveedor.fromMap(Map<String, dynamic> map) {
    return ProductoProveedor(
      producto: Producto.fromMap(map),
      proveedor: Proveedor.fromMap(map),
    );
  }
}
