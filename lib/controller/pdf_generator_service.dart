import 'dart:typed_data';
import 'package:proyecto_is/model/empresa.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:proyecto_is/model/producto.dart';
import 'package:proyecto_is/model/caja.dart';
import 'package:proyecto_is/model/movimiento_caja.dart';

class PdfGeneratorService {
  // final repositoryEmpresa = RepositoryEmpresa();
  // Empresa? _empresa;

  // void obtenerDatosEmpresa() {
  //   repositoryEmpresa.getEmpresa().then((empresa) {
  //     _empresa = empresa;
  //   });
  // }

  // Método para generar el PDF del inventario
  static Future<Uint8List> generateInventoryPdf(
    List<Producto> productos,
    Empresa? empresa,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(
      symbol: 'L. ',
      decimalDigits: 2,
    );

    // Cálculos
    int totalProductos = 0;
    double totalCosto = 0;
    double totalPrecioVenta = 0;
    double utilidadNeta = 0;

    for (var p in productos) {
      totalProductos += p.stock;
      totalCosto += (p.costo * p.stock);
      totalPrecioVenta += (p.precio * p.stock);
    }
    utilidadNeta = totalPrecioVenta - totalCosto;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'REPORTE DE INVENTARIO',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        empresa?.razonSocial ?? 'Empresa no configurada',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [pw.Text('Fecha: ${dateFormat.format(now)}')],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Resumen de Totales
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RESUMEN GENERAL',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                        'Total de Artículos en Stock:',
                        '$totalProductos',
                      ),
                      _buildSummaryItem(
                        'Total Costo de Inventario:',
                        currencyFormat.format(totalCosto),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                        'Valor Total de Venta:',
                        currencyFormat.format(totalPrecioVenta),
                      ),
                      _buildSummaryItem(
                        'Utilidad Proyectada:',
                        currencyFormat.format(utilidadNeta),
                        isBold: true,
                        color: PdfColors.green800,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            // Tabla de Productos
            pw.Text(
              'DETALLE DE PRODUCTOS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Nombre
                1: const pw.FlexColumnWidth(1), // Stock
                2: const pw.FlexColumnWidth(1.5), // Costo
                3: const pw.FlexColumnWidth(1.5), // Precio
                4: const pw.FlexColumnWidth(1.5), // Total Costo
                5: const pw.FlexColumnWidth(1.5), // Total Venta
              },
              children: [
                // Fila de encabezado
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _buildCell('Producto', isHeader: true),
                    _buildCell('Stock', isHeader: true),
                    _buildCell('Costo Un.', isHeader: true),
                    _buildCell('Precio Un.', isHeader: true),
                    _buildCell('ISV', isHeader: true),
                    _buildCell('Precio Final', isHeader: true),
                    _buildCell('Subt. Costo', isHeader: true),
                    _buildCell('Subt. Venta', isHeader: true),
                  ],
                ),
                // Filas de datos
                ...productos.map((p) {
                  final double subtotalCosto = p.costo * p.stock;
                  final double subtotalVenta = p.precio * p.stock;
                  return pw.TableRow(
                    children: [
                      _buildCell(p.nombre),
                      _buildCell('${p.stock}'),
                      _buildCell(p.costo.toStringAsFixed(2)),
                      _buildCell(p.precio.toStringAsFixed(2)),
                      _buildCell('${p.isv.toString()} %'),
                      _buildCell(p.precioVenta.toStringAsFixed(2)),
                      _buildCell(subtotalCosto.toStringAsFixed(2)),
                      _buildCell(subtotalVenta.toStringAsFixed(2)),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Footer(
              margin: const pw.EdgeInsets.only(top: 20),
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
              ),
              trailing: pw.Text("Pag. "),
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryItem(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isBlack = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isBlack
              ? PdfColors.black
              : isHeader
              ? PdfColors.white
              : PdfColors.black,
        ),
      ),
    );
  }

  // Método para generar el PDF del cierre de caja
  static Future<Uint8List> generateCierreCajaPdf({
    required Caja caja,
    required List<MovimientoCaja> movimientos,
    Empresa? empresa,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(
      symbol: 'L. ',
      decimalDigits: 2,
    );

    // Cálculos de totales por método de pago
    double ventasEfectivo = 0;
    double ventasTarjeta = 0;
    double ventasTransferencia = 0;

    double ingresosEfectivo = 0;
    double ingresosTarjeta = 0;
    double ingresosTransferencia = 0;

    double egresosEfectivo = 0;
    double egresosTarjeta = 0;
    double egresosTransferencia = 0;

    for (var m in movimientos) {
      if (m.tipo == 'Venta') {
        if (m.metodoPago == 'Efectivo') ventasEfectivo += m.monto;
        if (m.metodoPago == 'Tarjeta') ventasTarjeta += m.monto;
        if (m.metodoPago == 'Transferencia') ventasTransferencia += m.monto;
      } else if (m.tipo == 'Ingreso') {
        if (m.metodoPago == 'Efectivo') ingresosEfectivo += m.monto;
        if (m.metodoPago == 'Tarjeta') ingresosTarjeta += m.monto;
        if (m.metodoPago == 'Transferencia') ingresosTransferencia += m.monto;
      } else if (m.tipo == 'Egreso') {
        if (m.metodoPago == 'Efectivo') egresosEfectivo += m.monto;
        if (m.metodoPago == 'Tarjeta') egresosTarjeta += m.monto;
        if (m.metodoPago == 'Transferencia') egresosTransferencia += m.monto;
      }
    }

    final double totalVentas =
        ventasEfectivo + ventasTarjeta + ventasTransferencia;
    final double totalIngresos =
        ingresosEfectivo + ingresosTarjeta + ingresosTransferencia;
    final double totalEgresos =
        egresosEfectivo + egresosTarjeta + egresosTransferencia;

    // Efectivo Esperado
    final double efectivoEsperado =
        caja.montoApertura +
        ventasEfectivo +
        ingresosEfectivo -
        egresosEfectivo;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'REPORTE DE CIERRE DE CAJA',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      if (empresa != null)
                        pw.Text(
                          empresa.razonSocial,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey700,
                          ),
                        ),
                      pw.Text(
                        'ID Caja: #${caja.id}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Generado: ${dateFormat.format(now)}'),
                      pw.Text(
                        'Estado: ${caja.estado}',
                        style: pw.TextStyle(
                          color: caja.estado == 'Abierta'
                              ? PdfColors.green
                              : PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Información de Apertura y Cierre
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildCell(
                      'DETALLES DE APERTURA',
                      isHeader: true,
                      isBlack: true,
                    ),
                    _buildCell(
                      'DETALLES DE CIERRE',
                      isHeader: true,
                      isBlack: true,
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Cajero:', caja.cajeroAbre),
                          _buildInfoRow(
                            'Fecha:',
                            dateFormat.format(
                              DateTime.parse(caja.fechaApertura),
                            ),
                          ),
                          _buildInfoRow(
                            'Monto Inicial:',
                            currencyFormat.format(caja.montoApertura),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Cajero:', caja.cajeroCierra),
                          _buildInfoRow(
                            'Fecha:',
                            caja.fechaCierre != null
                                ? dateFormat.format(
                                    DateTime.parse(caja.fechaCierre!),
                                  )
                                : 'N/A',
                          ),
                          _buildInfoRow(
                            'Monto Final (Real):',
                            caja.montoCierre != null
                                ? currencyFormat.format(caja.montoCierre)
                                : 'N/A',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Resumen Financiero por Método de Pago
            pw.Text(
              'RESUMEN FINANCIERO',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2), // Concepto
                1: const pw.FlexColumnWidth(1.5), // Efectivo
                2: const pw.FlexColumnWidth(1.5), // Tarjeta
                3: const pw.FlexColumnWidth(1.5), // Transferencia
                4: const pw.FlexColumnWidth(1.5), // Total
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _buildCell('Concepto', isHeader: true),
                    _buildCell('Efectivo', isHeader: true),
                    _buildCell('Tarjeta', isHeader: true),
                    _buildCell('Transferencia', isHeader: true),
                    _buildCell('Total', isHeader: true),
                  ],
                ),
                _buildFinancialRow(
                  'Ventas',
                  ventasEfectivo,
                  ventasTarjeta,
                  ventasTransferencia,
                  totalVentas,
                  currencyFormat,
                  isPositive: true,
                ),
                _buildFinancialRow(
                  'Ingresos',
                  ingresosEfectivo,
                  ingresosTarjeta,
                  ingresosTransferencia,
                  totalIngresos,
                  currencyFormat,
                  isPositive: true,
                ),
                _buildFinancialRow(
                  'Egresos',
                  egresosEfectivo,
                  egresosTarjeta,
                  egresosTransferencia,
                  totalEgresos,
                  currencyFormat,
                  isPositive: false,
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'TOTAL NETO',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    _buildCell(
                      currencyFormat.format(
                        ventasEfectivo + ingresosEfectivo - egresosEfectivo,
                      ),
                    ),
                    _buildCell(
                      currencyFormat.format(
                        ventasTarjeta + ingresosTarjeta - egresosTarjeta,
                      ),
                    ),
                    _buildCell(
                      currencyFormat.format(
                        ventasTransferencia +
                            ingresosTransferencia -
                            egresosTransferencia,
                      ),
                    ),
                    _buildCell(
                      currencyFormat.format(
                        totalVentas + totalIngresos - totalEgresos,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Balance de Caja (Efectivo)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'BALANCE DE EFECTIVO',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildBalanceRow(
                    'Monto Inicial (+)',
                    caja.montoApertura,
                    currencyFormat,
                  ),
                  _buildBalanceRow(
                    'Ventas Efectivo (+)',
                    ventasEfectivo,
                    currencyFormat,
                  ),
                  _buildBalanceRow(
                    'Ingresos Efectivo (+)',
                    ingresosEfectivo,
                    currencyFormat,
                  ),
                  _buildBalanceRow(
                    'Egresos Efectivo (-)',
                    egresosEfectivo,
                    currencyFormat,
                  ),
                  pw.Divider(),
                  _buildBalanceRow(
                    'Efectivo Esperado (=)',
                    efectivoEsperado,
                    currencyFormat,
                    isBold: true,
                  ),
                  _buildBalanceRow(
                    'Monto Real (Cierre)',
                    caja.montoCierre ?? 0.0,
                    currencyFormat,
                    isBold: true,
                  ),
                  pw.Divider(),
                  _buildBalanceRow(
                    'DIFERENCIA',
                    caja.diferencia ?? 0.0,
                    currencyFormat,
                    isBold: true,
                    color: (caja.diferencia ?? 0) < 0
                        ? PdfColors.red
                        : ((caja.diferencia ?? 0) > 0
                              ? PdfColors.green
                              : PdfColors.black),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            // Lista detallada de movimientos
            pw.Text(
              'DETALLE DE MOVIMIENTOS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5), // Hora
                1: const pw.FlexColumnWidth(1.5), // Tipo
                2: const pw.FlexColumnWidth(3), // Concepto
                3: const pw.FlexColumnWidth(2), // Método
                4: const pw.FlexColumnWidth(2), // Monto
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _buildCell('Hora', isHeader: true),
                    _buildCell('Tipo', isHeader: true),
                    _buildCell('Concepto', isHeader: true),
                    _buildCell('Método', isHeader: true),
                    _buildCell('Monto', isHeader: true),
                  ],
                ),
                ...movimientos.map((m) {
                  final hora = DateFormat(
                    'HH:mm',
                  ).format(DateTime.parse(m.fecha));
                  return pw.TableRow(
                    children: [
                      _buildCell(hora),
                      _buildCell(m.tipo),
                      _buildCell(m.concepto),
                      _buildCell(m.metodoPago),
                      _buildCell(currencyFormat.format(m.monto)),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 20),
            // Firma
            pw.SizedBox(height: 50),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildSignatureLine('Firma Cajero'),
                _buildSignatureLine('Firma Supervisor/Administrador'),
              ],
            ),
            pw.Footer(
              margin: const pw.EdgeInsets.only(top: 20),
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
              ),
              trailing: pw.Text("Pag. "),
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label ',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.TableRow _buildFinancialRow(
    String label,
    double efectivo,
    double tarjeta,
    double transferencia,
    double total,
    NumberFormat fmt, {
    required bool isPositive,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ),
        _buildCell(fmt.format(efectivo)),
        _buildCell(fmt.format(tarjeta)),
        _buildCell(fmt.format(transferencia)),
        _buildCell(fmt.format(total)),
      ],
    );
  }

  static pw.Widget _buildBalanceRow(
    String label,
    double amount,
    NumberFormat fmt, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            fmt.format(amount),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureLine(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 150,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}
