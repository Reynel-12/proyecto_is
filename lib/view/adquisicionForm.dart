import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_is/controller/repository_caja.dart';
import 'package:proyecto_is/controller/repository_producto.dart';
import 'package:proyecto_is/controller/repository_proveedor.dart';
import 'package:proyecto_is/controller/repository_compra.dart';
import 'package:proyecto_is/model/caja.dart';
import 'package:proyecto_is/model/movimiento_caja.dart';
import 'package:proyecto_is/model/producto.dart';
import 'package:proyecto_is/model/proveedor.dart';
import 'package:proyecto_is/model/compra.dart';
import 'package:proyecto_is/model/detalle_compra.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:provider/provider.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:proyecto_is/view/widgets/caja_cerrada.dart';

class AdquisicionForm extends StatefulWidget {
  const AdquisicionForm({super.key});

  @override
  State<AdquisicionForm> createState() => _AdquisicionFormState();
}

class _AdquisicionFormState extends State<AdquisicionForm> {
  final _productoRepo = ProductoRepository();
  final _proveedorRepo = ProveedorRepository();
  final _compraRepo = CompraRepository();
  final _movimientoRepo = CajaRepository();

  List<Proveedor> _proveedores = [];
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  Proveedor? _proveedorSeleccionado;
  Caja? _cajaSeleccionada;

  // Lista de items en la compra actual
  List<Map<String, dynamic>> _carritoCompra = [];
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final proveedores = await _proveedorRepo.getProveedoresByEstado('Activo');
    final productos = await _productoRepo.getProductos();
    final caja = await _movimientoRepo.obtenerCajaAbierta();
    setState(() {
      _proveedores = proveedores;
      _productos = productos;
      _cajaSeleccionada = caja;
      _productosFiltrados = productos;
      _isLoading = false;
    });
  }

  void _agregarAlCarrito(Producto producto) {
    TextEditingController cantidadController = TextEditingController(text: '1');
    TextEditingController costoController = TextEditingController(
      text: producto.costo.toString(),
    );
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Calculamos el ancho del diálogo según el tamaño de pantalla
    final double dialogWidth = isDesktop
        ? screenSize.width * 0.3
        : (isTablet ? screenSize.width * 0.5 : screenSize.width * 0.8);

    showDialog(
      context: context,
      builder: (context) {
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
                  Icons.add,
                  size: isMobile ? 20.0 : 24.0,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                SizedBox(width: 8),
                Text(
                  'Agregar ${producto.nombre}',
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
                  children: [
                    _buildTextField(
                      cantidadController,
                      'Cantidad',
                      isNumber: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      costoController,
                      'Costo Unitario',
                      isNumber: true,
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
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                int cant = int.tryParse(cantidadController.text) ?? 0;
                double costo = double.tryParse(costoController.text) ?? 0.0;
                if (cant > 0 && costo > 0) {
                  setState(() {
                    int index = _carritoCompra.indexWhere(
                      (item) =>
                          (item['producto'] as Producto).id == producto.id,
                    );

                    if (index != -1) {
                      _carritoCompra[index]['cantidad'] += cant;
                      _carritoCompra[index]['costo'] = costo;
                      _carritoCompra[index]['subtotal'] =
                          _carritoCompra[index]['cantidad'] * costo;
                    } else {
                      _carritoCompra.add({
                        'producto': producto,
                        'cantidad': cant,
                        'costo': costo,
                        'subtotal': cant * costo,
                      });
                    }
                  });
                  Navigator.pop(context);
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
                'Agregar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  double get _totalCompra =>
      _carritoCompra.fold(0, (sum, item) => sum + item['subtotal']);

  Future<void> _finalizarCompra() async {
    if (_proveedorSeleccionado == null) {
      _mostrarMensaje(
        'Error',
        'Debe seleccionar un proveedor',
        ContentType.failure,
      );
      return;
    }
    if (_carritoCompra.isEmpty) {
      _mostrarMensaje(
        'Error',
        'Debe agregar al menos un producto',
        ContentType.failure,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fecha = DateTime.now().toIso8601String();

      final compra = Compra(
        proveedorId: _proveedorSeleccionado!.id!,
        fecha: fecha,
        total: _totalCompra,
      );

      final detalles = _carritoCompra
          .map(
            (item) => DetalleCompra(
              productoId: (item['producto'] as Producto).id,
              cantidad: item['cantidad'],
              costoUnitario: item['costo'],
              subtotal: item['subtotal'],
            ),
          )
          .toList();

      final movimiento = MovimientoCaja(
        idCaja: _cajaSeleccionada!.id!,
        tipo: 'Egreso',
        concepto: 'Adquisición de ${_proveedorSeleccionado!.nombre}',
        monto: _totalCompra,
        metodoPago: 'Efectivo',
        fecha: fecha,
      );

      await _compraRepo.registrarCompra(compra, detalles);
      await _movimientoRepo.registrarMovimiento(movimiento);

      _mostrarMensaje(
        'Éxito',
        'Adquisición registrada correctamente. Stock actualizado.',
        ContentType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      _mostrarMensaje(
        'Error',
        'No se pudo registrar la compra',
        ContentType.failure,
      );
      print(e);
    } finally {
      setState(() => _isLoading = false);
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
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isDesktop = screenSize.width >= 900;

    final esModoOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;
    final colorTexto = esModoOscuro ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          'Nueva adquisición',
          style: TextStyle(
            color: colorTexto,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: esModoOscuro
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(color: colorTexto),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cajaSeleccionada == null
          ? CajaCerradaScreen()
          : isDesktop
          ? _buildDesktopLayout()
          : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProveedorSelector(),
          const SizedBox(height: 16),
          _buildItemsListHeader(),
          Expanded(child: _buildItemsList()),
          _buildSummary(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        width: 1000,
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel izquierdo: Selector de proveedor y resumen
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildProveedorSelector(),
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Panel derecho: Lista de productos
            Expanded(
              flex: 3,
              child: Card(
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? const Color.fromRGBO(30, 30, 30, 1)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Productos en esta adquisición',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _buildItemsList()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProveedorSelector() {
    return _buildDropdown(
      value: _proveedorSeleccionado,
      items: _proveedores,
      label: 'Seleccionar proveedor',
      icon: Icons.person,
      onChanged: (val) {
        setState(() {
          _proveedorSeleccionado = val;
          _productosFiltrados = _productos
              .where((p) => p.proveedorId == val?.id)
              .toList();
        });
      },
    );
  }

  Widget _buildItemsListHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        'Productos en esta adquisición:',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    final esModoOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;
    if (_carritoCompra.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: esModoOscuro ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos agregados',
              style: TextStyle(
                color: esModoOscuro ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _carritoCompra.length,
      itemBuilder: (context, index) {
        final item = _carritoCompra[index];
        final producto = item['producto'] as Producto;
        return Card(
          color: esModoOscuro
              ? const Color.fromRGBO(40, 40, 40, 1)
              : Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.inventory_2, color: Colors.white, size: 20),
            ),
            title: Text(
              producto.nombre,
              style: TextStyle(
                color: esModoOscuro ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () {
                    setState(() {
                      if (item['cantidad'] > 1) {
                        item['cantidad']--;
                        item['subtotal'] = item['cantidad'] * item['costo'];
                      }
                    });
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    '${item['cantidad']}',
                    style: TextStyle(
                      color: esModoOscuro ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () {
                    setState(() {
                      item['cantidad']++;
                      item['subtotal'] = item['cantidad'] * item['costo'];
                    });
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text(
                  'x L. ${item['costo']}',
                  style: TextStyle(
                    color: esModoOscuro ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'L. ${item['subtotal']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () =>
                      setState(() => _carritoCompra.removeAt(index)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary() {
    final colorTexto = Provider.of<TemaProveedor>(context).esModoOscuro
        ? Colors.white
        : Colors.black;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOTAL:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorTexto,
            ),
          ),
          Text(
            'L. $_totalCompra',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final esModoOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;
    return Card(
      color: esModoOscuro ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Resumen de Adquisición',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: esModoOscuro ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items:',
                  style: TextStyle(
                    color: esModoOscuro ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  '${_carritoCompra.length}',
                  style: TextStyle(
                    color: esModoOscuro ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: esModoOscuro ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'L. $_totalCompra',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showProductPicker,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Agregar Producto',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _finalizarCompra,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Finalizar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? const Color.fromRGBO(30, 30, 30, 1)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Seleccionar Producto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _productosFiltrados.length,
                itemBuilder: (context, index) {
                  final p = _productosFiltrados[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      p.nombre,
                      style: TextStyle(
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Stock actual: ${p.stock}',
                      style: TextStyle(
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _agregarAlCarrito(p);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
          fontSize: isMobile ? 14.0 : 16.0,
        ),
        hintText: 'Ingrese el $label',
        filled: true,
        fillColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : const Color.fromRGBO(244, 243, 243, 1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
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
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
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
          return 'Por favor, ingrese el $label';
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
  }) {
    final temaOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;
    return DropdownButtonFormField<Proveedor>(
      dropdownColor: temaOscuro
          ? const Color.fromRGBO(30, 30, 30, 1)
          : Colors.white,
      value: value,
      items: items
          .map((p) => DropdownMenuItem(value: p, child: Text(p.nombre)))
          .toList(),
      onChanged: onChanged,
      style: TextStyle(color: temaOscuro ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: temaOscuro ? Colors.white70 : Colors.black54,
        ),
        filled: true,
        fillColor: temaOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
