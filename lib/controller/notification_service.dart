import 'package:proyecto_is/controller/repository_producto.dart';
import 'package:proyecto_is/model/notifications.dart';
import 'package:proyecto_is/model/producto.dart';

class NotificationService {
  final ProductoRepository _productoRepository = ProductoRepository();

  Future<List<NotificationItem>> getLowStockNotifications(Set<String> dismissedProductIds) async {
    List<NotificationItem> notifications = [];
    try {
      List<Producto> productos = await _productoRepository.getProductosActivos();
      for (Producto producto in productos) {
        if (producto.stock <= producto.stockMinimo && producto.stockMinimo > 0 && !dismissedProductIds.contains(producto.id)) {
          notifications.add(NotificationItem(
            id: 'low_stock_${producto.id}',
            title: 'Stock bajo',
            message: 'El producto "${producto.nombre}" tiene stock bajo (${producto.stock} ${producto.unidadMedida}). Stock mínimo: ${producto.stockMinimo}',
            timestamp: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      // Handle error
    }
    return notifications;
  }
}