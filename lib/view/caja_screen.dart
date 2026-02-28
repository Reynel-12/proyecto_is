import 'package:proyecto_is/view/widgets/modal_print_movil.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_is/controller/repository_caja.dart';
import 'package:proyecto_is/model/app_logger.dart';
import 'package:proyecto_is/model/caja.dart';
import 'package:proyecto_is/model/movimiento_caja.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_is/controller/repository_empresa.dart';
import 'package:proyecto_is/model/permissions.dart';
import 'package:proyecto_is/view/widgets/caja_pdf_preview.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen>
    with SingleTickerProviderStateMixin {
  final CajaRepository _cajaRepository = CajaRepository();
  final AppLogger _logger = AppLogger.instance;
  Caja? _cajaActual;
  List<MovimientoCaja> _movimientos = [];
  bool _isLoading = true;
  late TabController _tabController;

  // History filters
  String _filtroHistorial = 'Todo';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<Caja> _historialCajas = [];

  final _formKey = GlobalKey<FormState>();
  final List<String> _metodosPago = ['Efectivo', 'Tarjeta', 'Transferencia'];
  String _metodoPago = 'Efectivo';

  // Totales por método de pago
  double _totalTarjeta = 0.0;
  double _totalTransferencia = 0.0;
  double _totalEfectivoVentas = 0.0;

  // Desglose de devoluciones
  double _totalDevolucionesEfectivo = 0.0;
  double _totalDevolucionesTarjeta = 0.0;
  double _totalDevolucionesTransferencia = 0.0;

  // Desglose de Ingresos
  double _totalIngresosEfectivo = 0.0;
  double _totalIngresosTarjeta = 0.0;
  double _totalIngresosTransferencia = 0.0;

  // Desglose de Egresos
  double _totalEgresosEfectivo = 0.0;
  double _totalEgresosTarjeta = 0.0;
  double _totalEgresosTransferencia = 0.0;

  double diferencia = 0.0;

  String _filtroMetodoPago = 'Todo';
  @override
  void initState() {
    super.initState();
    _checkPermission();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _checkPermission() async {
    final prefs = await SharedPreferences.getInstance();
    String? perms = prefs.getString('permisos');
    bool ok = false;
    if (perms != null && perms.isNotEmpty) {
      try {
        List<String> list = List<String>.from(jsonDecode(perms));
        ok = list.contains(Permission.caja);
      } catch (_) {}
    }
    if (!ok) {
      if (!mounted) return;
      _mostrarAccesoDenegado();
    }
  }

  void _mostrarAccesoDenegado() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Acceso denegado'),
        content: const Text('No tienes permiso para acceder a Caja'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                ..pop()
                ..maybePop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() => _isLoading = true);
      final caja = await _cajaRepository.obtenerCajaAbierta();
      if (caja != null) {
        final movimientos = await _cajaRepository.obtenerMovimientos(caja.id!);

        // Calcular totales por método de pago
        double tarjeta = 0.0;
        double transferencia = 0.0;
        double efectivoVentas = 0.0;

        double devolucionesEfectivo = 0.0;
        double devolucionesTarjeta = 0.0;
        double devolucionesTransferencia = 0.0;

        double ingresosEfectivo = 0.0;
        double ingresosTarjeta = 0.0;
        double ingresosTransferencia = 0.0;

        double egresosEfectivo = 0.0;
        double egresosTarjeta = 0.0;
        double egresosTransferencia = 0.0;

        for (var mov in movimientos) {
          if (mov.tipo == 'Venta') {
            if (mov.metodoPago == 'Tarjeta') {
              tarjeta += mov.monto;
            } else if (mov.metodoPago == 'Transferencia') {
              transferencia += mov.monto;
            } else if (mov.metodoPago == 'Efectivo') {
              efectivoVentas += mov.monto;
            }
          } else if (mov.tipo == 'Ingreso') {
            if (mov.metodoPago == 'Tarjeta') {
              ingresosTarjeta += mov.monto;
            } else if (mov.metodoPago == 'Transferencia') {
              ingresosTransferencia += mov.monto;
            } else if (mov.metodoPago == 'Efectivo') {
              ingresosEfectivo += mov.monto;
            }
          } else if (mov.tipo == 'Egreso') {
            if (mov.metodoPago == 'Tarjeta') {
              egresosTarjeta += mov.monto;
            } else if (mov.metodoPago == 'Transferencia') {
              egresosTransferencia += mov.monto;
            } else if (mov.metodoPago == 'Efectivo') {
              egresosEfectivo += mov.monto;
            }
          }

          if (mov.tipo == 'Devolucion') {
            if (mov.metodoPago == 'Tarjeta') {
              devolucionesTarjeta += mov.monto;
            } else if (mov.metodoPago == 'Transferencia') {
              devolucionesTransferencia += mov.monto;
            } else if (mov.metodoPago == 'Efectivo') {
              devolucionesEfectivo += mov.monto;
            }
          }
        }

        final double totalEfectivoCalculado =
            caja.montoApertura +
            efectivoVentas +
            ingresosEfectivo -
            egresosEfectivo;

        setState(() {
          _cajaActual = Caja(
            id: caja.id,
            cajeroAbre: caja.cajeroAbre,
            cajeroCierra: caja.cajeroCierra,
            fechaApertura: caja.fechaApertura,
            montoApertura: caja.montoApertura,
            fechaCierre: caja.fechaCierre,
            montoCierre: caja.montoCierre,
            totalVentas: caja.totalVentas,
            totalEfectivo: totalEfectivoCalculado,
            ingresos: caja.ingresos,
            egresos: caja.egresos,
            diferencia: caja.diferencia,
            estado: caja.estado,
          );
          _movimientos = movimientos;
          _totalTarjeta = tarjeta;
          _totalTransferencia = transferencia;
          _totalEfectivoVentas = efectivoVentas;

          _totalDevolucionesEfectivo = devolucionesEfectivo;
          _totalDevolucionesTarjeta = devolucionesTarjeta;
          _totalDevolucionesTransferencia = devolucionesTransferencia;

          _totalIngresosEfectivo = ingresosEfectivo;
          _totalIngresosTarjeta = ingresosTarjeta;
          _totalIngresosTransferencia = ingresosTransferencia;

          _totalEgresosEfectivo = egresosEfectivo;
          _totalEgresosTarjeta = egresosTarjeta;
          _totalEgresosTransferencia = egresosTransferencia;

          _isLoading = false;
        });
      } else {
        setState(() {
          _cajaActual = null;
          _movimientos = [];
          _totalTarjeta = 0.0;
          _totalTransferencia = 0.0;
          _totalEfectivoVentas = 0.0;

          _totalIngresosEfectivo = 0.0;
          _totalIngresosTarjeta = 0.0;
          _totalIngresosTransferencia = 0.0;

          _totalEgresosEfectivo = 0.0;
          _totalEgresosTarjeta = 0.0;
          _totalEgresosTransferencia = 0.0;

          _isLoading = false;
        });
      }
      _cargarHistorial();
    } catch (e, st) {
      _logger.log.e('Error al cargar datos', error: e, stackTrace: st);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarHistorial() async {
    try {
      diferencia = 0.0;
      final historial = await _cajaRepository.obtenerHistorialCajas(
        filtro: _filtroHistorial,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
      setState(() {
        _historialCajas = historial;
        for (var h in _historialCajas) {
          diferencia += h.diferencia ?? 0.0;
        }
      });
    } catch (e, st) {
      _logger.log.e('Error al cargar historial', error: e, stackTrace: st);
    }
  }

  Future<void> _abrirCaja() async {
    final montoController = TextEditingController();
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del diálogo según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Color.fromRGBO(60, 60, 60, 1)
            : Color.fromRGBO(220, 220, 220, 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? (screenSize.width - dialogWidth) / 2 : 24.0,
          vertical: 24.0,
        ),
        title: Container(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          decoration: BoxDecoration(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Color.fromRGBO(60, 60, 60, 1)
                : Color.fromRGBO(220, 220, 220, 1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_open,
                size: isMobile ? 20.0 : 24.0,
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? Colors.white
                    : Colors.black,
              ),
              SizedBox(width: 8),
              Text(
                'Abrir caja',
                style: TextStyle(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: Container(
          width: dialogWidth,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: montoController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Monto inicial',
                      labelStyle: TextStyle(
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                        fontSize: isMobile ? 14.0 : 16.0,
                      ),
                      hintText: 'Ingrese el monto',
                      filled: true,
                      fillColor:
                          Provider.of<TemaProveedor>(context).esModoOscuro
                          ? const Color.fromRGBO(30, 30, 30, 1)
                          : const Color.fromRGBO(244, 243, 243, 1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.money,
                        size: isMobile ? 20.0 : 22.0,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      errorStyle: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12.0 : 16.0,
                        horizontal: isMobile ? 12.0 : 16.0,
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, ingrese el monto';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 16.0,
          vertical: isMobile ? 8.0 : 12.0,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: isMobile ? 8.0 : 12.0,
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final monto = double.tryParse(montoController.text);
              if (monto != null) {
                try {
                  final resultado = await _cajaRepository.abrirCaja(monto);
                  if (resultado == -2) {
                    // El usuario ya tiene una caja abierta
                    if (context.mounted) {
                      Navigator.pop(context);
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.warning,
                        animType: AnimType.scale,
                        title: 'Caja ya abierta',
                        desc:
                            'Ya tienes una caja abierta. No puedes abrir más de una caja a la vez.',
                        btnOkText: 'Entendido',
                        btnOkOnPress: () {},
                      ).show();
                    }
                  } else if (resultado == -1) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.error,
                        animType: AnimType.scale,
                        title: 'Error',
                        desc: 'No se pudo abrir la caja. Verifica tu sesión.',
                        btnOkText: 'Aceptar',
                        btnOkOnPress: () {},
                      ).show();
                    }
                  } else {
                    if (context.mounted) Navigator.pop(context);
                    _cargarDatos();
                  }
                } catch (e, st) {
                  _logger.log.e(
                    'Error al abrir caja',
                    error: e,
                    stackTrace: st,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: isMobile ? 8.0 : 12.0,
              ),
            ),
            child: const Text('Abrir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarCaja() async {
    if (_cajaActual == null) return;
    final montoRealController = TextEditingController();
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del diálogo según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);
    await showDialog(
      context: context,
      builder: (context) {
        double esperado = _cajaActual!.totalEfectivo;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double real = double.tryParse(montoRealController.text) ?? 0.0;
            double diferencia = real - esperado;
            String estadoDif = diferencia == 0
                ? 'Exacto'
                : diferencia > 0
                ? 'Sobrante'
                : 'Faltante';
            Color colorDif = diferencia == 0
                ? Colors.green
                : diferencia > 0
                ? Colors.blue
                : Colors.red;

            return AlertDialog(
              backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(60, 60, 60, 1)
                  : Color.fromRGBO(220, 220, 220, 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isDesktop
                    ? (screenSize.width - dialogWidth) / 2
                    : 24.0,
                vertical: 24.0,
              ),
              title: Container(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                decoration: BoxDecoration(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Color.fromRGBO(60, 60, 60, 1)
                      : Color.fromRGBO(220, 220, 220, 1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.close,
                      size: isMobile ? 20.0 : 24.0,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Cerrar Caja',
                      style: TextStyle(
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                        fontSize: isMobile ? 18.0 : 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              content: Container(
                width: dialogWidth,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Esperado en caja: ${NumberFormat.currency(symbol: 'L. ').format(esperado)}',
                          style: TextStyle(
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white70
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: montoRealController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                          decoration: InputDecoration(
                            labelText: 'Monto real en caja',
                            labelStyle: TextStyle(
                              color:
                                  Provider.of<TemaProveedor>(
                                    context,
                                  ).esModoOscuro
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: isMobile ? 14.0 : 16.0,
                            ),
                            hintText: 'Ingrese el monto',
                            filled: true,
                            fillColor:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? const Color.fromRGBO(30, 30, 30, 1)
                                : const Color.fromRGBO(244, 243, 243, 1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    Provider.of<TemaProveedor>(
                                      context,
                                    ).esModoOscuro
                                    ? Colors.white
                                    : Colors.black,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.description,
                              size: isMobile ? 20.0 : 22.0,
                              color:
                                  Provider.of<TemaProveedor>(
                                    context,
                                  ).esModoOscuro
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 2.0,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 2.0,
                              ),
                            ),
                            errorStyle: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12.0 : 16.0,
                              horizontal: isMobile ? 12.0 : 16.0,
                            ),
                          ),
                          onChanged: (val) => setStateDialog(() {}),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Por favor, ingrese el monto';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Diferencia: ${NumberFormat.currency(symbol: 'L. ').format(diferencia)} ($estadoDif)',
                          style: TextStyle(
                            color: colorDif,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12.0 : 16.0,
                vertical: isMobile ? 8.0 : 12.0,
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : 24.0,
                      vertical: isMobile ? 8.0 : 12.0,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final montoFinal = double.tryParse(
                      montoRealController.text,
                    );
                    if (montoFinal != null) {
                      try {
                        await _cajaRepository.cerrarCaja(
                          _cajaActual!,
                          montoFinal,
                          diferencia,
                        );
                        // Guardamos referencia para el reporte
                        final cajaCerrada = _cajaActual!.copyWith(
                          montoCierre: montoFinal,
                          fechaCierre: DateTime.now().toIso8601String(),
                          diferencia: diferencia,
                          estado: 'Cerrada',
                        );

                        _cargarDatos();

                        if (context.mounted) {
                          // Mostrar el modal y esperar la respuesta
                          final bool? shouldPrint =
                              await EnhancedConfirmationModalPrintMovil.show(
                                context: context,
                                title:
                                    'Reporte de cierre \n¿Deseas generar PDF?',
                                confirmText: 'Confirmar',
                                cancelText: 'Cancelar',
                                icon: Icons.print,
                                accentColor: Colors.blueAccent,
                              );

                          // Si el usuario confirmó, navegar a la pantalla de impresión
                          if (shouldPrint == true) {
                            try {
                              // Navigator.pop(context); // This was already done at 634
                              final movimientos = await _cajaRepository
                                  .obtenerMovimientos(cajaCerrada.id!);
                              final empresaRepo = RepositoryEmpresa();
                              final empresa = await empresaRepo.getEmpresa();

                              if (context.mounted) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CajaPdfPreview(
                                      caja: cajaCerrada,
                                      movimientos: movimientos,
                                      empresa: empresa,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al preparar vista previa: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                          if (context.mounted) Navigator.pop(context);
                        }
                      } catch (e, st) {
                        _logger.log.e(
                          'Error al cerrar caja',
                          error: e,
                          stackTrace: st,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16.0 : 24.0,
                      vertical: isMobile ? 8.0 : 12.0,
                    ),
                  ),
                  child: const Text(
                    'Cerrar Caja',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _registrarMovimiento(String tipo) async {
    if (_cajaActual == null) return;
    final conceptoController = TextEditingController();
    final montoController = TextEditingController();

    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del diálogo según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);

    final icon = tipo == 'Ingreso'
        ? Icons.add_circle_outline
        : Icons.remove_circle_outline;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Color.fromRGBO(60, 60, 60, 1)
            : Color.fromRGBO(220, 220, 220, 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? (screenSize.width - dialogWidth) / 2 : 24.0,
          vertical: 24.0,
        ),
        title: Container(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          decoration: BoxDecoration(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Color.fromRGBO(60, 60, 60, 1)
                : Color.fromRGBO(220, 220, 220, 1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: isMobile ? 20.0 : 24.0,
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? Colors.white
                    : Colors.black,
              ),
              SizedBox(width: 8),
              Text(
                'Registrar $tipo',
                style: TextStyle(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: Container(
          width: dialogWidth,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    maxLines: 3,
                    controller: conceptoController,
                    style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                    decoration: InputDecoration(
                      labelText: 'Concepto',
                      labelStyle: TextStyle(
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                        fontSize: isMobile ? 14.0 : 16.0,
                      ),
                      hintText: 'Ingrese el concepto',
                      filled: true,
                      fillColor:
                          Provider.of<TemaProveedor>(context).esModoOscuro
                          ? const Color.fromRGBO(30, 30, 30, 1)
                          : const Color.fromRGBO(244, 243, 243, 1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.description,
                        size: isMobile ? 20.0 : 22.0,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      errorStyle: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12.0 : 16.0,
                        horizontal: isMobile ? 12.0 : 16.0,
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, ingrese el concepto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: montoController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      labelStyle: TextStyle(
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                        fontSize: isMobile ? 14.0 : 16.0,
                      ),
                      hintText: 'Ingrese el monto',
                      filled: true,
                      fillColor:
                          Provider.of<TemaProveedor>(context).esModoOscuro
                          ? const Color.fromRGBO(30, 30, 30, 1)
                          : const Color.fromRGBO(244, 243, 243, 1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.money,
                        size: isMobile ? 20.0 : 22.0,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      errorStyle: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12.0 : 16.0,
                        horizontal: isMobile ? 12.0 : 16.0,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, ingrese el monto';
                      } else if (value.contains('-')) {
                        return 'Por favor, ingrese un número positivo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownMetodoPago(
                    value: _metodoPago,
                    items: _metodosPago,
                    label: 'Método de pago',
                    icon: Icons.payment,
                    onChanged: (value) {
                      setState(() {
                        _metodoPago = value!;
                      });
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, seleccione un método de pago';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 16.0,
          vertical: isMobile ? 8.0 : 12.0,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: isMobile ? 8.0 : 12.0,
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final monto = double.tryParse(montoController.text);
              if (monto != null && conceptoController.text.isNotEmpty) {
                try {
                  final mov = MovimientoCaja(
                    idCaja: _cajaActual!.id!,
                    tipo: tipo,
                    concepto: conceptoController.text,
                    monto: monto,
                    metodoPago: _metodoPago,
                    fecha: DateTime.now().toIso8601String(),
                  );
                  await _cajaRepository.registrarMovimiento(mov);
                  Navigator.pop(context);
                  _cargarDatos();
                } catch (e, st) {
                  _logger.log.e(
                    'Error al registrar movimiento',
                    error: e,
                    stackTrace: st,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: isMobile ? 8.0 : 12.0,
              ),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _editarMovimiento(MovimientoCaja mov) async {
    final conceptoController = TextEditingController(text: mov.concepto);
    final montoController = TextEditingController(text: mov.monto.toString());
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del diálogo según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Color.fromRGBO(60, 60, 60, 1)
            : Color.fromRGBO(220, 220, 220, 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? (screenSize.width - dialogWidth) / 2 : 24.0,
          vertical: 24.0,
        ),
        title: Container(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          decoration: BoxDecoration(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Color.fromRGBO(60, 60, 60, 1)
                : Color.fromRGBO(220, 220, 220, 1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.edit,
                size: isMobile ? 20.0 : 24.0,
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? Colors.white
                    : Colors.black,
              ),
              SizedBox(width: 8),
              Text(
                'Editar ${mov.tipo}',
                style: TextStyle(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: Container(
          width: dialogWidth,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: conceptoController,
                    style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Concepto',
                      labelStyle: TextStyle(
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                        fontSize: isMobile ? 14.0 : 16.0,
                      ),
                      hintText: 'Ingrese el concepto',
                      filled: true,
                      fillColor:
                          Provider.of<TemaProveedor>(context).esModoOscuro
                          ? const Color.fromRGBO(30, 30, 30, 1)
                          : const Color.fromRGBO(244, 243, 243, 1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.description,
                        size: isMobile ? 20.0 : 22.0,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      errorStyle: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12.0 : 16.0,
                        horizontal: isMobile ? 12.0 : 16.0,
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, ingrese el concepto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: montoController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      labelStyle: TextStyle(
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                        fontSize: isMobile ? 14.0 : 16.0,
                      ),
                      hintText: 'Ingrese el monto',
                      filled: true,
                      fillColor:
                          Provider.of<TemaProveedor>(context).esModoOscuro
                          ? const Color.fromRGBO(30, 30, 30, 1)
                          : const Color.fromRGBO(244, 243, 243, 1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.money,
                        size: isMobile ? 20.0 : 22.0,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 2.0,
                        ),
                      ),
                      errorStyle: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12.0 : 16.0,
                        horizontal: isMobile ? 12.0 : 16.0,
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, ingrese el monto';
                      } else if (value.contains('-')) {
                        return 'Por favor, ingrese un número positivo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownMetodoPago(
                    value: _metodoPago,
                    items: _metodosPago,
                    label: 'Método de pago',
                    icon: Icons.payment,
                    onChanged: (value) {
                      setState(() {
                        _metodoPago = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 16.0,
          vertical: isMobile ? 8.0 : 12.0,
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: isMobile ? 8.0 : 12.0,
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final monto = double.tryParse(montoController.text);
              if (monto != null && conceptoController.text.isNotEmpty) {
                try {
                  final movEditado = MovimientoCaja(
                    id: mov.id,
                    idCaja: mov.idCaja,
                    idVenta: mov.idVenta,
                    tipo: mov.tipo,
                    concepto: conceptoController.text,
                    monto: monto,
                    metodoPago: _metodoPago,
                    fecha: mov.fecha,
                  );
                  await _cajaRepository.editarMovimiento(movEditado);
                  Navigator.pop(context);
                  _cargarDatos();
                } catch (e, st) {
                  _logger.log.e(
                    'Error al editar movimiento',
                    error: e,
                    stackTrace: st,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 24.0,
                vertical: isMobile ? 8.0 : 12.0,
              ),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarMovimiento(int id) async {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del awesomeDialog según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);

    AwesomeDialog(
      width: isDesktop ? (screenSize.width - dialogWidth) / 2 : null,
      dialogBackgroundColor:
          Provider.of<TemaProveedor>(context, listen: false).esModoOscuro
          ? Color.fromRGBO(60, 60, 60, 1)
          : Color.fromRGBO(220, 220, 220, 1),
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Atención',
      desc: '¿Está seguro que desea eliminar este movimiento?',
      btnCancelText: 'No, cancelar',
      btnOkText: 'Sí, eliminar',
      btnOkOnPress: () async {
        try {
          await _cajaRepository.eliminarMovimiento(id);
          _cargarDatos();
        } catch (e, st) {
          _logger.log.e(
            'Error al eliminar movimiento',
            error: e,
            stackTrace: st,
          );
        }
      },
      btnCancelOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = screenSize.width >= 900;
    final themeProvider = Provider.of<TemaProveedor>(context);
    final isDark = themeProvider.esModoOscuro;

    // Obtenemos el tamaño de la pantalla
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);

    return Scaffold(
      backgroundColor: isDark
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          'Gestión de caja',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(text: 'Caja actual'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildCajaActualView(isDesktop), _buildHistorialTab()],
            ),
    );
  }

  Widget _buildCajaActualView(bool isDesktop) {
    if (_cajaActual == null) {
      return _buildNoCajaView();
    }
    return isDesktop ? _buildCajaActualDesktop() : _buildCajaActualMobile();
  }

  Widget _buildNoCajaView() {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.point_of_sale, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'No hay una caja abierta',
            style: TextStyle(
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _abrirCaja,
            icon: const Icon(Icons.lock_open, color: Colors.white),
            label: const Text(
              'Abrir caja',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCajaActualMobile() {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderInfo(),
          const SizedBox(height: 16),
          _buildSummaryGrid(crossAxisCount: 2),
          const SizedBox(height: 16),
          _buildNetProfitCard(),
          const SizedBox(height: 20),
          _buildActionsRow(),
          const SizedBox(height: 20),
          Text(
            'Movimientos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          _buildMovimientosList(),
          const SizedBox(height: 30),
          _buildCloseCajaButton(),
        ],
      ),
    );
  }

  Widget _buildCajaActualDesktop() {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 24),
                  _buildSummaryGrid(crossAxisCount: 4),
                  const SizedBox(height: 24),
                  _buildNetProfitCard(),
                  const SizedBox(height: 24),
                  _buildCloseCajaButton(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Card(
              color: isDark
                  ? const Color.fromRGBO(30, 30, 30, 1)
                  : Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionsRow(),
                    const SizedBox(height: 20),
                    Divider(color: isDark ? Colors.white24 : Colors.black12),
                    const SizedBox(height: 10),
                    Text(
                      'Movimientos recientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: _buildMovimientosList(scrollable: true)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final currency = NumberFormat.currency(symbol: 'L. ');
    final fechaApertura = DateTime.parse(_cajaActual!.fechaApertura);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(fechaApertura);
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    final usuario = _cajaActual!.cajeroAbre;

    return Card(
      elevation: 4,
      color: isDark ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Columna izquierda (usuario y fecha)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caja abierta por $usuario',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    maxLines: 2, // <-- ahora sí puede romperse
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Apertura: $formattedDate',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Columna derecha (monto)
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Monto Inicial',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    currency.format(_cajaActual!.montoApertura),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    overflow:
                        TextOverflow.ellipsis, // <-- controla overflow aquí
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalculationDetails({
    required String title,
    required String formula,
    Map<String, double>? breakdown,
    List<MovimientoCaja>? movimientos,
  }) {
    final currency = NumberFormat.currency(symbol: 'L. ');
    final isDark = Provider.of<TemaProveedor>(
      context,
      listen: false,
    ).esModoOscuro;

    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = screenSize.width >= 900;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    final double dialogWidth = isDesktop
        ? screenSize.width * 0.35
        : (isTablet ? screenSize.width * 0.55 : screenSize.width * 0.85);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? const Color.fromRGBO(60, 60, 60, 1)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fórmula:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    formula,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (breakdown != null) ...[
                  Text(
                    'Desglose:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...breakdown.entries.map((e) {
                    final isNegative = e.key == 'Egresos' || e.value < 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          Text(
                            currency.format(e.value),
                            style: TextStyle(
                              color: isNegative ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (movimientos != null && movimientos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: isDark ? Colors.white24 : Colors.black12),
                  const SizedBox(height: 8),
                  Text(
                    'Transacciones (${movimientos.length}):',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: movimientos.length,
                      itemBuilder: (context, index) {
                        final mov = movimientos[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            mov.concepto,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'dd/MM HH:mm',
                            ).format(DateTime.parse(mov.fecha)),
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          trailing: Text(
                            currency.format(mov.monto),
                            style: TextStyle(
                              color: mov.tipo == 'Egreso'
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (movimientos != null && movimientos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No hay transacciones registradas.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid({required int crossAxisCount}) {
    double _totalDevoluciones =
        _totalDevolucionesEfectivo +
        _totalDevolucionesTarjeta +
        _totalDevolucionesTransferencia;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildSummaryCard(
          'Ventas Efectivo',
          _totalEfectivoVentas - _totalDevolucionesEfectivo,
          Colors.green,
          onInfoPressed: () => _showCalculationDetails(
            title: 'Ventas en Efectivo',
            formula: 'Ventas Efectivo - Devoluciones Efectivo',
            breakdown: {
              'Ventas Efectivo': _totalEfectivoVentas,
              'Devoluciones Efectivo': _totalDevolucionesEfectivo,
            },
            movimientos: _movimientos
                .where((m) => m.tipo == 'Venta' && m.metodoPago == 'Efectivo')
                .toList(),
          ),
        ),
        _buildSummaryCard(
          'Ventas Tarjeta',
          _totalTarjeta - _totalDevolucionesTarjeta,
          Colors.blue,
          onInfoPressed: () => _showCalculationDetails(
            title: 'Ventas con Tarjeta',
            formula: 'Ventas con Tarjeta - Devoluciones con Tarjeta',
            breakdown: {
              'Ventas con Tarjeta': _totalTarjeta,
              'Devoluciones con Tarjeta': _totalDevolucionesTarjeta,
            },
            movimientos: _movimientos
                .where((m) => m.tipo == 'Venta' && m.metodoPago == 'Tarjeta')
                .toList(),
          ),
        ),
        _buildSummaryCard(
          'Ventas Transferencia',
          _totalTransferencia - _totalDevolucionesTransferencia,
          Colors.orange,
          onInfoPressed: () => _showCalculationDetails(
            title: 'Ventas por Transferencia',
            formula:
                'Ventas por Transferencia - Devoluciones por Transferencia',
            breakdown: {
              'Ventas por Transferencia': _totalTransferencia,
              'Devoluciones por Transferencia': _totalDevolucionesTransferencia,
            },
            movimientos: _movimientos
                .where(
                  (m) => m.tipo == 'Venta' && m.metodoPago == 'Transferencia',
                )
                .toList(),
          ),
        ),
        _buildSummaryCard(
          'Total Ventas',
          _cajaActual!.totalVentas - _totalDevoluciones,
          Colors.indigo,
          onInfoPressed: () => _showCalculationDetails(
            title: 'Total de Ventas',
            formula:
                'Ventas Efectivo + Ventas Tarjeta + Ventas Transferencia - Devoluciones Efectivo - Devoluciones Tarjeta - Devoluciones Transferencia',
            breakdown: {
              'Ventas Efectivo': _totalEfectivoVentas,
              'Ventas Tarjeta': _totalTarjeta,
              'Ventas Transferencia': _totalTransferencia,
              'Devoluciones Efectivo': _totalDevolucionesEfectivo,
              'Devoluciones Tarjeta': _totalDevolucionesTarjeta,
              'Devoluciones Transferencia': _totalDevolucionesTransferencia,
            },
          ),
        ),
        _buildSummaryCard(
          'Devoluciones',
          _totalDevoluciones,
          Colors.teal,
          onInfoPressed: () => _showCalculationDetails(
            title: 'Devoluciones de productos',
            formula:
                'Devoluciones Efectivo + Devoluciones Tarjeta + Devoluciones Transferencia',
            breakdown: {
              'Devoluciones Efectivo': _totalDevolucionesEfectivo,
              'Devoluciones Tarjeta': _totalDevolucionesTarjeta,
              'Devoluciones Transferencia': _totalDevolucionesTransferencia,
            },
            movimientos: _movimientos
                .where((m) => m.tipo == 'Devolucion')
                .toList(),
          ),
        ),
        _buildSummaryCard(
          'Ingresos',
          _cajaActual!.ingresos,
          Colors.teal,
          onInfoPressed: () => _showCalculationDetails(
            title: 'Ingresos de Caja',
            formula:
                'Ingresos Efectivo + Ingresos Tarjeta + Ingresos Transferencia',
            breakdown: {
              'Ingresos Efectivo': _totalIngresosEfectivo,
              'Ingresos Tarjeta': _totalIngresosTarjeta,
              'Ingresos Transferencia': _totalIngresosTransferencia,
            },
            movimientos: _movimientos
                .where((m) => m.tipo == 'Ingreso')
                .toList(),
          ),
        ),
        _buildSummaryCard(
          'Egresos',
          _cajaActual!.egresos - _totalDevoluciones,
          Colors.red,
          onInfoPressed: () => _showCalculationDetails(
            title: 'Egresos de Caja',
            formula:
                'Egresos Efectivo + Egresos Tarjeta + Egresos Transferencia',
            breakdown: {
              'Egresos Efectivo': _totalEgresosEfectivo,
              'Egresos Tarjeta': _totalEgresosTarjeta,
              'Egresos Transferencia': _totalEgresosTransferencia,
            },
            movimientos: _movimientos.where((m) => m.tipo == 'Egreso').toList(),
          ),
        ),
        _buildSummaryCard(
          'Efectivo en Caja',
          _cajaActual!.montoApertura +
              _totalEfectivoVentas +
              _totalIngresosEfectivo -
              _totalEgresosEfectivo -
              _totalDevolucionesEfectivo,
          Colors.green.shade700,
          onInfoPressed: () => _showCalculationDetails(
            title: 'Efectivo en Caja',
            formula:
                'Monto Inicial + Ventas Efectivo + Ingresos Efectivo - Egresos Efectivo',
            breakdown: {
              'Monto Inicial': _cajaActual!.montoApertura,
              'Ventas Efectivo':
                  _totalEfectivoVentas - _totalDevolucionesEfectivo,
              'Ingresos Efectivo': _totalIngresosEfectivo,
              'Egresos Efectivo': -_totalEgresosEfectivo,
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNetProfitCard() {
    final currency = NumberFormat.currency(symbol: 'L. ');
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    return Card(
      color: isDark ? Colors.blueGrey.shade900 : Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(
          'Balance Neto',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          '(Ventas + Ingresos - Egresos)',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency.format(
                _cajaActual!.totalVentas +
                    _cajaActual!.ingresos -
                    _cajaActual!.egresos,
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () => _showCalculationDetails(
                title: 'Balance Neto',
                formula: 'Total Ventas + Ingresos - Egresos',
                breakdown: {
                  'Total Ventas': _cajaActual!.totalVentas,
                  'Ingresos': _cajaActual!.ingresos,
                  'Egresos': -_cajaActual!.egresos,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          'Ingreso',
          Icons.add_circle,
          Colors.green,
          () => _registrarMovimiento('Ingreso'),
        ),
        _buildActionButton(
          'Egreso',
          Icons.remove_circle,
          Colors.red,
          () => _registrarMovimiento('Egreso'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMovimientosList({bool scrollable = false}) {
    final currency = NumberFormat.currency(symbol: 'L. ');
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    final filteredMovimientos = _movimientos.where((mov) {
      if (_filtroMetodoPago == 'Todo') return true;
      return mov.metodoPago == _filtroMetodoPago;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChipMetodo('Todo'),
              const SizedBox(width: 8),
              _filterChipMetodo('Efectivo'),
              const SizedBox(width: 8),
              _filterChipMetodo('Tarjeta'),
              const SizedBox(width: 8),
              _filterChipMetodo('Transferencia'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        scrollable
            ? Expanded(
                child: ListView.builder(
                  shrinkWrap: false,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredMovimientos.length,
                  itemBuilder: (context, index) {
                    final mov = filteredMovimientos[index];
                    return _buildMovimientoCard(
                      mov,
                      isDark,
                      isMobile,
                      currency,
                    );
                  },
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMovimientos.length,
                itemBuilder: (context, index) {
                  final mov = filteredMovimientos[index];
                  return _buildMovimientoCard(mov, isDark, isMobile, currency);
                },
              ),
      ],
    );
  }

  Widget _buildMovimientoCard(
    MovimientoCaja mov,
    bool isDark,
    bool isMobile,
    NumberFormat currency,
  ) {
    return Card(
      color: isDark ? const Color.fromRGBO(40, 40, 40, 1) : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mov.tipo == 'Ingreso'
              ? Colors.green.withOpacity(0.2)
              : mov.tipo == 'Egreso' || mov.tipo == 'Devolucion'
              ? Colors.red.withOpacity(0.2)
              : Colors.blue.withOpacity(0.2),
          child: Icon(
            mov.tipo == 'Ingreso'
                ? Icons.arrow_upward
                : mov.tipo == 'Egreso' || mov.tipo == 'Devolucion'
                ? Icons.arrow_downward
                : Icons.shopping_cart,
            color: mov.tipo == 'Ingreso'
                ? Colors.green
                : mov.tipo == 'Egreso' || mov.tipo == 'Devolucion'
                ? Colors.red
                : Colors.blue,
          ),
        ),
        title: Text(
          mov.concepto,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(mov.fecha)),
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: isMobile ? 12.0 : 14.0,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(DateTime.parse(mov.fecha)),
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: isMobile ? 12.0 : 14.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                mov.metodoPago,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency.format(mov.monto),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: mov.tipo == 'Egreso' || mov.tipo == 'Devolucion'
                    ? Colors.red
                    : Colors.green,
              ),
            ),
            if (mov.tipo != 'Venta' && mov.tipo != 'Devolucion') ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editarMovimiento(mov),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _eliminarMovimiento(mov.id!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChipMetodo(String label) {
    final isSelected = _filtroMetodoPago == label;
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filtroMetodoPago = label;
          });
        }
      },
      selectedColor: Colors.blueAccent,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
      ),
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
    );
  }

  Widget _buildCloseCajaButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _cerrarCaja,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'CERRAR CAJA',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color, {
    VoidCallback? onInfoPressed,
  }) {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    return Card(
      elevation: 2,
      color: isDark ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  NumberFormat.currency(symbol: 'L. ').format(amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (onInfoPressed != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: color.withOpacity(0.7),
                ),
                onPressed: onInfoPressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorialTab() {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    final currency = NumberFormat.currency(symbol: 'L. ');
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todo'),
                _filterChip('Hoy'),
                _filterChip('Semana'),
                _filterChip('Mes'),
                ActionChip(
                  label: Text(
                    'Calendario',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  avatar: Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _filtroHistorial = 'Rango';
                        _fechaInicio = picked.start;
                        _fechaFin = picked.end;
                      });
                      _cargarHistorial();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.only(
            bottom: 8.0,
            left: 24.00,
            right: 24.00,
            top: 8.0,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: diferencia == 0
                  ? Colors.green.withOpacity(0.1)
                  : (diferencia > 0
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: diferencia == 0
                    ? Colors.green
                    : (diferencia > 0 ? Colors.blue : Colors.red),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diferencia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diferencia == 0
                        ? Colors.green
                        : (diferencia > 0 ? Colors.blue : Colors.red),
                  ),
                ),
                Text(
                  currency.format(diferencia),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diferencia == 0
                        ? Colors.green
                        : (diferencia > 0 ? Colors.blue : Colors.red),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _historialCajas.length,
            itemBuilder: (context, index) {
              final caja = _historialCajas[index];
              return CajaHistoryCard(caja: caja);
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label) {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    final isSelected = _filtroHistorial == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : Colors.black),
          ),
        ),
        selected: isSelected,
        selectedColor: Colors.blueAccent,
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _filtroHistorial = label;
              _fechaInicio = null;
              _fechaFin = null;
            });
            _cargarHistorial();
          }
        },
      ),
    );
  }

  Widget _buildDropdownMetodoPago({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double labelFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double inputFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double verticalPadding = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);
    final double horizontalPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    final temaOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;

    return DropdownButtonFormField<String>(
      dropdownColor: temaOscuro ? Colors.black : Colors.white,
      value: value,
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontSize: inputFontSize,
        color: temaOscuro ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: temaOscuro ? Colors.white : Colors.black,
          fontSize: labelFontSize,
        ),
        filled: true,
        fillColor: temaOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: BorderSide(
            color: temaOscuro ? Colors.white : Colors.black,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: temaOscuro ? Colors.white : Colors.black,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        errorStyle: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
          fontSize: isMobile ? 12.0 : 13.0,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
      ),
    );
  }
}

class CajaHistoryCard extends StatefulWidget {
  final Caja caja;
  const CajaHistoryCard({super.key, required this.caja});

  @override
  State<CajaHistoryCard> createState() => _CajaHistoryCardState();
}

class _CajaHistoryCardState extends State<CajaHistoryCard> {
  final CajaRepository _repository = CajaRepository();
  late Future<Map<String, Map<String, double>>> _desgloseFuture;

  @override
  void initState() {
    super.initState();
    _desgloseFuture = _repository.obtenerDesgloseCaja(widget.caja.id!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<TemaProveedor>(context);
    final isDark = theme.esModoOscuro;
    final currency = NumberFormat.currency(symbol: 'L. ');
    final inicio = DateTime.parse(widget.caja.fechaApertura);
    final fin = DateTime.parse(widget.caja.fechaCierre!);

    return Card(
      color: isDark ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: isDark ? Colors.white : Colors.black,
        collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Caja #${widget.caja.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.caja.estado == 'Abierta'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.caja.estado,
                    style: TextStyle(
                      color: widget.caja.estado == 'Abierta'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Abierta: ${DateFormat('dd/MM/yyyy HH:mm').format(inicio)}',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                if (widget.caja.estado == 'Cerrada')
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    tooltip: 'Generar Reporte PDF',
                    onPressed: () async {
                      try {
                        final movimientos = await _repository
                            .obtenerMovimientos(widget.caja.id!);
                        final empresaRepo = RepositoryEmpresa();
                        final empresa = await empresaRepo.getEmpresa();

                        if (context.mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CajaPdfPreview(
                                caja: widget.caja,
                                movimientos: movimientos,
                                empresa: empresa,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al preparar vista previa: $e',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Cerrada: ${DateFormat('dd/MM/yyyy HH:mm').format(fin)}',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Ventas: ${currency.format(widget.caja.totalVentas)}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FutureBuilder<Map<String, Map<String, double>>>(
              future: _desgloseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error al cargar detalles');
                }

                final desglose = snapshot.data ?? {};
                return Column(
                  children: [
                    const Divider(),
                    _buildUserSection(isDark),
                    const Divider(),
                    _buildBreakdownSection(desglose, isDark, currency),
                    const Divider(),
                    _buildTotalsSection(isDark, currency),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_open, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Abrió:',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                widget.caja.cajeroAbre,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cerró:',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.lock, size: 16, color: Colors.red),
                ],
              ),
              Text(
                widget.caja.cajeroCierra,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownSection(
    Map<String, Map<String, double>> desglose,
    bool isDark,
    NumberFormat currency,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Stack vertically
          return Column(
            children: [
              _buildCategoryBlock(
                'Ventas',
                desglose['Venta']!,
                Colors.blue,
                isDark,
                currency,
              ),
              const SizedBox(height: 12),
              _buildCategoryBlock(
                'Ingresos',
                desglose['Ingreso']!,
                Colors.green,
                isDark,
                currency,
              ),
              const SizedBox(height: 12),
              _buildCategoryBlock(
                'Egresos',
                desglose['Egreso']!,
                Colors.red,
                isDark,
                currency,
              ),
            ],
          );
        } else {
          // Desktop/Tablet: Row
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCategoryBlock(
                  'Ventas',
                  desglose['Venta']!,
                  Colors.blue,
                  isDark,
                  currency,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryBlock(
                  'Ingresos',
                  desglose['Ingreso']!,
                  Colors.green,
                  isDark,
                  currency,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryBlock(
                  'Egresos',
                  desglose['Egreso']!,
                  Colors.red,
                  isDark,
                  currency,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildCategoryBlock(
    String title,
    Map<String, double> items,
    Color color,
    bool isDark,
    NumberFormat currency,
  ) {
    final total = items.values.fold(0.0, (sum, val) => sum + val);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                currency.format(total),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...items.entries.map((e) {
            if (e.value == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    currency.format(e.value),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(bool isDark, NumberFormat currency) {
    return Column(
      children: [
        _rowDetail(
          'Monto Apertura',
          currency.format(widget.caja.montoApertura),
          isDark,
        ),
        _rowDetail(
          'Total Efectivo Calculado',
          currency.format(widget.caja.totalEfectivo),
          isDark,
        ),
        if (widget.caja.montoCierre != null)
          _rowDetail(
            'Monto de Cierre Real',
            currency.format(widget.caja.montoCierre!),
            isDark,
          ),
        if (widget.caja.diferencia != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: widget.caja.diferencia == 0
                  ? Colors.green.withOpacity(0.1)
                  : (widget.caja.diferencia! > 0
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.caja.diferencia == 0
                    ? Colors.green
                    : (widget.caja.diferencia! > 0 ? Colors.blue : Colors.red),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diferencia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.caja.diferencia == 0
                        ? Colors.green
                        : (widget.caja.diferencia! > 0
                              ? Colors.blue
                              : Colors.red),
                  ),
                ),
                Text(
                  currency.format(widget.caja.diferencia),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.caja.diferencia == 0
                        ? Colors.green
                        : (widget.caja.diferencia! > 0
                              ? Colors.blue
                              : Colors.red),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _rowDetail(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
