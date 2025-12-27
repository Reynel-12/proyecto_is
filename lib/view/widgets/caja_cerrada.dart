import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_is/model/preferences.dart';

class CajaCerradaScreen extends StatelessWidget {
  const CajaCerradaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;
    return Scaffold(
      backgroundColor: esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono animado de candado
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.08),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 72,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Título principal
                Text(
                  'La caja está cerrada',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.white
                        : Colors.black,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Subtítulo descriptivo
                Text(
                  'No se pueden realizar operaciones hasta que se abra la caja.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.white
                        : Colors.black,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                // const SizedBox(height: 48),

                // // Botón opcional (ej. "Solicitar apertura")
                // SizedBox(
                //   width: double.infinity,
                //   child: OutlinedButton.icon(
                //     onPressed: () {
                //       // Acción opcional: notificar, abrir chat, etc.
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(
                //           content: Text('Solicitud enviada al administrador'),
                //         ),
                //       );
                //     },
                //     icon: const Icon(Icons.support_agent, size: 20),
                //     label: const Text('Solicitar Apertura'),
                //     style: OutlinedButton.styleFrom(
                //       foregroundColor: const Color(0xFF475569),
                //       side: const BorderSide(color: Color(0xFFCBD5E1)),
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //   ),
                // ),

                // const SizedBox(height: 12),

                // // Texto secundario (opcional)
                // TextButton(
                //   onPressed: () => Navigator.of(context).pop(),
                //   child: Text(
                //     'Volver',
                //     style: TextStyle(
                //       color: Colors.grey[500],
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
