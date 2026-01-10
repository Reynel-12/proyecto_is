import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_is/controller/sar_service.dart';
import 'package:proyecto_is/model/sar_config.dart';
import 'package:proyecto_is/model/preferences.dart';

class ConfiguracionSarView extends StatefulWidget {
  const ConfiguracionSarView({super.key});

  @override
  State<ConfiguracionSarView> createState() => _ConfiguracionSarViewState();
}

class _ConfiguracionSarViewState extends State<ConfiguracionSarView> {
  final _formKey = GlobalKey<FormState>();
  final _caiController = TextEditingController();
  final _rangoInicialController = TextEditingController();
  final _rangoFinalController = TextEditingController();
  final _fechaLimiteController = TextEditingController();
  final _numeroActualController = TextEditingController();

  final _sarService = SarService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracionActual();
  }

  Future<void> _cargarConfiguracionActual() async {
    setState(() => _isLoading = true);
    final config = await _sarService.obtenerConfiguracionActiva();
    if (config != null) {
      _caiController.text = config.cai;
      _rangoInicialController.text = config.rangoInicial;
      _rangoFinalController.text = config.rangoFinal;
      _fechaLimiteController.text = config.fechaLimite;
      _numeroActualController.text = config.numeroActual.toString();
    }
    setState(() => _isLoading = false);
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

  void _guardarConfiguracion() async {
    if (_formKey.currentState!.validate()) {
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
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          _mostrarMensaje(
            'Error',
            'Error al guardar la configuración: $e',
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración SAR',
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
      ),
      backgroundColor: isDark
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
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
                                validator: (v) => v?.isEmpty ?? true
                                    ? 'Campo requerido'
                                    : null,
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
                      onPressed: _guardarConfiguracion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Guardar Configuración',
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
