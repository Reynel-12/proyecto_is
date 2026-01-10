import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/empresa.dart';

class RepositoryEmpresa {
  final dbHelper = DBHelper();

  Future<void> insertEmpresa(Empresa empresa) async {
    final db = await dbHelper.database;
    await db.insert(DBHelper.empresaTable, empresa.toMap());
  }

  Future<Empresa?> getEmpresa() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBHelper.empresaTable,
    );

    return maps.map((map) => Empresa.fromMap(map)).toList().first;
  }

  Future<int> updateEmpresa(Empresa empresa) async {
    final db = await dbHelper.database;
    return await db.update(
      DBHelper.empresaTable,
      empresa.toMap(),
      where: 'id_empresa = ?',
      whereArgs: [empresa.id],
    );
  }

  Future<int> deleteEmpresa(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      DBHelper.empresaTable,
      where: 'id_empresa = ?',
      whereArgs: [id],
    );
  }
}
