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

  Future<int> updateProducto(Producto producto) async {
    final db = await dbHelper.database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> deleteProducto(String id) async {
    final db = await dbHelper.database;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }
}
