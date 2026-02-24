import 'package:flutter/material.dart';
import 'package:proyecto_is/controller/pdf_generator_service.dart';
import 'package:proyecto_is/model/caja.dart';
import 'package:proyecto_is/model/movimiento_caja.dart';
import 'package:proyecto_is/model/empresa.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CajaPdfPreview extends StatelessWidget {
  final Caja caja;
  final List<MovimientoCaja> movimientos;
  final Empresa? empresa;

  const CajaPdfPreview({
    Key? key,
    required this.caja,
    required this.movimientos,
    this.empresa,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);
    final themeProvider = Provider.of<TemaProveedor>(context);
    final isDark = themeProvider.esModoOscuro;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Vista previa de reporte de caja',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        backgroundColor: isDark
            ? Colors.black
            : const Color.fromRGBO(244, 243, 243, 1),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: PdfPreview(
        build: (format) => PdfGeneratorService.generateCierreCajaPdf(
          caja: caja,
          movimientos: movimientos,
          empresa: empresa,
        ),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: true,
        canChangePageFormat: true,
        pdfFileName:
            'Caja_${caja.id}_${DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now())}.pdf',
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
