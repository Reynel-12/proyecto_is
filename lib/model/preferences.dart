import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_is/controller/notification_service.dart';
import 'package:proyecto_is/model/notifications.dart';

class PreferencesService {
  static const String _keyTemaOscuro = "es_tema_oscuro";

  Future<ThemeMode> obtenerTemaInicial() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? esTemaOscuro = prefs.getBool(_keyTemaOscuro);
    return esTemaOscuro == true ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> guardarTema(bool esTemaOscuro) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTemaOscuro, esTemaOscuro);
  }

  Future<void> eliminarTema() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTemaOscuro);
  }
}

class TemaProveedor extends ChangeNotifier {
  TemaProveedor(this._preferencesService) {
    _inicializarTema();
  }

  final PreferencesService _preferencesService;
  ThemeMode _modoTema = ThemeMode.light;

  ThemeMode get modoTema => _modoTema;
  bool get esModoOscuro => _modoTema == ThemeMode.dark;

  Future<void> _inicializarTema() async {
    _modoTema = await _preferencesService.obtenerTemaInicial();
    notifyListeners();
  }

  Future<void> cambiarTema() async {
    // Alternar el estado del tema
    _modoTema = _modoTema == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    notifyListeners(); // Notificar a los oyentes sobre el cambio

    // Guardar el estado del tema en preferencias
    if (_modoTema == ThemeMode.dark) {
      await _preferencesService.guardarTema(true);
    } else {
      await _preferencesService.eliminarTema();
    }
  }
}

class MisTemas {
  static final ThemeData temaClaro = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
    ),
  );

  static final ThemeData temaOscuro = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  final NotificationService _notificationService = NotificationService();
  Set<String> _dismissedProductIds = {};

  List<NotificationItem> get notifications => _notifications;

  NotificationProvider() {
    _loadDismissedIds();
  }

  Future<void> _loadDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? dismissed = prefs.getStringList('dismissed_notifications');
    if (dismissed != null) {
      _dismissedProductIds = dismissed.toSet();
    }
  }

  Future<void> _saveDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_notifications', _dismissedProductIds.toList());
  }

  Future<void> loadNotifications() async {
    _notifications = await _notificationService.getLowStockNotifications(_dismissedProductIds);
    notifyListeners();
  }

  void dismissNotification(String productId) {
    _dismissedProductIds.add(productId);
    _saveDismissedIds();
    loadNotifications(); // Recargar para filtrar
  }

  void dismissAllNotifications() {
    for (var notification in _notifications) {
      // Extraer productId del message, asumiendo formato "El producto \"nombre\" tiene stock bajo..."
      final RegExp regExp = RegExp(r'El producto "([^"]+)"');
      final match = regExp.firstMatch(notification.message);
      if (match != null) {
        final productId = notification.id.replaceFirst('low_stock_', '');
        _dismissedProductIds.add(productId);
      }
    }
    _saveDismissedIds();
    loadNotifications();
  }
}
