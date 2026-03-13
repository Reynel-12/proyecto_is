import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_is/model/preferences.dart';

class AccessDeniedDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryButtonText;

  const AccessDeniedDialog({
    super.key,
    this.title = 'Acceso denegado',
    required this.message,
    this.primaryButtonText = 'Entendido',
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<TemaProveedor>(context).esModoOscuro;
    final theme = Theme.of(context);
    final primaryColor = Colors.blueAccent;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 40,
        vertical: isMobile ? 24 : 32,
      ),
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style:
                          theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ) ??
                          TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context)
                      ..pop()
                      ..maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: textColor.withOpacity(0.7),
                    ),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: textColor.withOpacity(0.1)),
              const SizedBox(height: 16),
              Text(
                message,
                style:
                    theme.textTheme.bodyMedium?.copyWith(
                      color: textColor.withOpacity(0.9),
                      height: 1.4,
                    ) ??
                    TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: textColor.withOpacity(0.9),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: isMobile ? double.infinity : null,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                        ..pop()
                        ..maybePop();
                    },
                    child: Text(
                      primaryButtonText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAccessDeniedDialog(
  BuildContext context, {
  required String moduleName,
  String? customMessage,
}) {
  final message =
      customMessage ??
      'No tienes permiso para acceder a $moduleName en esta aplicación. '
          'Si crees que se trata de un error, contacta con el administrador.';

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AccessDeniedDialog(message: message),
  );
}
