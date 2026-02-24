import 'package:proyecto_is/model/empresa.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_is/controller/pdf_generator_service.dart';
import 'package:proyecto_is/model/producto.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class InventoryPdfPreview extends StatelessWidget {
  final List<Producto> productos;
  final Empresa? empresa;

  const InventoryPdfPreview({Key? key, required this.productos, this.empresa})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Vista previa de inventario',
          style: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
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
      body: PdfPreview(
        build: (format) =>
            PdfGeneratorService.generateInventoryPdf(productos, empresa),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: true,
        canChangePageFormat: true,
        pdfFileName:
            'Inventario_${DateFormat('dd_MM_yyyy_HHmm').format(DateTime.now())}.pdf',
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
