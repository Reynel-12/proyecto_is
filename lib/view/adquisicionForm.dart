import 'package:flutter/material.dart';
import 'package:proyecto_is/controller/repository_producto.dart';
import 'package:proyecto_is/controller/repository_proveedor.dart';
import 'package:proyecto_is/controller/repository_compra.dart';
import 'package:proyecto_is/model/producto.dart';
import 'package:proyecto_is/model/proveedor.dart';
import 'package:proyecto_is/model/compra.dart';
import 'package:proyecto_is/model/detalle_compra.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:provider/provider.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class AdquisicionForm extends StatefulWidget {
  const AdquisicionForm({super.key});

  @override
  State<AdquisicionForm> createState() => _AdquisicionFormState();
}

class _AdquisicionFormState extends State<AdquisicionForm> {
  final _productoRepo = ProductoRepository();
  final _proveedorRepo = ProveedorRepository();
  final _compraRepo = CompraRepository();

  List<Proveedor> _proveedores = [];
  List<Producto> _productos = [];
  Proveedor? _proveedorSeleccionado;

  // Lista de items en la compra actual
  List<Map<String, dynamic>> _carritoCompra = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final proveedores = await _proveedorRepo.getProveedores();
    final productos = await _productoRepo.getProductos();
    setState(() {
      _proveedores = proveedores;
      _productos = productos;
      _isLoading = false;
    });
  }

  void _agregarAlCarrito(Producto producto) {
    TextEditingController cantidadController = TextEditingController(text: '1');
    TextEditingController costoController = TextEditingController(
      text: producto.costo.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar ${producto.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: costoController,
              decoration: const InputDecoration(labelText: 'Costo Unitario'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              int cant = int.tryParse(cantidadController.text) ?? 0;
              double costo = double.tryParse(costoController.text) ?? 0.0;
              if (cant > 0 && costo > 0) {
                setState(() {
                  _carritoCompra.add({
                    'producto': producto,
                    'cantidad': cant,
                    'costo': costo,
                    'subtotal': cant * costo,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
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
      final compra = Compra(
        proveedorId: _proveedorSeleccionado!.id!,
        fecha: DateTime.now().toString(),
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

      await _compraRepo.registrarCompra(compra, detalles);

      _mostrarMensaje(
        'Éxito',
        'Adquisición registrada correctamente. Stock actualizado.',
        ContentType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      _mostrarMensaje(
        'Error',
        'No se pudo registrar la compra: $e',
        ContentType.failure,
      );
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
    final esModoOscuro = Provider.of<TemaProveedor>(context).esModoOscuro;
    final colorTexto = esModoOscuro ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: esModoOscuro ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Nueva Adquisición'),
        backgroundColor: esModoOscuro ? Colors.black : Colors.white,
        foregroundColor: colorTexto,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selección de Proveedor
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Proveedor>(
                          isExpanded: true,
                          hint: const Text('Seleccionar Proveedor'),
                          value: _proveedorSeleccionado,
                          items: _proveedores
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _proveedorSeleccionado = val),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Productos en esta adquisición:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _carritoCompra.length,
                      itemBuilder: (context, index) {
                        final item = _carritoCompra[index];
                        final producto = item['producto'] as Producto;
                        return ListTile(
                          title: Text(producto.nombre),
                          subtitle: Text(
                            'Cant: ${item['cantidad']} x L. ${item['costo']}',
                          ),
                          trailing: Text(
                            'L. ${item['subtotal']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onLongPress: () =>
                              setState(() => _carritoCompra.removeAt(index)),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => ListView.builder(
                                itemCount: _productos.length,
                                itemBuilder: (context, index) => ListTile(
                                  title: Text(_productos[index].nombre),
                                  subtitle: Text(
                                    'Stock actual: ${_productos[index].stock}',
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _agregarAlCarrito(_productos[index]);
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Producto'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _finalizarCompra,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                            'Finalizar Adquisición',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
