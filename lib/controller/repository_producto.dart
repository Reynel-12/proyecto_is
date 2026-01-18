import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/producto.dart';

class ProductoRepository {
  final dbHelper = DBHelper();

  Future<int> insertProducto(Producto producto) async {
    final db = await dbHelper.database;
    return await db.insert('productos', producto.toMap());
  }

  Future<List<Producto>> getProductos() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('productos');

    return maps.map((map) => Producto.fromMap(map)).toList();
  }

  Future<List<Producto>> getProductosActivos() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'estado = ?',
      whereArgs: ['Activo'],
    );

    return maps.map((map) => Producto.fromMap(map)).toList();
  }

  Future<List<Producto>> getProductosByProveedor(int idProveedor) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'proveedor_id = ?',
      whereArgs: [idProveedor],
    );

    return maps.map((map) => Producto.fromMap(map)).toList();
  }

  Future<Producto?> getProductoByID(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'id_producto = ?',
      whereArgs: [id],
    );

    return maps.map((map) => Producto.fromMap(map)).toList().firstOrNull;
  }

  Future<int> updateProducto(Producto producto) async {
    final db = await dbHelper.database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id_producto = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> deleteProducto(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'productos',
      where: 'id_producto = ?',
      whereArgs: [id],
    );
  }

  Future<int> addInventario(String id, int cantidad) async {
    final db = await dbHelper.database;
    return await db.rawUpdate(
      'update productos set stock = stock + $cantidad where id_producto = $id',
    );
  }

  Future<int> editInventario(String id, int cantidad) async {
    final db = await dbHelper.database;
    return await db.update(
      'productos',
      {'stock': cantidad},
      where: 'id_producto = ?',
      whereArgs: [id],
    );
  }
}
