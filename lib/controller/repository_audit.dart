import 'dart:convert';
import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/app_logger.dart';
import 'package:proyecto_is/model/audit_log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class RepositoryAudit {
  final dbHelper = DBHelper();
  final AppLogger _logger = AppLogger.instance;

  // Insert a new audit log entry
  Future<int> insertAuditLog(AuditLog log) async {
    try {
      final db = await dbHelper.database;
      return await db.insert(DBHelper.auditLogsTable, log.toMap());
    } catch (e, st) {
      _logger.log.e(
        'Error al insertar registro de auditoría',
        error: e,
        stackTrace: st,
      );
      return -1;
    }
  }

  Future<void> insertAuditLogWithTxn(Transaction txn, AuditLog log) async {
    try {
      await txn.insert(DBHelper.auditLogsTable, log.toMap());
    } catch (e, st) {
      _logger.log.e(
        'Error al insertar registro de auditoría con transacción',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Get all audit logs
  Future<List<AuditLog>> getAuditLogs() async {
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.auditLogsTable,
        orderBy: 'fecha DESC',
      );
      return maps.map((map) => AuditLog.fromMap(map)).toList();
    } catch (e, st) {
      _logger.log.e(
        'Error al obtener registros de auditoría',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  // Helper method to automatically calculate and log changes for an UPDATE
  Future<void> logUpdate({
    required String tabla,
    required String registroId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
    Transaction? txn, // <- opcional
  }) async {
    try {
      final differences = calculateDifferences(oldData, newData);
      if (differences.isEmpty) {
        return; // Nothing changed
      }

      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('user');
      final nombreUsuario = prefs.getString('user_fullname');

      final log = AuditLog(
        tabla: tabla,
        registroId: registroId,
        accion: 'UPDATE',
        usuarioId: usuarioId,
        nombreUsuario: nombreUsuario,
        fecha: DateTime.now().toIso8601String(),
        detalles: jsonEncode(differences),
      );

      // Aquí decides si usar txn o db
      if (txn != null) {
        await insertAuditLogWithTxn(txn, log);
      } else {
        await insertAuditLog(log);
      }
    } catch (e, st) {
      _logger.log.e(
        'Error al registrar UPDATE en auditoría para $tabla',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Helper method to automatically log a DELETE
  Future<void> logDelete({
    required String tabla,
    required String registroId,
    required Map<String, dynamic> oldData,
    Transaction? txn, // <- opcional
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('user');
      final nombreUsuario = prefs.getString('user_fullname');

      final log = AuditLog(
        tabla: tabla,
        registroId: registroId,
        accion: 'DELETE',
        usuarioId: usuarioId,
        nombreUsuario: nombreUsuario,
        fecha: DateTime.now().toIso8601String(),
        detalles: jsonEncode(oldData),
      );

      // Aquí decides si usar txn o db
      if (txn != null) {
        await insertAuditLogWithTxn(txn, log);
      } else {
        await insertAuditLog(log);
      }
    } catch (e, st) {
      _logger.log.e(
        'Error al registrar DELETE en auditoría para $tabla',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Calculate the differences between two maps, ignoring certain non-critical fields
  Map<String, dynamic> calculateDifferences(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    Map<String, dynamic> diffs = {};
    final ignoredKeys = ['fecha_actualizacion', 'fecha_creacion'];

    newData.forEach((key, newValue) {
      if (ignoredKeys.contains(key)) return;

      final oldValue = oldData[key];
      // Compare values, carefully handling possible nulls and type mismatches (e.g. 1 vs 1.0)
      if (oldValue.toString() != newValue.toString()) {
        diffs[key] = {'old': oldValue, 'new': newValue};
      }
    });

    return diffs;
  }
}
