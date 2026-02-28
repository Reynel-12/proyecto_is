import 'package:proyecto_is/controller/repository_caja.dart';
import 'package:proyecto_is/controller/repository_devolucion.dart';
import 'package:proyecto_is/controller/repository_venta.dart';
import 'package:proyecto_is/model/caja.dart';
import 'package:proyecto_is/model/devolucion.dart';
import 'package:proyecto_is/model/devolucion_detalle.dart';
import 'package:proyecto_is/model/venta.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/view/widgets/caja_cerrada.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NuevaDevolucionView extends StatefulWidget {
  const NuevaDevolucionView({super.key});

  @override
  State<NuevaDevolucionView> createState() => _NuevaDevolucionViewState();
}

class _NuevaDevolucionViewState extends State<NuevaDevolucionView> {
  final _searchController = TextEditingController();
  final VentaRepository _repoVenta = VentaRepository();
  final RepositoryDevolucion _repoDevolucion = RepositoryDevolucion();
  final _movimientoRepo = CajaRepository();

  VentaCompleta? _ventaSeleccionada;
  bool _isLoading = false;

  final Map<String, int> _cantidadesDevolver = {};
  final Map<String, String> _condiciones =
      {}; // 'BUENO', 'DEFECTUOSO', 'NO_REINGRESA'
  final Map<String, int> _cantidadesYaDevueltas = {};

  String _tipoReembolso = 'Efectivo';
  final _motivoGlobalController = TextEditingController();
  Caja? _cajaSeleccionada;

  @override
  void dispose() {
    _searchController.dispose();
    _motivoGlobalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _movimientoRepo.obtenerCajaAbierta().then((caja) {
      if (mounted) setState(() => _cajaSeleccionada = caja);
    });
  }

  Future<void> _buscarVenta() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _ventaSeleccionada = null;
      _cantidadesDevolver.clear();
      _condiciones.clear();
      _cantidadesYaDevueltas.clear();
    });

    try {
      String facturaId = _searchController.text.trim();
      final venta = await _repoVenta.getVentaCompletaByFactura(facturaId);

      if (venta != null) {
        for (var item in venta.detalles) {
          final yaDevuelto = await _repoDevolucion.getCantidadDevuelta(
            facturaId,
            item.id,
          );
          _cantidadesYaDevueltas[item.id] = yaDevuelto;
        }
        setState(() => _ventaSeleccionada = venta);
      } else {
        _mostrarMensaje("Atención", "Venta no encontrada", ContentType.warning);
      }
    } catch (e) {
      _mostrarMensaje("Error", "Error al buscar venta", ContentType.failure);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _incrementarCantidad(String productoId, int max) {
    final current = _cantidadesDevolver[productoId] ?? 0;
    if (current < max) {
      setState(() {
        _cantidadesDevolver[productoId] = current + 1;
        if (!_condiciones.containsKey(productoId))
          _condiciones[productoId] = 'BUENO';
      });
    }
  }

  void _decrementarCantidad(String productoId) {
    final current = _cantidadesDevolver[productoId] ?? 0;
    if (current > 0) {
      setState(() {
        _cantidadesDevolver[productoId] = current - 1;
        if (_cantidadesDevolver[productoId] == 0)
          _condiciones.remove(productoId);
      });
    }
  }

  double get totalDevolucion {
    if (_ventaSeleccionada == null) return 0.0;
    double total = 0;
    for (var item in _ventaSeleccionada!.detalles) {
      final qty = _cantidadesDevolver[item.id] ?? 0;
      if (qty > 0) {
        double precioReal = item.precio;
        if (item.cantidad > 0 && item.descuento > 0) {
          precioReal = item.precio - (item.descuento / item.cantidad);
        }
        total += (precioReal * qty);
      }
    }
    return total;
  }

  Future<void> _procesarDevolucion() async {
    if (_ventaSeleccionada == null) return;

    bool hayItems = _cantidadesDevolver.values.any((v) => v > 0);
    if (!hayItems) {
      _mostrarMensaje(
        "Atención",
        "Seleccione al menos un producto",
        ContentType.warning,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final screenSize = MediaQuery.of(ctx).size;
        final bool isMobileCtx = screenSize.width < 600;
        final bool isTabletCtx =
            screenSize.width >= 600 && screenSize.width < 900;
        final double dialogWidth = isMobileCtx
            ? screenSize.width * 0.92
            : (isTabletCtx ? 480.0 : 520.0);

        final isDark = Provider.of<TemaProveedor>(
          ctx,
          listen: false,
        ).esModoOscuro;
        final bgCard = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final bgDialog = isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFDCDCDC);
        final txtColor = isDark ? Colors.white : Colors.black;
        final subTxtColor = isDark ? Colors.white60 : Colors.black54;

        final int itemsADevolver = _cantidadesDevolver.values
            .where((v) => v > 0)
            .length;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobileCtx ? 16 : (screenSize.width - dialogWidth) / 2,
            vertical: 24,
          ),
          child: Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              color: bgDialog,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header con gradiente ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_return_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Confirmar Devolución',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Esta acción actualizará el inventario y la caja',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // ── Cuerpo con resumen ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de resumen
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Column(
                          children: [
                            _dialogInfoRow(
                              icon: Icons.receipt_long,
                              label: 'Factura',
                              value: _ventaSeleccionada!.numeroFactura,
                              iconColor: Colors.blueAccent,
                              txtColor: txtColor,
                              subTxtColor: subTxtColor,
                            ),
                            Divider(
                              height: 20,
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                            _dialogInfoRow(
                              icon: Icons.inventory_2_outlined,
                              label: 'Productos a devolver',
                              value: '$itemsADevolver producto(s)',
                              iconColor: const Color(0xFFFF6B35),
                              txtColor: txtColor,
                              subTxtColor: subTxtColor,
                            ),
                            Divider(
                              height: 20,
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                            _dialogInfoRow(
                              icon: Icons.payments_outlined,
                              label: 'Total a reembolsar',
                              value: 'L. ${totalDevolucion.toStringAsFixed(2)}',
                              iconColor: Colors.green,
                              txtColor: txtColor,
                              subTxtColor: subTxtColor,
                              valueBold: true,
                              valueColor: Colors.green,
                            ),
                            Divider(
                              height: 20,
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                            _dialogInfoRow(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Tipo de reembolso',
                              value: _tipoReembolso,
                              iconColor: Colors.purple,
                              txtColor: txtColor,
                              subTxtColor: subTxtColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Botones ───────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: txtColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B35),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Confirmar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      List<DevolucionDetalle> detalles = [];
      for (var item in _ventaSeleccionada!.detalles) {
        final qty = _cantidadesDevolver[item.id] ?? 0;
        if (qty > 0) {
          double precioReal = item.precio;
          if (item.cantidad > 0 && item.descuento > 0) {
            precioReal = item.precio - (item.descuento / item.cantidad);
          }
          detalles.add(
            DevolucionDetalle(
              productoId: item.id,
              cantidad: qty,
              precioUnitario: precioReal,
              subtotal: precioReal * qty,
              estadoProducto: _condiciones[item.id] ?? 'BUENO',
            ),
          );
        }
      }

      final prefs = await SharedPreferences.getInstance();
      String? nombreUsuario = prefs.getString('user_fullname');
      String? userId = prefs.getString('user');

      final devolucion = Devolucion(
        ventaId: _ventaSeleccionada!.id,
        numeroFactura: _ventaSeleccionada!.numeroFactura,
        fecha: DateTime.now().toIso8601String(),
        nombreUsuario: nombreUsuario ?? 'Desconocido',
        motivo: _motivoGlobalController.text,
        totalDevuelto: totalDevolucion,
        tipoReembolso: _tipoReembolso,
        idUsuario: userId ?? '',
        estado: 'COMPLETADA',
      );

      await _repoDevolucion.createDevolucion(devolucion, detalles);
      _mostrarMensaje(
        "Éxito",
        "Devolución registrada correctamente",
        ContentType.success,
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarMensaje("Error", "Fallo al registrar: $e", ContentType.failure);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _dialogInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color txtColor,
    required Color subTxtColor,
    bool valueBold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: subTxtColor, fontSize: 11)),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? txtColor,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarMensaje(String title, String message, ContentType contentType) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: title,
          message: message,
          contentType: contentType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<TemaProveedor>(context);
    final isDarkMode = themeProvider.esModoOscuro;
    final backgroundColor = isDarkMode ? Colors.black : const Color(0xFFF4F3F3);
    final textColor = isDarkMode ? Colors.white : Colors.black;

    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = screenSize.width >= 900;
    final bool isMobile = screenSize.width < 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Nueva devolución',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: _cajaSeleccionada == null
          ? const CajaCerradaScreen()
          : SafeArea(
              child: isDesktop
                  ? _buildDesktopLayout(isDarkMode, textColor, backgroundColor)
                  : _buildMobileLayout(isDarkMode, textColor, backgroundColor),
            ),
    );
  }

  Widget _buildSearchArea(bool isDarkMode, Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Número de factura...',
                hintStyle: TextStyle(color: textColor.withAlpha(100)),
                prefixIcon: Icon(Icons.search, color: textColor.withAlpha(150)),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: textColor.withAlpha(30)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _buscarVenta(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _buscarVenta,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Buscar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool isDarkMode, Color textColor, Color bgColor) {
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _buildSearchArea(isDarkMode, textColor, cardColor),
        ),
        if (_ventaSeleccionada != null) ...[
          Expanded(
            child: _buildMainContent(isDarkMode, textColor, cardColor, bgColor),
          ),
          _buildSummaryPanel(isDarkMode, textColor, cardColor, bgColor),
        ] else if (!_isLoading)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: textColor.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Busque una factura para comenzar",
                    style: TextStyle(
                      color: textColor.withAlpha(150),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDarkMode, Color textColor, Color bgColor) {
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildSearchArea(isDarkMode, textColor, cardColor),
          const SizedBox(height: 24),
          if (_ventaSeleccionada != null)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildMainContent(
                      isDarkMode,
                      textColor,
                      cardColor,
                      bgColor,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: _buildSummaryPanel(
                      isDarkMode,
                      textColor,
                      cardColor,
                      bgColor,
                      isDesktop: true,
                    ),
                  ),
                ],
              ),
            )
          else if (!_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 100,
                      color: textColor.withAlpha(50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Busque una factura para comenzar",
                      style: TextStyle(
                        color: textColor.withAlpha(150),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    bool isDarkMode,
    Color textColor,
    Color cardColor,
    Color bgColor,
  ) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _buildSaleHero(isDarkMode, textColor, cardColor),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "Productos vendidos",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._ventaSeleccionada!.detalles.map((item) {
          final yaDevuelto = _cantidadesYaDevueltas[item.id] ?? 0;
          final disponible = item.cantidad - yaDevuelto;
          final aDevolver = _cantidadesDevolver[item.id] ?? 0;

          return _buildProductCard(
            item,
            aDevolver,
            disponible,
            yaDevuelto,
            isDarkMode,
            textColor,
            cardColor,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSaleHero(bool isDarkMode, Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withAlpha(isDarkMode ? 40 : 20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.receipt, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Factura: ${_ventaSeleccionada!.numeroFactura}",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Cliente: ${_ventaSeleccionada!.nombreCliente}",
                  style: TextStyle(
                    color: textColor.withAlpha(180),
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Fecha: ${_ventaSeleccionada!.fecha.substring(0, 10)}",
                  style: TextStyle(
                    color: textColor.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Total venta",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                "L. ${_ventaSeleccionada!.total.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    DetalleItem item,
    int aDevolver,
    int disponible,
    int yaDevuelto,
    bool isDarkMode,
    Color textColor,
    Color cardColor,
  ) {
    double subtotal = 0;
    final qty = aDevolver;
    if (qty > 0) {
      double precioReal = item.precio;
      if (item.cantidad > 0 && item.descuento > 0) {
        precioReal = item.precio - (item.descuento / item.cantidad);
      }
      subtotal += (precioReal * qty);
    }

    double descuento = (item.descuento / (item.cantidad * item.precio)) * 100;

    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: textColor.withAlpha(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueAccent.withAlpha(30),
                  child: Text(
                    item.producto[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.producto,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "Precio Unit: L. ${item.precio.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: textColor.withAlpha(150),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "Descuento: ${descuento.toStringAsFixed(0)}%",
                        style: TextStyle(
                          color: textColor.withAlpha(150),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQuantitySelector(
                  item.id,
                  aDevolver,
                  disponible,
                  textColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildMiniBadge("Vendidos: ${item.cantidad}", Colors.grey),
                    const SizedBox(width: 8),
                    if (yaDevuelto > 0)
                      _buildMiniBadge("Devueltos: $yaDevuelto", Colors.orange),
                    const SizedBox(width: 8),
                    _buildMiniBadge("Disp: $disponible", Colors.green),
                  ],
                ),
                if (aDevolver > 0)
                  Text(
                    "Subtotal: L. ${(subtotal).toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
              ],
            ),
            if (aDevolver > 0) ...[
              const Divider(height: 24),
              _buildConditionSelector(item.id, isDarkMode, textColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(
    String id,
    int current,
    int max,
    Color textColor,
  ) {
    return Row(
      children: [
        _roundIconButton(
          Icons.remove,
          Colors.redAccent,
          current > 0 ? () => _decrementarCantidad(id) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "$current",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        _roundIconButton(
          Icons.add,
          Colors.green,
          current < max ? () => _incrementarCantidad(id, max) : null,
        ),
      ],
    );
  }

  Widget _roundIconButton(IconData icon, Color color, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: onTap == null
                  ? Colors.grey.withAlpha(50)
                  : color.withAlpha(100),
            ),
            color: onTap == null ? Colors.transparent : color.withAlpha(10),
          ),
          child: Icon(
            icon,
            color: onTap == null ? Colors.grey.withAlpha(100) : color,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildConditionSelector(String id, bool isDarkMode, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Estado del producto devuelto:",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _conditionChip(id, 'BUENO', 'Bueno', Colors.green),
            _conditionChip(id, 'DEFECTUOSO', 'Dañado', Colors.orange),
            _conditionChip(id, 'NO_REINGRESA', 'Pérdida', Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _conditionChip(
    String productId,
    String value,
    String label,
    Color color,
  ) {
    final selected = _condiciones[productId] == value;
    return GestureDetector(
      onTap: () => setState(() => _condiciones[productId] = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : color.withAlpha(50)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPanel(
    bool isDarkMode,
    Color textColor,
    Color cardColor,
    Color bgColor, {
    bool isDesktop = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: isDesktop
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: isDesktop
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _motivoGlobalController,
            style: TextStyle(color: textColor),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Motivo general',
              labelStyle: TextStyle(color: textColor.withAlpha(150)),
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(
            "Reembolso",
            _tipoReembolso,
            isDropdown: true,
            textColor: textColor,
            cardColor: cardColor,
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total a devolver",
                style: TextStyle(color: textColor.withAlpha(150), fontSize: 16),
              ),
              Text(
                "L. ${totalDevolucion.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _procesarDevolucion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              child: const Text(
                "PROCESAR DEVOLUCIÓN",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDropdown = false,
    required Color textColor,
    required Color cardColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        if (isDropdown)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: value,
              items: const [
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                DropdownMenuItem(
                  value: 'Transferencia',
                  child: Text('Transferencia'),
                ),
              ],
              onChanged: (v) => setState(() => _tipoReembolso = v!),
              underline: const SizedBox(),
              dropdownColor: cardColor,
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
