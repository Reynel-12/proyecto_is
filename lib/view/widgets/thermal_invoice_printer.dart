import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ThermalInvoicePrinter {
  // Configuración de márgenes y espaciado (en puntos)
  static const double _marginLeft = 4.0;
  static const double _marginRight = 4.0;
  static const double _lineSpacing = 1.5;
  static const double _sectionSpacing = 6.0;
  final InvoiceData data;

  ThermalInvoicePrinter({required this.data});

  /// Genera el PDF adaptado al ancho del papel
  Future<Uint8List> generatePdf({required double paperWidthMm}) async {
    final pdf = pw.Document();

    final double paperWidthPt = paperWidthMm * 2.8346;

    // --- Contenido (mismo de antes) ---
    final double contentWidth = paperWidthPt - _marginLeft - _marginRight;
    final content = _buildInvoiceContent(contentWidth);

    // --- MultiPage: Altura DINÁMICA automática ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(paperWidthPt, double.infinity, marginAll: 0),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: _marginLeft,
              vertical: 8,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content,
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Construye el contenido de la factura
  List<pw.Widget> _buildInvoiceContent(double maxWidth) {
    final List<pw.Widget> children = [];

    // --- ENCABEZADO ---
    children.add(_buildHeader(maxWidth));

    // --- LÍNEA DIVISORIA ---
    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_divider(maxWidth));

    // --- DETALLES DE LA EMPRESA ---
    children.add(_buildCompanyInfo(maxWidth));

    // --- INFORMACIÓN DEL CLIENTE ---
    if (data.customerName.isNotEmpty) {
      children.add(pw.SizedBox(height: _sectionSpacing));
      children.add(_buildCustomerInfo(maxWidth));
    }

    // --- DETALLES DE LA FACTURA ---
    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_buildInvoiceDetails(maxWidth));

    // --- LÍNEA DIVISORIA ---
    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_divider(maxWidth));

    // --- ITEMS ---
    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_buildItemsTable(maxWidth));

    // --- TOTALES ---
    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_buildTotals(maxWidth));

    children.add(pw.SizedBox(height: _sectionSpacing));
    children.add(_centerText(data.notes, maxWidth));

    // Corte de papel (opcional, depende de la impresora)
    children.add(pw.SizedBox(height: 20));

    return children;
  }

  /// Encabezado (logo opcional + nombre del negocio)
  pw.Widget _buildHeader(double maxWidth) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.SizedBox(height: 6),
          _boldText(
            data.businessName,
            maxWidth,
            align: pw.TextAlign.center,
            fontSize: 11,
          ),
          _regularText(
            data.businessAddress,
            maxWidth,
            align: pw.TextAlign.center,
          ),
          if (data.businessPhone.isNotEmpty)
            _regularText(
              "Tel: ${data.businessPhone}",
              maxWidth,
              align: pw.TextAlign.center,
            ),
        ],
      ),
    );
  }

  /// Información de la empresa
  pw.Widget _buildCompanyInfo(double maxWidth) {
    return pw.Center(
      child: pw.Column(
        children: [
          _boldText(
            "Tipo pedido: ${data.typeOrder}",
            maxWidth,
            align: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Información del cliente
  pw.Widget _buildCustomerInfo(double maxWidth) {
    final bool isNarrow = maxWidth < 180;
    final String name = data.customerName.length > 22
        ? "${data.customerName.substring(0, 20)}.."
        : data.customerName;

    return pw.Column(
      crossAxisAlignment: isNarrow
          ? pw.CrossAxisAlignment.center
          : pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _boldText("Cliente: ", maxWidth),
            _regularText(name, maxWidth),
          ],
        ),
        pw.Row(
          children: [
            _boldText("Método de pago: ", maxWidth),
            _regularText(data.metodoPago, maxWidth),
          ],
        ),
      ],
    );
  }

  /// Detalles de la factura
  pw.Widget _buildInvoiceDetails(double maxWidth) {
    final bool isNarrow = maxWidth < 180;

    final leftColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _regularText("N°: ${data.invoiceNumber}", maxWidth),
        _regularText("Fecha: ${data.date} ${data.hora}", maxWidth),
      ],
    );

    if (!isNarrow && data.cashier.isNotEmpty) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          leftColumn,
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _regularText("Cajero:", maxWidth * 0.4),
              _regularText(data.cashier, maxWidth * 0.4),
            ],
          ),
        ],
      );
    } else {
      // En 58mm: todo en columna
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          leftColumn,
          if (data.cashier.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _regularText("Cajero: ${data.cashier}", maxWidth),
            ),
        ],
      );
    }
  }

  /// Tabla de ítems (adaptativa)
  pw.Widget _buildItemsTable(double maxWidth) {
    final bool isNarrow = maxWidth < 180;

    if (isNarrow) {
      // === MODO 58mm: Lista vertical ===
      return pw.Column(
        children: data.items.map((item) {
          final desc = item.description.length > 20
              ? "${item.description.substring(0, 18)}.."
              : item.description;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _boldText(desc, maxWidth, fontSize: 9),
              pw.Row(
                children: [
                  _regularText("${item.quantity}x", maxWidth * 0.2),
                  pw.Spacer(),
                  _regularText(
                    "${NumberFormat.currency(symbol: '', decimalDigits: 2).format(item.unitPrice)}",
                    maxWidth * 0.35,
                    align: pw.TextAlign.right,
                  ),
                  pw.Spacer(),
                  _boldText(
                    NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    ).format(item.total),
                    maxWidth * 0.35,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
            ],
          );
        }).toList(),
      );
    } else {
      // === MODO 80mm: Tabla alineada ===
      final headers = ["Descripción", "Cant", "P.Unit", "SubTotal"];
      final colWidths = {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.3),
      };

      return pw.Table(
        border: pw.TableBorder.all(style: pw.BorderStyle.none),
        columnWidths: colWidths,
        children: [
          // Encabezados
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: headers
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(3),
                    child: _boldText(h, 50, fontSize: 8),
                  ),
                )
                .toList(),
          ),
          // Filas
          ...data.items.map((item) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: _regularText(item.description, 100),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: _regularText(
                    item.quantity.toStringAsFixed(0),
                    30,
                    align: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: _regularText(
                    NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    ).format(item.unitPrice),
                    40,
                    align: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: _boldText(
                    NumberFormat.currency(
                      symbol: '',
                      decimalDigits: 2,
                    ).format(item.total),
                    40,
                    align: pw.TextAlign.right,
                  ),
                ),
              ],
            );
          }),
        ],
      );
    }
  }

  /// Totales
  pw.Widget _buildTotals(double maxWidth) {
    final currency = NumberFormat.currency(
      symbol: data.currencySymbol,
      decimalDigits: 2,
    );
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: maxWidth * 0.6,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _divider(maxWidth * 0.6),
            _totalRow("TOTAL:", currency.format(data.total), maxWidth * 0.6),
            _totalRow(
              "RECIBIDO:",
              currency.format(data.recibido),
              maxWidth * 0.6,
            ),
            _totalRow(
              "VUELTO:",
              currency.format(data.recibido - data.total),
              maxWidth * 0.6,
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets auxiliares ---
  pw.Widget _regularText(
    String text,
    double maxWidth, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        // font: _fontRegular,
        fontSize: 9,
        lineSpacing: _lineSpacing,
      ),
      textAlign: align,
      maxLines: 10,
      overflow: pw.TextOverflow.clip,
    );
  }

  pw.Widget _boldText(
    String text,
    double maxWidth, {
    pw.TextAlign align = pw.TextAlign.left,
    double? fontSize,
  }) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        // font: _fontBold,
        fontSize: fontSize ?? 10,
        lineSpacing: _lineSpacing,
      ),
      textAlign: align,
    );
  }

  pw.Widget _centerText(String text, double maxWidth) {
    return pw.Align(
      alignment: pw.Alignment.center,
      child: _regularText(text, maxWidth, align: pw.TextAlign.center),
    );
  }

  pw.Widget _divider(double width) {
    return pw.Container(width: width, height: 1, color: PdfColors.grey800);
  }

  pw.Widget _totalRow(String label, String value, double width) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _regularText(label, width * 0.5),
        _boldText(value, width * 0.5, align: pw.TextAlign.right),
      ],
    );
  }
}

/// ---------------------------------------------------------------
/// MODELO DE DATOS
/// ---------------------------------------------------------------
class InvoiceData {
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String typeOrder;
  final String invoiceNumber;
  final String date;
  final String hora;
  final String cashier;
  final String customerName;
  final String customerAddress;
  final List<InvoiceItem> items;
  final double total;
  final double recibido;
  final String metodoPago;
  final String currencySymbol;
  final String notes;
  InvoiceData({
    required this.businessName,
    this.businessAddress = '',
    this.businessPhone = '',
    required this.typeOrder,
    required this.invoiceNumber,
    required this.date,
    required this.hora,
    this.cashier = '',
    this.customerName = '',
    this.customerAddress = '',
    required this.items,
    required this.total,
    required this.recibido,
    required this.metodoPago,
    this.currencySymbol = 'L. ',
    this.notes = '',
  });
}

class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  }) : total = quantity * unitPrice;
}

class ThermalInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final double paperWidthMm;

  const ThermalInvoicePreview({
    Key? key,
    required this.data,
    this.paperWidthMm = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Factura',
          style: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: ThermalInvoicePrinter(
          data: data,
        ).generatePdf(paperWidthMm: paperWidthMm),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return PdfPreview(
            build: (format) => snapshot.data!,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            initialPageFormat: PdfPageFormat(
              paperWidthMm * 2.8346,
              1000,
              marginAll: 0,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.print),
        onPressed: () async {
          final pdf = await ThermalInvoicePrinter(
            data: data,
          ).generatePdf(paperWidthMm: paperWidthMm);
          await Printing.layoutPdf(
            onLayout: (format) => pdf,
            name: 'factura_${data.invoiceNumber}.pdf',
          );
        },
      ),
    );
  }
}
