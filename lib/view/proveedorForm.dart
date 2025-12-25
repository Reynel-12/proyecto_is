import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_is/controller/repository_proveedor.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/model/proveedor.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ProveedorForm extends StatefulWidget {
  bool isEdit;
  String nombre;
  String direccion;
  String telefono;
  String correo;

  ProveedorForm({
    super.key,
    this.isEdit = false,
    this.nombre = '',
    this.direccion = '',
    this.telefono = '',
    this.correo = '',
  });

  @override
  State<ProveedorForm> createState() => _ProveedorFormState();
}

class _ProveedorFormState extends State<ProveedorForm> {
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _correo = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ProveedorRepository _proveedorRepository = ProveedorRepository();

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _nombre.text = widget.nombre;
      _direccion.text = widget.direccion;
      _telefono.text = widget.telefono;
      _correo.text = widget.correo;
    }
  }

  void _mostrarMensaje(String titulo, String mensaje, ContentType type) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: titulo,
        message: mensaje,
        contentType: type,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  void _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;
    // Aquí iría la lógica para guardar en base de datos
    try {
      final proveedor = Proveedor(
        nombre: _nombre.text.trim(),
        direccion: _direccion.text.trim(),
        telefono: _telefono.text.trim(),
        correo: _correo.text.trim(),
      );
      await _proveedorRepository.insertProveedor(proveedor);
      _mostrarMensaje(
        'Éxito',
        'Proveedor creado correctamente',
        ContentType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      _mostrarMensaje(
        'Error',
        'Error al guardar el proveedor',
        ContentType.warning,
      );
      print(e);
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);

    return Scaffold(
      backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Editar Proveedor' : 'Nuevo Proveedor',
          style: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
      ),
      body: isDesktop ? _buildDesktopLayout() : Stack(children: [formulario()]),
    );
  }

  // Layout para escritorio (diseño horizontal)
  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        width: 800, // Ancho máximo para el formulario en escritorio
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna izquierda con imagen o icono
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isEdit ? Icons.edit_note : Icons.person_add,
                      size: 120,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white.withOpacity(0.8)
                          : Colors.blueAccent.withOpacity(0.8),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.isEdit
                          ? 'Actualizar Proveedor'
                          : 'Nuevo Proveedor',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isEdit
                          ? 'Modifica los datos del proveedor según sea necesario.'
                          : 'Completa el formulario para registrar un nuevo proveedor.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Columna derecha con el formulario
            Expanded(
              flex: 3,
              child: Card(
                margin: const EdgeInsets.all(24.0),
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? const Color.fromRGBO(30, 30, 30, 1)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: formulario(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget formulario() {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double buttonHeight = isMobile ? 50.0 : (isTablet ? 55.0 : 60.0);
    final double buttonFontSize = isMobile ? 16.0 : (isTablet ? 17.0 : 18.0);
    final double fieldSpacing = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(
          isMobile ? 16.0 : (isTablet ? 20.0 : 0.0),
        ), // Sin padding adicional en desktop
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nombre
              _buildTextField(_nombre, 'Nombre del Proveedor'),
              SizedBox(height: fieldSpacing),

              // Dirección
              _buildTextField(_direccion, 'Dirección'),
              SizedBox(height: fieldSpacing),

              // Teléfono
              _buildTextField(_telefono, 'Teléfono', isNumber: true),
              SizedBox(height: fieldSpacing),

              // Correo / Información adicional
              _buildTextField(_correo, 'Correo / Información'),

              // Botón de confirmar
              SizedBox(height: fieldSpacing * 1.25),
              ElevatedButton(
                onPressed: _guardarProveedor,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, buttonHeight),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12.0 : 16.0,
                  ),
                ),
                child: Text(
                  'Guardar',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // Botón de cancelar (solo en escritorio)
              if (isDesktop)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black.withOpacity(0.8),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
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

    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      inputFormatters: isNumber
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      style: TextStyle(
        fontSize: inputFontSize,
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.white
            : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
          fontSize: labelFontSize,
        ),
        filled: true,
        fillColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          borderSide: BorderSide(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
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
      validator: (value) {
        if (value!.isEmpty) {
          return 'Por favor, ingrese el $label';
        }
        return null;
      },
    );
  }
}
