import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_is/controller/repository_caja.dart';
import 'package:proyecto_is/model/caja.dart';
import 'package:proyecto_is/model/movimiento_caja.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen>
    with SingleTickerProviderStateMixin {
  final CajaRepository _cajaRepository = CajaRepository();
  Caja? _cajaActual;
  List<MovimientoCaja> _movimientos = [];
  bool _isLoading = true;
  late TabController _tabController;

  // History filters
  String _filtroHistorial = 'Todo';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<Caja> _historialCajas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
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
  }

  Future<void> _cargarHistorial() async {
    final historial = await _cajaRepository.obtenerHistorialCajas(
      filtro: _filtroHistorial,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
    );
    setState(() {
      _historialCajas = historial;
    });
  }

  Future<void> _abrirCaja() async {
    final montoController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Caja'),
        content: TextField(
          controller: montoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto Inicial'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(montoController.text);
              if (monto != null) {
                await _cajaRepository.abrirCaja(monto);
                Navigator.pop(context);
                _cargarDatos();
              }
            },
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarCaja() async {
    if (_cajaActual == null) return;
    final montoRealController = TextEditingController();

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
              title: const Text('Cerrar Caja'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Esperado en caja: ${NumberFormat.currency(symbol: 'L. ').format(esperado)}',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: montoRealController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto Real en Caja',
                    ),
                    onChanged: (val) => setStateDialog(() {}),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final montoFinal = double.tryParse(
                      montoRealController.text,
                    );
                    if (montoFinal != null) {
                      await _cajaRepository.cerrarCaja(
                        _cajaActual!,
                        montoFinal,
                        diferencia,
                      );
                      Navigator.pop(context);
                      _cargarDatos();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
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

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar $tipo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: conceptoController,
              decoration: const InputDecoration(labelText: 'Concepto'),
            ),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(montoController.text);
              if (monto != null && conceptoController.text.isNotEmpty) {
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
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarMovimiento(MovimientoCaja mov) async {
    final conceptoController = TextEditingController(text: mov.concepto);
    final montoController = TextEditingController(text: mov.monto.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${mov.tipo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: conceptoController,
              decoration: const InputDecoration(labelText: 'Concepto'),
            ),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final monto = double.tryParse(montoController.text);
              if (monto != null && conceptoController.text.isNotEmpty) {
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
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarMovimiento(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar este movimiento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cajaRepository.eliminarMovimiento(id);
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Caja'),
        bottom: TabBar(
          controller: _tabController,
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
              children: [_buildCajaActualTab(), _buildHistorialTab()],
            ),
    );
  }

  Widget _buildCajaActualTab() {
    if (_cajaActual == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.point_of_sale, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'No hay una caja abierta',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _abrirCaja,
              icon: const Icon(Icons.lock_open),
              label: const Text('Abrir Caja'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currency = NumberFormat.currency(symbol: 'L. ');
    final fechaApertura = DateTime.parse(_cajaActual!.fechaApertura);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(fechaApertura);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info
          Card(
            elevation: 4,
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
                      Text('Apertura: $formattedDate'),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Monto Inicial'),
                      Text(
                        currency.format(_cajaActual!.montoApertura),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
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
                  _buildSummaryCard(
                    'Ingresos',
                    _cajaActual!.ingresos,
                    Colors.orange,
                  ),
                  _buildSummaryCard(
                    'Egresos',
                    _cajaActual!.egresos,
                    Colors.red,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Net Profit (Ganancia Neta) - Assuming Sales - Expenses? Or just Sales?
          // User asked for "Ganancia Neta". Usually Sales - Cost, but here maybe Sales + Income - Expenses?
          // Let's assume (Ventas + Ingresos) - Egresos for now, or just Ventas if cost is not tracked here.
          // Given the context, it's likely Cash Flow based: (Ingresos + Ventas) - Egresos.
          // But "Ganancia" usually implies profit. Let's show (Ventas - Egresos) as a simple metric or just the cash balance.
          // The user said "mostrar la ganancia neta". Let's use (Total Ventas + Ingresos - Egresos).
          Card(
            color: Colors.blueGrey.shade50,
            child: ListTile(
              title: const Text('Balance Neto (Ventas + Ingresos - Egresos)'),
              trailing: Text(
                currency.format(
                  _cajaActual!.totalVentas +
                      _cajaActual!.ingresos -
                      _cajaActual!.egresos,
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _registrarMovimiento('Ingreso'),
                icon: const Icon(Icons.add_circle, color: Colors.white),
                label: const Text(
                  'Registrar Ingreso',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              ElevatedButton.icon(
                onPressed: () => _registrarMovimiento('Egreso'),
                icon: const Icon(Icons.remove_circle, color: Colors.white),
                label: const Text(
                  'Registrar Egreso',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'Movimientos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Transactions List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _movimientos.length,
            itemBuilder: (context, index) {
              final mov = _movimientos[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    mov.tipo == 'Ingreso'
                        ? Icons.arrow_downward
                        : mov.tipo == 'Egreso'
                        ? Icons.arrow_upward
                        : Icons.shopping_cart,
                    color: mov.tipo == 'Ingreso'
                        ? Colors.green
                        : mov.tipo == 'Egreso'
                        ? Colors.red
                        : Colors.blue,
                  ),
                  title: Text(mov.concepto),
                  subtitle: Text(
                    DateFormat('HH:mm').format(DateTime.parse(mov.fecha)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currency.format(mov.monto),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: mov.tipo == 'Egreso'
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      if (mov.tipo != 'Venta') ...[
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editarMovimiento(mov),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _eliminarMovimiento(mov.id!),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cerrarCaja,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'CERRAR CAJA',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
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
                  label: const Text('Calendario'),
                  avatar: const Icon(Icons.calendar_today, size: 16),
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
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile(
                  title: Text(
                    'Caja #${caja.id} - ${DateFormat('dd/MM/yyyy').format(inicio)}',
                  ),
                  subtitle: Text(
                    'Estado: ${caja.estado} | ${currency.format(caja.totalVentas)} Ventas',
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
                          const Divider(),
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
                          const Divider(),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _filtroHistorial == label,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
