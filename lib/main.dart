import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/view/login_view.dart';
import 'package:proyecto_is/view/principal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Map<String, String>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    String? user = prefs.getString('user');
    String? tipo = prefs.getString('tipo');
    String? estado = prefs.getString('estado');
    return {
      'email': email ?? '',
      'password': password ?? '',
      'user': user ?? '',
      'tipo': tipo ?? '',
      'estado': estado ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => TemaProveedor(PreferencesService()),
        ),
      ],
      child: Consumer<TemaProveedor>(
        builder: (context, temaProveedor, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            darkTheme: MisTemas.temaOscuro,
            theme: MisTemas.temaClaro,
            themeMode: temaProveedor.modoTema,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.black
                : const Color.fromRGBO(244, 243, 243, 1),
            home: FutureBuilder<Map<String, String>>(
              future: loadData(),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  if (asyncSnapshot.hasData &&
                      (asyncSnapshot.data?['email'] ?? '').isNotEmpty &&
                      (asyncSnapshot.data?['password'] ?? '').isNotEmpty &&
                      (asyncSnapshot.data?['user'] ?? '').isNotEmpty &&
                      (asyncSnapshot.data?['tipo'] ?? '').isNotEmpty &&
                      (asyncSnapshot.data?['estado'] ?? '').isNotEmpty) {
                    return const MyHomePage();
                  } else {
                    return const Login();
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}
