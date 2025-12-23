import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/view/principal.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Inicializa FFI para escritorio
  sqfliteFfiInit();

  // Usa la versión FFI como factory
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
            home: const MyHomePage(),
          );
        },
      ),
    );
  }
}
