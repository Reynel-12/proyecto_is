import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  // Nombres de tablas centralizados
  static const String cajaTable = 'caja';
  static const String proveedoresTable = 'proveedores';
  static const String productosTable = 'productos';
  static const String ventasTable = 'ventas';
  static const String detalleVentasTable = 'detalle_ventas';
  static const String comprasTable = 'compras';
  static const String detalleComprasTable = 'detalle_compras';
  static const String movimientosCajaTable = 'movimientos_caja';
  static const String configuracionSarTable = 'configuracion_sar';
  static const String empresaTable = 'empresa';
  static const String usuariosTable = 'usuarios';
  static const String categoriasTable = 'categorias';
  static const String devolucionesTable = 'devoluciones';
  static const String devolucionDetalleTable = 'devolucion_detalle';
  static const String auditLogsTable = 'audit_logs';

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
      id_proveedor INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      direccion TEXT,
      telefono TEXT,
      correo TEXT,
      fecha_registro TEXT,
      fecha_actualizacion TEXT,
      estado TEXT
    );
  ''');

    await db.execute('''
    CREATE TABLE $productosTable (
      id_producto TEXT PRIMARY KEY,
      nombre TEXT NOT NULL,
      proveedor_id INTEGER,
      categoria_id INTEGER,
      unidad_medida TEXT,
      precio REAL NOT NULL,
      costo REAL NOT NULL,
      stock INTEGER NOT NULL DEFAULT 0,
      stock_minimo INTEGER DEFAULT 0,
      isv REAL NOT NULL DEFAULT 0,
      precio_venta REAL NOT NULL,
      fecha_creacion TEXT,
      fecha_actualizacion TEXT,
      estado TEXT,
      FOREIGN KEY (proveedor_id) REFERENCES $proveedoresTable(id_proveedor)
          ON UPDATE CASCADE
          ON DELETE SET NULL,
      FOREIGN KEY (categoria_id) REFERENCES $categoriasTable(id_categoria)
          ON UPDATE CASCADE
          ON DELETE SET NULL
    );
  ''');

    await db.execute('''
    CREATE TABLE $ventasTable (
    id_venta INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT NOT NULL,
    numero_factura TEXT NOT NULL UNIQUE,
    tipo_documento TEXT NOT NULL DEFAULT 'FACTURA',
    rtn_emisor TEXT NOT NULL,
    razon_social_emisor TEXT NOT NULL,
    rtn_cliente TEXT,
    nombre_cliente TEXT,
    subtotal REAL NOT NULL,
    isv REAL NOT NULL,
    total REAL NOT NULL,
    cai TEXT NOT NULL,
    rango_autorizado TEXT NOT NULL,
    fecha_limite_cai TEXT NOT NULL,
    moneda TEXT NOT NULL DEFAULT 'HNL',
    monto_pagado REAL,
    cambio REAL,
    estado_fiscal TEXT NOT NULL DEFAULT 'EMITIDA',
    cajero TEXT,
    metodo_pago TEXT
    );
  ''');

    await db.execute('''
    CREATE TABLE $detalleVentasTable (
      id_detalle_venta INTEGER PRIMARY KEY AUTOINCREMENT,
      venta_id INTEGER NOT NULL,
      producto_id TEXT NOT NULL,
      descripcion TEXT NOT NULL,
      cantidad INTEGER NOT NULL,
      precio_unitario REAL NOT NULL,
      subtotal REAL NOT NULL,
      isv REAL DEFAULT 0,
      descuento REAL DEFAULT 0,
      FOREIGN KEY (venta_id) REFERENCES $ventasTable(id_venta)
    );
  ''');

    await db.execute('''
    CREATE TABLE $comprasTable (
      id_compra INTEGER PRIMARY KEY AUTOINCREMENT,
      proveedor_id INTEGER NOT NULL,
      fecha TEXT NOT NULL,
      total REAL NOT NULL,
      FOREIGN KEY (proveedor_id) REFERENCES $proveedoresTable(id_proveedor)
          ON UPDATE CASCADE
          ON DELETE RESTRICT
    );
  ''');

    await db.execute('''
    CREATE TABLE $detalleComprasTable (
      id_detalle_compra INTEGER PRIMARY KEY AUTOINCREMENT,
      compra_id INTEGER NOT NULL,
      producto_id TEXT NOT NULL,
      cantidad INTEGER NOT NULL,
      costo_unitario REAL NOT NULL,
      subtotal REAL NOT NULL,
      FOREIGN KEY (compra_id) REFERENCES $comprasTable(id_compra)
          ON UPDATE CASCADE
          ON DELETE CASCADE,
      FOREIGN KEY (producto_id) REFERENCES $productosTable(id_producto)
          ON UPDATE CASCADE
          ON DELETE RESTRICT
    );
  ''');

    await db.execute('''
      CREATE TABLE $cajaTable (
        id_caja INTEGER PRIMARY KEY AUTOINCREMENT,
        cajero_abre TEXT NOT NULL,
        cajero_cierra TEXT NOT NULL,
        fecha_apertura TEXT,
        monto_apertura REAL,
        fecha_cierre TEXT,
        monto_cierre REAL,
        total_ventas REAL,
        total_efectivo REAL,
        ingresos REAL,
        egresos REAL,
        diferencia REAL,
        estado TEXT,
        usuario_id TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE $movimientosCajaTable (
        id_movimiento INTEGER PRIMARY KEY AUTOINCREMENT,
        id_caja INTEGER,
        id_venta INTEGER,
        tipo TEXT,
        concepto TEXT,
        monto REAL,
        metodo_pago TEXT,
        fecha TEXT,
        FOREIGN KEY (id_caja)
          REFERENCES $cajaTable(id_caja)
          ON DELETE CASCADE,
        FOREIGN KEY (id_venta)
          REFERENCES $ventasTable(id_venta)
          ON DELETE SET NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE $configuracionSarTable (
        id_config INTEGER PRIMARY KEY AUTOINCREMENT,
        cai TEXT NOT NULL,
        rango_inicial TEXT NOT NULL,
        rango_final TEXT NOT NULL,
        fecha_limite TEXT NOT NULL,
        numero_actual INTEGER NOT NULL,
        activo INTEGER DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE $empresaTable (
        id_empresa INTEGER PRIMARY KEY,
        rtn TEXT NOT NULL UNIQUE,
        razon_social TEXT NOT NULL,
        nombre_comercial TEXT,
        direccion TEXT,
        telefono TEXT,
        correo TEXT,
        moneda_defecto TEXT DEFAULT 'HNL',
        fecha_creacion TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE $usuariosTable (
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        apellido TEXT NOT NULL,
        telefono TEXT,
        correo TEXT,
        contrasena TEXT NOT NULL,
        tipo TEXT NOT NULL,
        estado TEXT NOT NULL,
        permisos TEXT,
        fecha_creacion TEXT,
        fecha_actualizacion TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE $categoriasTable (
        id_categoria INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        estado TEXT NOT NULL,
        fecha_creacion TEXT,
        fecha_actualizacion TEXT
      );
    ''');

    // Crear tablas de devoluciones
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $devolucionesTable (
        id_devolucion INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER NOT NULL,
        numero_factura TEXT NOT NULL,
        fecha TEXT NOT NULL,
        nombre_usuario TEXT NOT NULL,
        motivo TEXT,
        total_devuelto REAL NOT NULL,
        tipo_reembolso TEXT NOT NULL,
        estado TEXT NOT NULL,
        FOREIGN KEY (venta_id) REFERENCES $ventasTable(id_venta)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $devolucionDetalleTable (
        id_detalle_devolucion INTEGER PRIMARY KEY AUTOINCREMENT,
        devolucion_id INTEGER NOT NULL,
        producto_id TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        estado_producto TEXT NOT NULL,
        FOREIGN KEY (devolucion_id) REFERENCES $devolucionesTable(id_devolucion) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES $productosTable(id_producto)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $auditLogsTable (
        id_audit_log INTEGER PRIMARY KEY AUTOINCREMENT,
        tabla TEXT NOT NULL,
        registro_id TEXT NOT NULL,
        accion TEXT NOT NULL,
        usuario_id TEXT,
        nombre_usuario TEXT,
        fecha TEXT NOT NULL,
        detalles TEXT
      );
    ''');
  }

  Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
    }

    if (oldVersion < 3) {
      // Migración de V2 → V3: agregar columna permisos a usuarios
    }

    // Y así sucesivamente...
  }

  // Future<void> _migrationV1toV2(Database db) async {
  //   // Agregar columna stock_minimo a productos
  //   await db.execute(
  //     'ALTER TABLE $productosTable ADD COLUMN stock_minimo INTEGER DEFAULT 0',
  //   );
  // }
}
