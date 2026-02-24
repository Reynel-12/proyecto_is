import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/app_logger.dart';
import 'package:proyecto_is/model/categorias.dart';
import 'package:proyecto_is/controller/repository_audit.dart';

class RepositoryCategoria {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;
  final RepositoryAudit _auditRepo = RepositoryAudit();

  Future<int> insertCategoria(Categorias categorias) async {
    try {
      final db = await dbHelper.database;
      return await db.insert('categorias', categorias.toMap());
    } catch (e, st) {
      _logger.log.e('Error al insertar categorias', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<Categorias>> getCategorias() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('categorias');

      return maps.map((map) => Categorias.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e('Error al obtener categorias', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Categorias>> getCategoriaById(int id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categorias',
        where: 'id_categoria = ?',
        whereArgs: [id],
      );

      return maps.map((map) => Categorias.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener categorias por ID',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<Categorias>> getCategoriasByEstado(String estado) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categorias',
        where: 'estado = ?',
        whereArgs: [estado],
      );

      return maps.map((map) => Categorias.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener categorias por estado',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<Categorias>> getCategoriasActivos() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categorias',
        where: 'estado = ?',
        whereArgs: ['Activo'],
      );

      return maps.map((map) => Categorias.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener categorias activos',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<int> updateCategoria(Categorias categorias) async {
    try {
      final oldCategoriaList = await getCategoriaById(categorias.idCategoria!);
      if (oldCategoriaList.isEmpty) return -1;
      final oldCategoria = oldCategoriaList.first;

      final db = await dbHelper.database;
      final result = await db.update(
        'categorias',
        categorias.toMap(),
        where: 'id_categoria = ?',
        whereArgs: [categorias.idCategoria],
      );

      if (result > 0) {
        await _auditRepo.logUpdate(
          tabla: 'categorias',
          registroId: categorias.idCategoria.toString(),
          oldData: oldCategoria.toMap(),
          newData: categorias.toMap(),
        );
      }
      return result;
    } catch (e, st) {
      _logger.log.e('Error al actualizar categorias', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> deleteCategoria(int id) async {
    try {
      final oldCategoriaList = await getCategoriaById(id);
      if (oldCategoriaList.isEmpty) return -1;
      final oldCategoria = oldCategoriaList.first;

      final db = await dbHelper.database;
      final result = await db.delete(
        'categorias',
        where: 'id_categoria = ?',
        whereArgs: [id],
      );

      if (result > 0) {
        await _auditRepo.logDelete(
          tabla: 'categorias',
          registroId: id.toString(),
          oldData: oldCategoria.toMap(),
        );
      }
      return result;
    } catch (e, st) {
      _logger.log.e('Error al eliminar categorias', error: e, stackTrace: st);
      return -1;
    }
  }
}
