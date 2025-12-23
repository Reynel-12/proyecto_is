import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/proveedor.dart';
import 'package:sqflite/sqflite.dart';

class ProveedorRepository {
  final dbHelper = DBHelper();

  Future<int> insertProveedor(Proveedor proveedor) async {
    final db = await dbHelper.database;
    return await db.insert(
      'proveedores',
      proveedor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Proveedor>> getProveedores() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('proveedores');

    return maps.map((map) => Proveedor.fromMap(map)).toList();
  }

  Future<int> updateProveedor(Proveedor proveedor) async {
    final db = await dbHelper.database;
    return await db.update(
      'proveedores',
      proveedor.toMap(),
      where: 'id = ?',
      whereArgs: [proveedor.id],
    );
  }

  Future<int> deleteProveedor(int id) async {
    final db = await dbHelper.database;
    return await db.delete('proveedores', where: 'id = ?', whereArgs: [id]);
  }
}
