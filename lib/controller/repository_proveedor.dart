import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/proveedor.dart';

class ProveedorRepository {
  final dbHelper = DBHelper();

  Future<int> insertProveedor(Proveedor proveedor) async {
    final db = await dbHelper.database;
    return await db.insert('proveedores', proveedor.toMap());
  }

  Future<List<Proveedor>> getProveedores() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('proveedores');

    return maps.map((map) => Proveedor.fromMap(map)).toList();
  }

  Future<List<Proveedor>> getProveedoresByEstado(String estado) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'proveedores',
      where: 'estado = ?',
      whereArgs: [estado],
    );

    return maps.map((map) => Proveedor.fromMap(map)).toList();
  }

  Future<int> updateProveedor(Proveedor proveedor) async {
    final db = await dbHelper.database;
    return await db.update(
      'proveedores',
      proveedor.toMap(),
      where: 'id_proveedor = ?',
      whereArgs: [proveedor.id],
    );
  }

  Future<int> deleteProveedor(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'proveedores',
      where: 'id_proveedor = ?',
      whereArgs: [id],
    );
  }

  Future<List<Proveedor>> getProveedorById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'proveedores',
      where: 'id_proveedor = ?',
      whereArgs: [id],
    );

    return maps.map((map) => Proveedor.fromMap(map)).toList();
  }
}
