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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() => _isLoading = true);
      final caja = await _cajaRepository.obtenerCajaAbierta();
      if (caja != null) {
        final movimientos = await _cajaRepository.obtenerMovimientos(caja.id!);
        setState(() {
          _cajaActual = caja;
          _movimientos = movimientos;
          _isLoading = false;
        });
      } else {
        setState(() {
          _cajaActual = null;
          _movimientos = [];
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
      final historial = await _cajaRepository.obtenerHistorialCajas(
        filtro: _filtroHistorial,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
      setState(() {
        _historialCajas = historial;
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
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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
                  await _cajaRepository.abrirCaja(monto);
                  Navigator.pop(context);
                  _cargarDatos();
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
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
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
                        Navigator.pop(context);
                        _cargarDatos();
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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
                    metodoPago:
                        'Efectivo', // Por defecto efectivo para ingresos/egresos manuales
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
                    metodoPago: mov.metodoPago,
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
            Tab(text: 'Caja Actual'),
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
              'Abrir Caja',
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
                      'Movimientos Recientes',
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

    return Card(
      elevation: 4,
      color: isDark ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Caja Abierta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Apertura: $formattedDate',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
            Column(
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid({required int crossAxisCount}) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildSummaryCard(
          'Total Ventas',
          _cajaActual!.totalVentas,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Total Efectivo',
          _cajaActual!.totalEfectivo,
          Colors.green,
        ),
        _buildSummaryCard('Ingresos', _cajaActual!.ingresos, Colors.orange),
        _buildSummaryCard('Egresos', _cajaActual!.egresos, Colors.red),
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
        trailing: Text(
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

    return ListView.builder(
      shrinkWrap: !scrollable,
      physics: scrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: _movimientos.length,
      itemBuilder: (context, index) {
        final mov = _movimientos[index];
        return Card(
          color: isDark ? const Color.fromRGBO(40, 40, 40, 1) : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: mov.tipo == 'Ingreso'
                  ? Colors.green.withOpacity(0.2)
                  : mov.tipo == 'Egreso'
                  ? Colors.red.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              child: Icon(
                mov.tipo == 'Ingreso'
                    ? Icons.arrow_upward
                    : mov.tipo == 'Egreso'
                    ? Icons.arrow_downward
                    : Icons.shopping_cart,
                color: mov.tipo == 'Ingreso'
                    ? Colors.green
                    : mov.tipo == 'Egreso'
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
            subtitle: Row(
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currency.format(mov.monto),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: mov.tipo == 'Egreso' ? Colors.red : Colors.green,
                  ),
                ),
                if (mov.tipo != 'Venta') ...[
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
      },
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

  Widget _buildSummaryCard(String title, double amount, Color color) {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
    return Card(
      elevation: 2,
      color: isDark ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: Padding(
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
    );
  }

  Widget _buildHistorialTab() {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
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

        // List
        Expanded(
          child: ListView.builder(
            itemCount: _historialCajas.length,
            itemBuilder: (context, index) {
              final caja = _historialCajas[index];
              final inicio = DateTime.parse(caja.fechaApertura);
              final fin = caja.fechaCierre != null
                  ? DateTime.parse(caja.fechaCierre!)
                  : null;
              final duracion = fin != null
                  ? fin.difference(inicio)
                  : Duration.zero;
              final currency = NumberFormat.currency(symbol: 'L. ');

              return Card(
                color: isDark
                    ? const Color.fromRGBO(30, 30, 30, 1)
                    : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile(
                  iconColor: isDark ? Colors.white : Colors.black,
                  collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
                  title: Text(
                    'Caja #${caja.id} - ${DateFormat('dd/MM/yyyy').format(inicio)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Estado: ${caja.estado} | ${currency.format(caja.totalVentas)} Ventas',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _rowDetail(
                            'Apertura',
                            DateFormat('HH:mm').format(inicio),
                          ),
                          if (fin != null)
                            _rowDetail(
                              'Cierre',
                              DateFormat('HH:mm').format(fin),
                            ),
                          _rowDetail(
                            'Duración',
                            '${duracion.inHours}h ${duracion.inMinutes.remainder(60)}m',
                          ),
                          Divider(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          _rowDetail(
                            'Monto Inicial',
                            currency.format(caja.montoApertura),
                          ),
                          _rowDetail(
                            'Ventas',
                            currency.format(caja.totalVentas),
                          ),
                          _rowDetail(
                            'Ingresos',
                            currency.format(caja.ingresos),
                          ),
                          _rowDetail('Egresos', currency.format(caja.egresos)),
                          Divider(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          _rowDetail(
                            'Total Efectivo',
                            currency.format(caja.totalEfectivo),
                          ),
                          if (caja.montoCierre != null)
                            _rowDetail(
                              'Monto Cierre',
                              currency.format(caja.montoCierre!),
                            ),
                          if (caja.diferencia != null)
                            _rowDetail(
                              'Diferencia',
                              currency.format(caja.diferencia!),
                              color: caja.diferencia! == 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
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

  Widget _rowDetail(String label, String value, {Color? color}) {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;
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
              color: color ?? (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
