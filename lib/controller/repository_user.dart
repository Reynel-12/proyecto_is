import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/user.dart';

class RepositoryUser {
  final dbHelper = DBHelper();

  Future<int> insertUser(User user) async {
    final db = await dbHelper.database;
    return await db.insert(DBHelper.usuariosTable, user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBHelper.usuariosTable,
    );
    return List.generate(maps.length, (i) {
      return User(
        id: maps[i]['id_usuario'],
        nombre: maps[i]['nombre'],
        apellido: maps[i]['apellido'],
        telefono: maps[i]['telefono'],
        correo: maps[i]['correo'],
        contrasena: maps[i]['contrasena'],
        tipo: maps[i]['tipo'],
        estado: maps[i]['estado'],
        fechaCreacion: maps[i]['fecha_creacion'],
        fechaActualizacion: maps[i]['fecha_actualizacion'],
      );
    });
  }

  Future<User?> getUserById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBHelper.usuariosTable,
      where: 'id_usuario = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return null;
    }
    return User(
      id: maps[0]['id_usuario'],
      nombre: maps[0]['nombre'],
      apellido: maps[0]['apellido'],
      telefono: maps[0]['telefono'],
      correo: maps[0]['correo'],
      contrasena: maps[0]['contrasena'],
      tipo: maps[0]['tipo'],
      estado: maps[0]['estado'],
      fechaCreacion: maps[0]['fecha_creacion'],
      fechaActualizacion: maps[0]['fecha_actualizacion'],
    );
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await dbHelper.database;
    return await db.update(
      DBHelper.usuariosTable,
      user,
      where: 'id_usuario = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      DBHelper.usuariosTable,
      where: 'id_usuario = ?',
      whereArgs: [id],
    );
  }

  Future<User?> getUserByEmail(String correo) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBHelper.usuariosTable,
      where: 'correo = ?',
      whereArgs: [correo],
    );
    if (maps.isEmpty) {
      return null;
    }
    return User(
      id: maps[0]['id_usuario'],
      nombre: maps[0]['nombre'],
      apellido: maps[0]['apellido'],
      telefono: maps[0]['telefono'],
      correo: maps[0]['correo'],
      contrasena: maps[0]['contrasena'],
      tipo: maps[0]['tipo'],
      estado: maps[0]['estado'],
      fechaCreacion: maps[0]['fecha_creacion'],
      fechaActualizacion: maps[0]['fecha_actualizacion'],
    );
  }

  Future<User?> signInWithEmailAndPassword(
    String correo,
    String contrasena,
  ) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DBHelper.usuariosTable,
      where: 'correo = ? AND contrasena = ?',
      whereArgs: [correo, contrasena],
    );
    if (maps.isEmpty) {
      return null;
    }
    return User(
      id: maps[0]['id_usuario'],
      nombre: maps[0]['nombre'],
      apellido: maps[0]['apellido'],
      telefono: maps[0]['telefono'],
      correo: maps[0]['correo'],
      contrasena: maps[0]['contrasena'],
      tipo: maps[0]['tipo'],
      estado: maps[0]['estado'],
      fechaCreacion: maps[0]['fecha_creacion'],
      fechaActualizacion: maps[0]['fecha_actualizacion'],
    );
  }

  Future<void> resetPassword(String correo, String contrasena) async {
    final db = await dbHelper.database;
    await db.update(
      DBHelper.usuariosTable,
      {
        'contrasena': contrasena,
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      },
      where: 'correo = ?',
      whereArgs: [correo],
    );
  }
}
