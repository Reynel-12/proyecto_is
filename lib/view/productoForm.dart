import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_is/controller/repository_producto.dart';
import 'package:proyecto_is/controller/repository_proveedor.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/model/producto.dart';
import 'package:proyecto_is/model/proveedor.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

// ignore: must_be_immutable
class Nuevoproducto extends StatefulWidget {
  bool isEdit;
  bool isEditCodigo;
  bool isEditNombre;
  bool isEditUnidad;
  bool isEditPrecio;
  bool isEditCosto;
  bool isEditProveedor;
  String codigo;
  Nuevoproducto({
    super.key,
    this.isEdit = false,
    this.isEditCodigo = false,
    this.isEditNombre = false,
    this.isEditPrecio = false,
    this.isEditUnidad = false,
    this.isEditCosto = false,
    this.isEditProveedor = false,
    this.codigo = '',
  });

  @override
  State<Nuevoproducto> createState() => _NuevoproductoState();
}

class _NuevoproductoState extends State<Nuevoproducto> {
  final TextEditingController _codigo = TextEditingController();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _tipo = TextEditingController();
  final TextEditingController _inventario = TextEditingController();
  final TextEditingController _precio = TextEditingController();
  final TextEditingController _costo = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? selectedProveedor;

  final ProductoRepository _productoRepository = ProductoRepository();
  final ProveedorRepository _proveedorRepository = ProveedorRepository();

  String nombre = '';
  String codigo = '';
  int precio = 0;
  int inventario = 0;

  Proveedor? _selectedItem;
  List<Proveedor> items = [];

  void cargarProveedores() async {
    items = await _proveedorRepository.getProveedores();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    !widget.isEdit ? cargarProveedores() : null;
  }

  void _mostrarMensaje(String titulo, String mensaje, ContentType type) {
    final snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: titulo,
        message: mensaje,

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: type,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> _updateProduct() async {
    String codigo = _codigo.text;
    String nombre = _nombre.text;
    String tipo = _tipo.text;
    int precio = int.tryParse(_precio.text) ?? 0;

    // Actualizar nombre
    if (widget.isEditNombre && nombre.isNotEmpty) {
      _mostrarMensaje(
        'Éxito',
        'Producto actualizado correctamente',
        ContentType.success,
      );
      Navigator.pop(context, true);
    }

    // Actualizar tipo
    if (widget.isEditUnidad && tipo.isNotEmpty) {
      _mostrarMensaje(
        'Éxito',
        'Producto actualizado correctamente',
        ContentType.success,
      );
      Navigator.pop(context, true);
    }

    // Actualizar precio
    if (widget.isEditPrecio && precio > 0) {
      _mostrarMensaje(
        'Éxito',
        'Producto actualizado correctamente',
        ContentType.success,
      );
      Navigator.pop(context, true);
    }

    // Actualizar código
    if (widget.isEditCodigo && codigo.isNotEmpty && widget.codigo != codigo) {
      _mostrarMensaje(
        'Éxito',
        'Producto actualizado correctamente',
        ContentType.success,
      );
      Navigator.pop(context, true);
    }
  }

  void agregarProducto() async {
    try {
      String codigo = _codigo.text.trim();
      String nombre = _nombre.text.trim();
      String tipo = _tipo.text.trim();
      double precio = double.tryParse(_precio.text) ?? 0;
      int inventario = int.tryParse(_inventario.text) ?? 0;
      double costo = double.tryParse(_costo.text) ?? 0;
      String fechaCreacion = DateTime.now().toString();
      int proveedorId = _selectedItem?.id ?? 0;
      final producto = Producto(
        id: codigo,
        nombre: nombre,
        precio: precio,
        costo: costo,
        unidadMedida: tipo,
        stock: inventario,
        fechaCreacion: fechaCreacion,
        proveedorId: proveedorId,
      );
      await _productoRepository.insertProducto(producto);
      _mostrarMensaje(
        'Éxito',
        'Producto creado correctamente',
        ContentType.success,
      );
      Navigator.pop(context);
    } catch (e) {
      _mostrarMensaje('Error', 'Error inesperado', ContentType.failure);
      print("Error inesperado: $e");
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
          widget.isEdit ? 'Editar producto' : 'Agregar producto',
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
      body: isDesktop
          ? _buildDesktopLayout()
          : Stack(children: [widget.isEdit ? formulario() : formulario()]),
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
                      widget.isEdit ? Icons.edit_document : Icons.add_box,
                      size: 120,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white.withOpacity(0.8)
                          : Colors.blueAccent.withOpacity(0.8),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.isEdit ? 'Actualizar Producto' : 'Nuevo Producto',
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
                          ? 'Modifica los datos del producto según sea necesario.'
                          : 'Completa el formulario para agregar un nuevo producto al inventario.',
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
              // Código
              if ((widget.isEdit && widget.isEditCodigo) || !widget.isEdit)
                _buildTextField(_codigo, 'Código', code: true),

              // Nombre
              if ((widget.isEdit && widget.isEditNombre) || !widget.isEdit)
                Column(
                  children: [
                    SizedBox(height: fieldSpacing),
                    _buildTextField(_nombre, 'Nombre'),
                  ],
                ),

              // Unidad/Tipo
              if ((widget.isEdit && widget.isEditUnidad) || !widget.isEdit)
                Column(
                  children: [
                    SizedBox(height: fieldSpacing),
                    _buildTextField(_tipo, widget.isEdit ? 'Unidad' : 'Tipo'),
                  ],
                ),

              // Inventario (solo en modo agregar)
              if (!widget.isEdit)
                Column(
                  children: [
                    SizedBox(height: fieldSpacing),
                    _buildTextField(
                      _inventario,
                      'Stock inicial',
                      isNumber: true,
                    ),
                  ],
                ),

              // Precio
              if ((widget.isEdit && widget.isEditPrecio) || !widget.isEdit)
                Column(
                  children: [
                    SizedBox(height: fieldSpacing),
                    _buildTextField(_precio, 'Precio', isNumber: true),
                  ],
                ),

              // Costo
              if ((widget.isEdit && widget.isEditCosto) || !widget.isEdit)
                Column(
                  children: [
                    SizedBox(height: fieldSpacing),
                    _buildTextField(_costo, 'Costo base', isNumber: true),
                  ],
                ),

              // Proveedor
              if ((widget.isEdit && widget.isEditProveedor) || !widget.isEdit)
                Column(
                  children: [
                    SizedBox(height: fieldSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedItem,
                            items: items,
                            label: 'Seleccionar proveedor',
                            icon: Icons.category,
                            onChanged: (Proveedor? newValue) {
                              setState(() {
                                _selectedItem = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor selecciona una opción';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: isMobile ? 8.0 : 12.0),
                      ],
                    ),
                  ],
                ),

              // Botón de confirmar
              SizedBox(height: fieldSpacing * 1.25),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.isEdit ? _updateProduct() : agregarProducto();
                  }
                },
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
                  'Confirmar',
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
    bool code = false,
    bool readOnly = false,
  }) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double labelFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double inputFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double iconSize = isMobile ? 22.0 : (isTablet ? 24.0 : 26.0);
    final double verticalPadding = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);
    final double horizontalPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly, // Permite solo dígitos
            ]
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
        suffixIcon: code
            ? IconButton(
                icon: Icon(
                  Icons.barcode_reader,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                  size: iconSize,
                ),
                onPressed: () async {
                  if (Platform.isAndroid || Platform.isIOS) {}
                },
              )
            : null,
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Por favor, ingrese el $label';
        } else if (isNumber && value.contains('-')) {
          return 'Por favor, ingrese números positivos';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required Proveedor? value,
    required List<Proveedor> items,
    required String label,
    required IconData icon,
    required Function(Proveedor?) onChanged,
    String? Function(Proveedor?)? validator,
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

    return DropdownButtonFormField<Proveedor>(
      dropdownColor: temaOscuro ? Colors.black : Colors.white,
      value: value,
      items: items.map<DropdownMenuItem<Proveedor>>((Proveedor item) {
        return DropdownMenuItem<Proveedor>(
          value: item,
          child: Text(
            item.nombre, // usamos la propiedad del objeto
          ),
        );
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
