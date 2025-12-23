import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  // Nombres de tablas centralizados
  static const String proveedoresTable = 'proveedores';
  static const String productosTable = 'productos';
  static const String ventasTable = 'ventas';
  static const String detalleVentasTable = 'detalle_ventas';
  static const String comprasTable = 'compras';
  static const String detalleComprasTable = 'detalle_compras';

  // Getter con manejo de errores
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabaseSafely();
    return _database!;
  }

  // --- Inicialización con manejo de errores ---
  Future<Database> _initDatabaseSafely() async {
    try {
      return await initDatabase();
    } catch (e, st) {
      print("Error en initDatabase(): $e\n$st");
      rethrow; // Re-lanza para depuración si es necesario
    }
  }

  // --- Inicialización principal ---
  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'ventas.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // Asegura claves foráneas siempre activas
        await db.execute("PRAGMA foreign_keys = ON;");
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(db, oldVersion, newVersion);
      },
    );
  }

  // --- Creación de tablas separada para mantenimiento ---
  Future<void> _createTables(Database db) async {
    await db.execute('''
    CREATE TABLE $proveedoresTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      direccion TEXT,
      telefono TEXT,
      correo TEXT,
      fecha_registro TEXT
    );
  ''');

    await db.execute('''
    CREATE TABLE $productosTable (
      id TEXT PRIMARY KEY,
      nombre TEXT NOT NULL,
      proveedor_id INTEGER,
      unidad_medida TEXT,
      precio REAL NOT NULL,
      costo REAL NOT NULL,
      stock INTEGER NOT NULL DEFAULT 0,
      fecha_creacion TEXT,
      fecha_actualizacion TEXT,
      FOREIGN KEY (proveedor_id) REFERENCES $proveedoresTable(id)
          ON UPDATE CASCADE
          ON DELETE SET NULL
    );
  ''');

    await db.execute('''
    CREATE TABLE $ventasTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT NOT NULL,
      total REAL NOT NULL,
      monto_pagado REAL,
      cambio REAL,
      estado TEXT
    );
  ''');

    await db.execute('''
    CREATE TABLE $detalleVentasTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      venta_id INTEGER NOT NULL,
      producto_id TEXT NOT NULL,
      cantidad INTEGER NOT NULL,
      precio_unitario REAL NOT NULL,
      subtotal REAL NOT NULL,
      descuento REAL DEFAULT 0,
      FOREIGN KEY (venta_id) REFERENCES $ventasTable(id)
          ON UPDATE CASCADE
          ON DELETE CASCADE,
      FOREIGN KEY (producto_id) REFERENCES $productosTable(id)
          ON UPDATE CASCADE
          ON DELETE RESTRICT
    );
  ''');

    await db.execute('''
    CREATE TABLE $comprasTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      proveedor_id INTEGER NOT NULL,
      fecha TEXT NOT NULL,
      total REAL NOT NULL,
      FOREIGN KEY (proveedor_id) REFERENCES $proveedoresTable(id)
          ON UPDATE CASCADE
          ON DELETE RESTRICT
    );
  ''');

    await db.execute('''
    CREATE TABLE $detalleComprasTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      compra_id INTEGER NOT NULL,
      producto_id TEXT NOT NULL,
      cantidad INTEGER NOT NULL,
      costo_unitario REAL NOT NULL,
      subtotal REAL NOT NULL,
      FOREIGN KEY (compra_id) REFERENCES $comprasTable(id)
          ON UPDATE CASCADE
          ON DELETE CASCADE,
      FOREIGN KEY (producto_id) REFERENCES $productosTable(id)
          ON UPDATE CASCADE
          ON DELETE RESTRICT
    );
  ''');
  }

  Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Migración de V1 → V2
      // await _migrationV1toV2(db);
    }

    if (oldVersion < 3) {
      // Migración de V2 → V3
      // await _migrationV2toV3(db);
    }

    // Y así sucesivamente...
  }

  // Future<void> _migrationV1toV2(Database db) async {
  //   await db.execute('''
  //     ALTER TABLE $configuracionTable
  //     ADD COLUMN email_tienda TEXT;
  //   ''');
  // }
}
