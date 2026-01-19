import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/app_logger.dart';
import 'package:proyecto_is/model/empresa.dart';

class RepositoryEmpresa {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;

  Future<void> insertEmpresa(Empresa empresa) async {
    try {
      final db = await dbHelper.database;
      await db.insert(DBHelper.empresaTable, empresa.toMap());
    } catch (e, st) {
      _logger.log.e('Error al insertar empresa', error: e, stackTrace: st);
    }
  }

  Future<Empresa?> getEmpresa() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.empresaTable,
      );

      return maps.map((map) => Empresa.fromMap(map)).toList().firstOrNull;
    } catch (e, st) {
      _logger.log.e('Error al obtener empresa', error: e, stackTrace: st);
      return null;
    }
  }

  Future<int> updateEmpresa(Empresa empresa) async {
    try {
      final db = await dbHelper.database;
      return await db.update(
        DBHelper.empresaTable,
        empresa.toMap(),
        where: 'id_empresa = ?',
        whereArgs: [empresa.id],
      );
    } catch (e, st) {
      _logger.log.e('Error al actualizar empresa', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> deleteEmpresa(String id) async {
    try {
      final db = await dbHelper.database;
      return await db.delete(
        DBHelper.empresaTable,
        where: 'id_empresa = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      _logger.log.e('Error al eliminar empresa', error: e, stackTrace: st);
      return -1;
    }
  }
}
