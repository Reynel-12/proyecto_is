import 'package:proyecto_is/controller/repository_devolucion.dart';
import 'package:proyecto_is/view/nueva_devolucion_view.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DevolucionesView extends StatefulWidget {
  const DevolucionesView({super.key});

  @override
  State<DevolucionesView> createState() => _DevolucionesViewState();
}

class _DevolucionesViewState extends State<DevolucionesView> {
  final RepositoryDevolucion _repository = RepositoryDevolucion();
  List<Map<String, dynamic>> _devoluciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevoluciones();
  }

  Future<void> _loadDevoluciones() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getAllDevolucionesDetalladas();
      setState(() {
        _devoluciones = list;
      });
    } catch (e) {
      debugPrint("Error loading devoluciones: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<TemaProveedor>(context);
    final isDarkMode = themeProvider.esModoOscuro;
    final backgroundColor = isDarkMode ? Colors.black : const Color(0xFFF4F3F3);
    final textColor = isDarkMode ? Colors.white : Colors.black;

    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Devoluciones',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devoluciones.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_return_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay devoluciones registradas',
                    style: TextStyle(color: textColor, fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _devoluciones.length,
              itemBuilder: (context, index) {
                return DevolucionCard(
                  devolucion: _devoluciones[index],
                  repository: _repository,
                  isDarkMode: isDarkMode,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NuevaDevolucionView(),
            ),
          );
          if (result == true) {
            _loadDevoluciones();
          }
        },
        label: const Text(
          'Nueva devolución',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

class DevolucionCard extends StatefulWidget {
  final Map<String, dynamic> devolucion;
  final RepositoryDevolucion repository;
  final bool isDarkMode;

  const DevolucionCard({
    super.key,
    required this.devolucion,
    required this.repository,
    required this.isDarkMode,
  });

  @override
  State<DevolucionCard> createState() => _DevolucionCardState();
}

class _DevolucionCardState extends State<DevolucionCard> {
  List<Map<String, dynamic>>? _detalles;
  bool _isExpanded = false;
  bool _loadingDetails = false;

  Future<void> _fetchDetails() async {
    if (_detalles != null) return;
    setState(() => _loadingDetails = true);
    try {
      final details = await widget.repository.getDetallesByDevolucion(
        widget.devolucion['id_devolucion'] as int,
      );
      setState(() {
        _detalles = details;
      });
    } catch (e) {
      debugPrint("Error fetching return details: $e");
    } finally {
      setState(() => _loadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dev = widget.devolucion;
    final fecha = DateTime.parse(dev['fecha']);
    final total = dev['total_devuelto'] as double;
    final factura = dev['numero_factura'] ?? 'N/A';
    var cliente = dev['nombre_cliente'].toString();
    final tipo = dev['tipo_reembolso'] ?? '';
    var usuario = dev['nombre_usuario'].toString();
    var motivo = dev['motivo'].toString();

    cliente.isEmpty || cliente == '' ? cliente = 'Consumidor Final' : cliente;
    usuario.isEmpty || usuario == '' ? usuario = 'Desconocido' : usuario;
    motivo.isEmpty || motivo == ''
        ? motivo = 'Sin motivo especificado'
        : motivo;

    final cardColor = widget.isDarkMode
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final subTextColor = widget.isDarkMode ? Colors.white70 : Colors.black54;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
            if (expanded) _fetchDetails();
          },
          leading: CircleAvatar(
            backgroundColor: Colors.orange.withAlpha(50),
            child: const Icon(Icons.replay, color: Colors.orange),
          ),
          title: Text(
            'Factura: $factura',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'Cliente: $cliente',
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'L ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tipo,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        'Fecha',
                        DateFormat('dd/MM/yyyy hh:mm a').format(fecha),
                        subTextColor,
                      ),
                      _buildInfoItem('Usuario', usuario, subTextColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem('Motivo', motivo, subTextColor),
                  const SizedBox(height: 16),
                  Text(
                    'Detalle de Productos',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingDetails)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_detalles != null && _detalles!.isNotEmpty)
                    _buildDetailsTable(textColor, subTextColor)
                  else
                    const Text('No hay detalles disponibles'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTable(Color textColor, Color subTextColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.black26 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(
        columnSpacing: 16,
        horizontalMargin: 12,
        headingRowHeight: 35,
        dataRowMinHeight: 30,
        dataRowMaxHeight: 50,
        columns: [
          DataColumn(
            label: Text(
              'Producto',
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Cant.',
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Estado',
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ),
          DataColumn(
            label: Text(
              'Total',
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ),
        ],
        rows: _detalles!.map((item) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 100,
                  child: Text(
                    item['producto_nombre'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${item['cantidad']} ${item['unidad_medida']}',
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
              ),
              DataCell(_buildConditionBadge(item['estado_producto'])),
              DataCell(
                Text(
                  'L ${item['subtotal'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConditionBadge(String condition) {
    Color color;
    String label;
    switch (condition) {
      case 'BUENO':
        color = Colors.green;
        label = 'Bueno';
        break;
      case 'DEFECTUOSO':
        color = Colors.red;
        label = 'Defectuoso';
        break;
      case 'NO_REINGRESA':
        color = Colors.grey;
        label = 'No Reingresa';
        break;
      default:
        color = Colors.blue;
        label = condition;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
