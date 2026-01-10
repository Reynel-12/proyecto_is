import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_is/controller/sar_service.dart';
import 'package:proyecto_is/model/sar_config.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/controller/repository_empresa.dart';
import 'package:proyecto_is/model/empresa.dart';

class ConfiguracionSarView extends StatefulWidget {
  const ConfiguracionSarView({super.key});

  @override
  State<ConfiguracionSarView> createState() => _ConfiguracionSarViewState();
}

class _ConfiguracionSarViewState extends State<ConfiguracionSarView> {
  // SAR Controllers
  final _formKeySar = GlobalKey<FormState>();
  final _caiController = TextEditingController();
  final _rangoInicialController = TextEditingController();
  final _rangoFinalController = TextEditingController();
  final _fechaLimiteController = TextEditingController();
  final _numeroActualController = TextEditingController();

  // Empresa Controllers
  final _formKeyEmpresa = GlobalKey<FormState>();
  final _rtnController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _nombreComercialController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _monedaController = TextEditingController(text: 'HNL');

  final _sarService = SarService();
  final _empresaRepository = RepositoryEmpresa();

  bool _isLoading = false;
  int _empresaId = 0; // 0 indicates new record

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    await Future.wait([_cargarConfiguracionSar(), _cargarDatosEmpresa()]);
    setState(() => _isLoading = false);
  }

  Future<void> _cargarConfiguracionSar() async {
    final config = await _sarService.obtenerConfiguracionActiva();
    if (config != null) {
      _caiController.text = config.cai;
      _rangoInicialController.text = config.rangoInicial;
      _rangoFinalController.text = config.rangoFinal;
      _fechaLimiteController.text = config.fechaLimite;
      _numeroActualController.text = config.numeroActual.toString();
    }
  }

  Future<void> _cargarDatosEmpresa() async {
    try {
      final empresa = await _empresaRepository.getEmpresa();
      if (empresa != null) {
        _empresaId = empresa.id;
        _rtnController.text = empresa.rtn;
        _razonSocialController.text = empresa.razonSocial;
        _nombreComercialController.text = empresa.nombreComercial;
        _direccionController.text = empresa.direccion;
        _telefonoController.text = empresa.telefono;
        _correoController.text = empresa.correo;
        _monedaController.text = empresa.monedaDefecto;
      }
    } catch (e) {
      // Handle error or assume no company exists yet
      print('Error cargando empresa: $e');
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaLimiteController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _guardarConfiguracionSar() async {
    if (_formKeySar.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final config = SarConfig(
          cai: _caiController.text.trim(),
          rangoInicial: _rangoInicialController.text.trim(),
          rangoFinal: _rangoFinalController.text.trim(),
          fechaLimite: _fechaLimiteController.text.trim(),
          numeroActual: int.parse(_numeroActualController.text.trim()),
          activo: true,
        );

        await _sarService.guardarConfiguracion(config);

        if (mounted) {
          _mostrarMensaje(
            'Éxito',
            'Configuración SAR guardada correctamente',
            ContentType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          _mostrarMensaje(
            'Error',
            'Error al guardar la configuración SAR: $e',
            ContentType.failure,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _guardarEmpresa() async {
    if (_formKeyEmpresa.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final empresa = Empresa(
          id: _empresaId == 0
              ? 1
              : _empresaId, // Assuming single company with ID 1
          rtn: _rtnController.text.trim(),
          razonSocial: _razonSocialController.text.trim(),
          nombreComercial: _nombreComercialController.text.trim(),
          direccion: _direccionController.text.trim(),
          telefono: _telefonoController.text.trim(),
          correo: _correoController.text.trim(),
          monedaDefecto: _monedaController.text.trim(),
          fechaCreacion: DateTime.now().toIso8601String(),
        );

        if (_empresaId == 0) {
          await _empresaRepository.insertEmpresa(empresa);
          _empresaId = 1; // Set ID after insert
        } else {
          await _empresaRepository.updateEmpresa(empresa);
        }

        if (mounted) {
          _mostrarMensaje(
            'Éxito',
            'Datos de la empresa guardados correctamente',
            ContentType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          _mostrarMensaje(
            'Error',
            'Error al guardar datos de la empresa: $e',
            ContentType.failure,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarMensaje(String title, String message, ContentType contentType) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<TemaProveedor>(context).esModoOscuro;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Configuración',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isDark
              ? Colors.black
              : const Color.fromRGBO(244, 243, 243, 1),
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: isDark ? Colors.grey : Colors.grey[600],
            indicatorColor: Colors.blueAccent,
            tabs: const [
              Tab(text: 'SAR', icon: Icon(Icons.receipt_long)),
              Tab(text: 'Empresa', icon: Icon(Icons.business)),
            ],
          ),
        ),
        backgroundColor: isDark
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [_buildSarTab(isDark), _buildEmpresaTab(isDark)],
              ),
      ),
    );
  }

  Widget _buildSarTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeySar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              isDark,
              Column(
                children: [
                  _buildTextField(
                    controller: _caiController,
                    label: 'CAI',
                    icon: Icons.receipt_long,
                    isDark: isDark,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _rangoInicialController,
                    label: 'Rango Inicial (Ej: 000-001-01-00000001)',
                    icon: Icons.start,
                    isDark: isDark,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _rangoFinalController,
                    label: 'Rango Final (Ej: 000-001-01-00001000)',
                    icon: Icons.last_page,
                    isDark: isDark,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _seleccionarFecha,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: _fechaLimiteController,
                        label: 'Fecha Límite de Emisión',
                        icon: Icons.calendar_today,
                        isDark: isDark,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Campo requerido' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _numeroActualController,
                    label: 'Número Actual (Correlativo)',
                    icon: Icons.numbers,
                    isDark: isDark,
                    isNumber: true,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardarConfiguracionSar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Guardar Configuración SAR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpresaTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyEmpresa,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              isDark,
              Column(
                children: [
                  _buildTextField(
                    controller: _rtnController,
                    label: 'RTN',
                    icon: Icons.badge,
                    isDark: isDark,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _razonSocialController,
                    label: 'Razón Social',
                    icon: Icons.business,
                    isDark: isDark,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nombreComercialController,
                    label: 'Nombre Comercial',
                    icon: Icons.store,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _direccionController,
                    label: 'Dirección',
                    icon: Icons.location_on,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _telefonoController,
                    label: 'Teléfono',
                    icon: Icons.phone,
                    isDark: isDark,
                    isNumber: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _correoController,
                    label: 'Correo Electrónico',
                    icon: Icons.email,
                    isDark: isDark,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if (!v.contains('@')) return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _monedaController,
                    label: 'Moneda por Defecto',
                    icon: Icons.monetization_on,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardarEmpresa,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Guardar Datos Empresa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: isDark
            ? const Color.fromRGBO(40, 40, 40, 1)
            : Colors.grey[50],
      ),
    );
  }
}
