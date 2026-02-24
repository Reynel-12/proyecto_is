import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/app_logger.dart';
import 'package:proyecto_is/model/proveedor.dart';
import 'package:proyecto_is/controller/repository_audit.dart';

class ProveedorRepository {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;
  final RepositoryAudit _auditRepo = RepositoryAudit();

  Future<int> insertProveedor(Proveedor proveedor) async {
    try {
      final db = await dbHelper.database;
      return await db.insert('proveedores', proveedor.toMap());
    } catch (e, st) {
      _logger.log.e('Error al insertar proveedor', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<Proveedor>> getProveedores() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('proveedores');

      return maps.map((map) => Proveedor.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e('Error al obtener proveedores', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Proveedor>> getProveedoresByEstado(String estado) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'proveedores',
        where: 'estado = ?',
        whereArgs: [estado],
      );

      return maps.map((map) => Proveedor.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener proveedores por estado',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<int> updateProveedor(Proveedor proveedor) async {
    try {
      if (proveedor.id == null) return -1;
      final oldProveedorList = await getProveedorById(proveedor.id!);
      if (oldProveedorList.isEmpty) return -1;
      final oldProveedor = oldProveedorList.first;

      final db = await dbHelper.database;
      final result = await db.update(
        'proveedores',
        proveedor.toMap(),
        where: 'id_proveedor = ?',
        whereArgs: [proveedor.id],
      );

      if (result > 0) {
        await _auditRepo.logUpdate(
          tabla: 'proveedores',
          registroId: proveedor.id.toString(),
          oldData: oldProveedor.toMap(),
          newData: proveedor.toMap(),
        );
      }
      return result;
    } catch (e, st) {
      _logger.log.e('Error al actualizar proveedor', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<int> deleteProveedor(int id) async {
    try {
      final oldProveedorList = await getProveedorById(id);
      if (oldProveedorList.isEmpty) return -1;
      final oldProveedor = oldProveedorList.first;

      final db = await dbHelper.database;
      final result = await db.delete(
        'proveedores',
        where: 'id_proveedor = ?',
        whereArgs: [id],
      );

      if (result > 0) {
        await _auditRepo.logDelete(
          tabla: 'proveedores',
          registroId: id.toString(),
          oldData: oldProveedor.toMap(),
        );
      }
      return result;
    } catch (e, st) {
      _logger.log.e('Error al eliminar proveedor', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<List<Proveedor>> getProveedorById(int id) async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'proveedores',
        where: 'id_proveedor = ?',
        whereArgs: [id],
      );

      return maps.map((map) => Proveedor.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener proveedor por ID',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }
}
