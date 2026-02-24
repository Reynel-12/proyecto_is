import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_is/model/preferences.dart';

class NotificationBanner extends StatelessWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final notifications = notificationProvider.notifications;
        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        final screenSize = MediaQuery.of(context).size;
        final bool isMobile = screenSize.width < 600;
        final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.0 : (isTablet ? 20.0 : 24.0),
            vertical: 8.0,
          ),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.red[900]
                : Colors.red[50],
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.red[700]!
                  : Colors.red[200]!,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.red[300]
                            : Colors.red[700],
                        size: 24.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Notificaciones de Stock Bajo',
                        style: TextStyle(
                          fontSize: isMobile ? 16.0 : (isTablet ? 18.0 : 20.0),
                          fontWeight: FontWeight.bold,
                          color: Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black87,
                          size: 20.0,
                        ),
                        onPressed: () => notificationProvider.loadNotifications(),
                        tooltip: 'Refrescar notificaciones',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.clear_all,
                          color: Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black87,
                          size: 20.0,
                        ),
                        onPressed: () => notificationProvider.dismissAllNotifications(),
                        tooltip: 'Descartar todas las notificaciones',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              ...notifications.map((notification) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: isMobile ? 14.0 : (isTablet ? 15.0 : 16.0),
                              color: Provider.of<TemaProveedor>(context).esModoOscuro
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white70
                                : Colors.black54,
                            size: 18.0,
                          ),
                          onPressed: () {
                            final productId = notification.id.replaceFirst('low_stock_', '');
                            notificationProvider.dismissNotification(productId);
                          },
                          tooltip: 'Descartar esta notificación',
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}