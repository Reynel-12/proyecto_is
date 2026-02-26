import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/app_logger.dart';
import 'package:proyecto_is/model/caja.dart';
import 'package:proyecto_is/model/movimiento_caja.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_is/controller/repository_audit.dart';

class CajaRepository {
  final dbHelper = DBHelper();
  final RepositoryAudit _auditRepo = RepositoryAudit();

  // Retorna -2 si el usuario ya tiene una caja abierta
  Future<int> abrirCaja(double montoInicial) async {
    final logger = AppLogger.instance;
    final prefs = await SharedPreferences.getInstance();
    try {
      final db = await dbHelper.database;
      String? fullname = prefs.getString('user_fullname');
      String? usuarioId = prefs.getString('user');
      if (fullname == null || usuarioId == null) {
        return -1;
      }

      // Validar que el usuario no tenga ya una caja abierta
      final cajaExistente = await db.query(
        DBHelper.cajaTable,
        where: "estado = ? AND usuario_id = ?",
        whereArgs: ['Abierta', usuarioId],
        limit: 1,
      );
      if (cajaExistente.isNotEmpty) {
        return -2; // Ya tiene una caja abierta
      }

      final caja = Caja(
        cajeroAbre: fullname,
        cajeroCierra: fullname,
        fechaApertura: DateTime.now().toIso8601String(),
        montoApertura: montoInicial,
        totalEfectivo: montoInicial,
        usuarioId: usuarioId,
      );
      return await db.insert(DBHelper.cajaTable, caja.toMap());
    } catch (e, stackTrace) {
      logger.log.e('Error al abrir caja', error: e, stackTrace: stackTrace);
      return -1;
    }
  }

  // Devuelve la caja abierta del usuario actual (filtrado por usuario_id)
  Future<Caja?> obtenerCajaAbierta() async {
    final logger = AppLogger.instance;
    final prefs = await SharedPreferences.getInstance();
    try {
      final db = await dbHelper.database;
      final String? usuarioId = prefs.getString('user');
      if (usuarioId == null) return null;

      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.cajaTable,
        where: "estado = ? AND usuario_id = ?",
        whereArgs: ['Abierta', usuarioId],
        orderBy: 'id_caja DESC',
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Caja.fromMap(maps.first);
      }
      return null;
    } catch (e, st) {
      logger.log.e('Error al obtener caja abierta', error: e, stackTrace: st);
      return null;
    }
  }

  Future<int> cerrarCaja(
    Caja caja,
    double montoFinal,
    double diferencia,
  ) async {
    final logger = AppLogger.instance;
    try {
      final db = await dbHelper.database;
      final prefs = await SharedPreferences.getInstance();
      String? fullname = prefs.getString('user_fullname');
      if (fullname == null) {
        return -1;
      }
      final cajaCerrada = Caja(
        id: caja.id,
        cajeroAbre: caja.cajeroAbre,
        cajeroCierra: fullname,
        fechaApertura: caja.fechaApertura,
        montoApertura: caja.montoApertura,
        fechaCierre: DateTime.now().toIso8601String(),
        montoCierre: montoFinal,
        totalVentas: caja.totalVentas,
        totalEfectivo: caja.totalEfectivo,
        ingresos: caja.ingresos,
        egresos: caja.egresos,
        diferencia: diferencia,
        estado: 'Cerrada',
      );
      await db.update(
        DBHelper.cajaTable,
        cajaCerrada.toMap(),
        where: 'id_caja = ?',
        whereArgs: [caja.id],
      );
      return cajaCerrada.id!;
    } catch (e, st) {
      logger.log.e('Error al cerrar caja', error: e, stackTrace: st);
      return -1;
    }
  }

  Future<void> registrarMovimiento(MovimientoCaja movimiento) async {
    final logger = AppLogger.instance;
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // Insertar movimiento
        await txn.insert(DBHelper.movimientosCajaTable, movimiento.toMap());

        // Actualizar totales de la caja
        final cajaMap = await txn.query(
          DBHelper.cajaTable,
          where: 'id_caja = ?',
          whereArgs: [movimiento.idCaja],
        );

        if (cajaMap.isNotEmpty) {
          final caja = Caja.fromMap(cajaMap.first);
          double nuevosIngresos = caja.ingresos;
          double nuevosEgresos = caja.egresos;
          double nuevoTotalEfectivo = caja.totalEfectivo;
          double nuevasVentas = caja.totalVentas;

          if (movimiento.tipo == 'Ingreso') {
            nuevosIngresos += movimiento.monto;
            if (movimiento.metodoPago == 'Efectivo') {
              nuevoTotalEfectivo += movimiento.monto;
            }
          } else if (movimiento.tipo == 'Egreso') {
            nuevosEgresos += movimiento.monto;
            if (movimiento.metodoPago == 'Efectivo') {
              nuevoTotalEfectivo -= movimiento.monto;
            }
          } else if (movimiento.tipo == 'Venta') {
            nuevasVentas += movimiento.monto;
            if (movimiento.metodoPago == 'Efectivo') {
              nuevoTotalEfectivo += movimiento.monto;
            }
          }

          await txn.update(
            DBHelper.cajaTable,
            {
              'ingresos': nuevosIngresos,
              'egresos': nuevosEgresos,
              'total_efectivo': nuevoTotalEfectivo,
              'total_ventas': nuevasVentas,
            },
            where: 'id_caja = ?',
            whereArgs: [caja.id],
          );
        }
      });
    } catch (e, st) {
      logger.log.e('Error al registrar movimiento', error: e, stackTrace: st);
    }
  }

  Future<List<MovimientoCaja>> obtenerMovimientos(int idCaja) async {
    final logger = AppLogger.instance;
    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.movimientosCajaTable,
        where: 'id_caja = ?',
        whereArgs: [idCaja],
        orderBy: 'id_movimiento DESC',
      );
      return List.generate(maps.length, (i) => MovimientoCaja.fromMap(maps[i]));
    } catch (e, st) {
      logger.log.e('Error al obtener movimientos', error: e, stackTrace: st);
      return [];
    }
  }

  Future<void> eliminarMovimiento(int idMovimiento) async {
    final logger = AppLogger.instance;
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // Obtener el movimiento antes de borrarlo para revertir los montos
        final movMap = await txn.query(
          DBHelper.movimientosCajaTable,
          where: 'id_movimiento = ?',
          whereArgs: [idMovimiento],
        );

        if (movMap.isNotEmpty) {
          final mov = MovimientoCaja.fromMap(movMap.first);

          // Borrar movimiento
          await txn.delete(
            DBHelper.movimientosCajaTable,
            where: 'id_movimiento = ?',
            whereArgs: [idMovimiento],
          );

          await _auditRepo.logDelete(
            tabla: DBHelper.movimientosCajaTable,
            registroId: idMovimiento.toString(),
            oldData: mov.toMap(),
            txn: txn,
          );

          // Actualizar caja
          final cajaMap = await txn.query(
            DBHelper.cajaTable,
            where: 'id_caja = ?',
            whereArgs: [mov.idCaja],
          );

          if (cajaMap.isNotEmpty) {
            final caja = Caja.fromMap(cajaMap.first);
            double nuevosIngresos = caja.ingresos;
            double nuevosEgresos = caja.egresos;
            double nuevoTotalEfectivo = caja.totalEfectivo;
            double nuevasVentas = caja.totalVentas;

            if (mov.tipo == 'Ingreso') {
              nuevosIngresos -= mov.monto;
              if (mov.metodoPago == 'Efectivo') {
                nuevoTotalEfectivo -= mov.monto;
              }
            } else if (mov.tipo == 'Egreso') {
              nuevosEgresos -= mov.monto;
              if (mov.metodoPago == 'Efectivo') {
                nuevoTotalEfectivo += mov.monto;
              }
            } else if (mov.tipo == 'Venta') {
              nuevasVentas -= mov.monto;
              if (mov.metodoPago == 'Efectivo') {
                nuevoTotalEfectivo -= mov.monto;
              }
            }

            await txn.update(
              DBHelper.cajaTable,
              {
                'ingresos': nuevosIngresos,
                'egresos': nuevosEgresos,
                'total_efectivo': nuevoTotalEfectivo,
                'total_ventas': nuevasVentas,
              },
              where: 'id_caja = ?',
              whereArgs: [caja.id],
            );
          }
        }
      });
    } catch (e, st) {
      logger.log.e('Error al eliminar movimiento', error: e, stackTrace: st);
    }
  }

  Future<void> editarMovimiento(MovimientoCaja movimiento) async {
    final logger = AppLogger.instance;
    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        // 1. Obtener el movimiento anterior para revertir
        final movAnteriorMap = await txn.query(
          DBHelper.movimientosCajaTable,
          where: 'id_movimiento = ?',
          whereArgs: [movimiento.id],
        );

        if (movAnteriorMap.isNotEmpty) {
          final movAnterior = MovimientoCaja.fromMap(movAnteriorMap.first);

          // 2. Revertir impacto del movimiento anterior en la caja
          final cajaMap = await txn.query(
            DBHelper.cajaTable,
            where: 'id_caja = ?',
            whereArgs: [movimiento.idCaja],
          );

          if (cajaMap.isNotEmpty) {
            final caja = Caja.fromMap(cajaMap.first);
            double nuevosIngresos = caja.ingresos;
            double nuevosEgresos = caja.egresos;
            double nuevoTotalEfectivo = caja.totalEfectivo;
            double nuevasVentas = caja.totalVentas;

            // Revertir anterior
            if (movAnterior.tipo == 'Ingreso') {
              nuevosIngresos -= movAnterior.monto;
              if (movAnterior.metodoPago == 'Efectivo') {
                nuevoTotalEfectivo -= movAnterior.monto;
              }
            } else if (movAnterior.tipo == 'Egreso') {
              nuevosEgresos -= movAnterior.monto;
              if (movAnterior.metodoPago == 'Efectivo') {
                nuevoTotalEfectivo += movAnterior.monto;
              }
            }

            // Aplicar nuevo
            if (movimiento.tipo == 'Ingreso') {
              nuevosIngresos += movimiento.monto;
              if (movimiento.metodoPago == 'Efectivo') {
                nuevoTotalEfectivo += movimiento.monto;
              }
            } else if (movimiento.tipo == 'Egreso') {
              nuevosEgresos += movimiento.monto;
              if (movimiento.metodoPago == 'Efectivo') {
                nuevoTotalEfectivo -= movimiento.monto;
              }
            }

            // Actualizar Caja
            await txn.update(
              DBHelper.cajaTable,
              {
                'ingresos': nuevosIngresos,
                'egresos': nuevosEgresos,
                'total_efectivo': nuevoTotalEfectivo,
                'total_ventas': nuevasVentas,
              },
              where: 'id_caja = ?',
              whereArgs: [caja.id],
            );

            // 3. Actualizar Movimiento
            await txn.update(
              DBHelper.movimientosCajaTable,
              movimiento.toMap(),
              where: 'id_movimiento = ?',
              whereArgs: [movimiento.id],
            );

            await _auditRepo.logUpdate(
              tabla: DBHelper.movimientosCajaTable,
              registroId: movimiento.id.toString(),
              oldData: movAnterior.toMap(),
              newData: movimiento.toMap(),
              txn: txn,
            );
          }
        }
      });
    } catch (e, st) {
      logger.log.e('Error al editar movimiento', error: e, stackTrace: st);
    }
  }

  // Historial global: muestra TODAS las cajas (de todos los usuarios)
  Future<List<Caja>> obtenerHistorialCajas({
    String filtro = 'Todo',
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final logger = AppLogger.instance;
    try {
      final db = await dbHelper.database;
      // Sin filtro por usuario: se muestran todas las cajas cerradas de todos los cajeros
      String whereClause = "estado = 'Cerrada'";
      List<dynamic> whereArgs = [];

      final now = DateTime.now();

      if (filtro == 'Hoy') {
        final startOfDay = DateTime(
          now.year,
          now.month,
          now.day,
        ).toIso8601String();
        final endOfDay = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        ).toIso8601String();
        whereClause += " AND fecha_apertura BETWEEN ? AND ?";
        whereArgs.addAll([startOfDay, endOfDay]);
      } else if (filtro == 'Semana') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startStr = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        ).toIso8601String();
        final endStr = now.toIso8601String();
        whereClause += " AND fecha_apertura BETWEEN ? AND ?";
        whereArgs.addAll([startStr, endStr]);
      } else if (filtro == 'Mes') {
        final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
        final endOfMonth = DateTime(
          now.year,
          now.month + 1,
          0,
          23,
          59,
          59,
        ).toIso8601String();
        whereClause += " AND fecha_apertura BETWEEN ? AND ?";
        whereArgs.addAll([startOfMonth, endOfMonth]);
      } else if (filtro == 'Rango' && fechaInicio != null && fechaFin != null) {
        final startStr = fechaInicio.toIso8601String();
        final endStr = DateTime(
          fechaFin.year,
          fechaFin.month,
          fechaFin.day,
          23,
          59,
          59,
        ).toIso8601String();
        whereClause += " AND fecha_apertura BETWEEN ? AND ?";
        whereArgs.addAll([startStr, endStr]);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.cajaTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'fecha_apertura DESC',
      );
      return List.generate(maps.length, (i) => Caja.fromMap(maps[i]));
    } catch (e, st) {
      logger.log.e(
        'Error al obtener historial de cajas',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<Map<String, Map<String, double>>> obtenerDesgloseCaja(
    int idCaja,
  ) async {
    final logger = AppLogger.instance;
    final Map<String, Map<String, double>> desglose = {
      'Venta': {'Efectivo': 0.0, 'Tarjeta': 0.0, 'Transferencia': 0.0},
      'Ingreso': {'Efectivo': 0.0, 'Tarjeta': 0.0, 'Transferencia': 0.0},
      'Egreso': {'Efectivo': 0.0, 'Tarjeta': 0.0, 'Transferencia': 0.0},
    };

    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.movimientosCajaTable,
        where: 'id_caja = ?',
        whereArgs: [idCaja],
      );

      for (var map in maps) {
        final mov = MovimientoCaja.fromMap(map);
        if (desglose.containsKey(mov.tipo) &&
            desglose[mov.tipo]!.containsKey(mov.metodoPago)) {
          desglose[mov.tipo]![mov.metodoPago] =
              (desglose[mov.tipo]![mov.metodoPago] ?? 0.0) + mov.monto;
        }
      }
      return desglose;
    } catch (e, st) {
      logger.log.e(
        'Error al obtener desglose de caja',
        error: e,
        stackTrace: st,
      );
      return desglose;
    }
  }
}
