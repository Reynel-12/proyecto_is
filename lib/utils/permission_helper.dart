import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility to check stored permissions for the current user.
class PermissionHelper {
  /// Returns true if the user has the given [permiso].
  static Future<bool> hasPermission(String permiso) async {
    final prefs = await SharedPreferences.getInstance();
    final perms = prefs.getString('permisos');
    if (perms == null || perms.isEmpty) return false;
    try {
      final list = List<String>.from(jsonDecode(perms));
      return list.contains(permiso);
    } catch (_) {
      return false;
    }
  }
}
