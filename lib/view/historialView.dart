import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class Historial extends StatefulWidget {
  const Historial({super.key});

  @override
  State<Historial> createState() => _HistorialState();
}

class _HistorialState extends State<Historial> {
  DateTime hoy = DateTime.now();

  // ignore: non_constant_identifier_names
  void _DiaSeleccionado(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      hoy = selectedDay;
    });
  }

  StreamSubscription? _ventasSubscription;

  @override
  void dispose() {
    // Cancelar la suscripción cuando el widget se destruye
    _ventasSubscription?.cancel();
    super.dispose();
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
    final double contentPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 24.0);
    final double cardElevation = isMobile ? 3.0 : 5.0;

    // final isConnected = Provider.of<InternetProvider>(context).isConnected;

    return Scaffold(
      backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          'Historial de ventas',
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
          ? _buildDesktopLayout(contentPadding, cardElevation)
          : _buildMobileTabletLayout(contentPadding, cardElevation),
    );
  }

  // Layout para móvil y tablet (diseño vertical)
  Widget _buildMobileTabletLayout(double padding, double elevation) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: ListView(
        children: [
          Column(
            children: [
              _buildCalendario(elevation),
              SizedBox(height: padding),
              _buildResumenVentasDelDia(elevation),
              SizedBox(height: padding),
              const Text(
                'Ventas:',
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: padding / 2),
              _buildListaVentasDelDia(elevation),
            ],
          ),
        ],
      ),
    );
  }

  // Layout para escritorio (diseño horizontal)
  Widget _buildDesktopLayout(double padding, double elevation) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda con calendario y resumen
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildCalendario(elevation),
                SizedBox(height: padding),
                _buildResumenVentasDelDia(elevation),
              ],
            ),
          ),

          SizedBox(width: padding),

          // Columna derecha con lista de ventas
          Expanded(
            flex: 3,
            child: Card(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? const Color.fromRGBO(30, 30, 30, 1)
                  : Colors.white,
              elevation: elevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ventas del día',
                          style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        Text(
                          '${hoy.day}/${hoy.month}/${hoy.year}',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: padding),
                    Expanded(child: _buildListaVentasDelDia(elevation)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calendario responsivo
  Widget _buildCalendario(double elevation) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double rowHeight = isMobile ? 40.0 : (isTablet ? 45.0 : 50.0);
    final double iconSize = isMobile ? 24.0 : (isTablet ? 26.0 : 28.0);
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TableCalendar(
        rowHeight: rowHeight,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            size: iconSize,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            size: iconSize,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12.0 : 14.0,
          ),
          weekendStyle: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12.0 : 14.0,
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: isMobile ? 12.0 : 14.0,
          ),
          weekendTextStyle: TextStyle(
            color: Colors.redAccent,
            fontSize: isMobile ? 12.0 : 14.0,
          ),
        ),
        selectedDayPredicate: (day) => isSameDay(day, hoy),
        focusedDay: hoy,
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        onDaySelected: _DiaSeleccionado,
      ),
    );
  }

  // Resumen de ventas responsivo
  Widget _buildResumenVentasDelDia(double elevation) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double fontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final double iconSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);

    double totalDelDia = 0.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? const Color.fromRGBO(30, 30, 30, 1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: Colors.blueAccent, size: iconSize),
              SizedBox(width: 8),
              Text(
                'Resumen del día',
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildResumenItem(
            'Total de ventas',
            '100',
            fontSize,
            iconSize,
            Icons.receipt_long,
          ),
          SizedBox(height: isMobile ? 8.0 : 12.0),
          _buildResumenItem(
            'Total del día',
            'L. ${totalDelDia.toStringAsFixed(2)}',
            fontSize,
            iconSize,
            Icons.attach_money,
          ),
          SizedBox(height: isMobile ? 8.0 : 12.0),
          _buildResumenItem(
            'Promedio por venta',
            'L. 50.00',
            fontSize,
            iconSize,
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  // Item de resumen responsivo
  Widget _buildResumenItem(
    String label,
    String value,
    double fontSize,
    double iconSize,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white.withOpacity(0.7)
              : Colors.black.withOpacity(0.7),
          size: iconSize,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    );
  }

  // Lista de ventas responsiva
  Widget _buildListaVentasDelDia(double elevation) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final bool isDesktop = screenSize.width >= 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 16.0 : (isTablet ? 17.0 : 18.0);
    final double subtitleFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final double iconSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final double cardPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 16.0);

    // Generamos ventas de ejemplo para demostración
    List<Widget> ventasWidgets = List.generate(
      5,
      (index) => _buildVentaCard(
        index + 1,
        100.0 * (index + 1),
        5,
        '${10 + index}:30 AM',
        titleFontSize,
        subtitleFontSize,
        iconSize,
        cardPadding,
        elevation,
      ),
    );

    // Si hay ventas, mostrar las tarjetas de ventas
    return ListView(
      shrinkWrap: true,
      physics: isDesktop ? null : const NeverScrollableScrollPhysics(),
      children: ventasWidgets,
    );
  }

  // Tarjeta de venta responsiva
  Widget _buildVentaCard(
    int ventaId,
    double total,
    int elementos,
    String hora,
    double titleFontSize,
    double subtitleFontSize,
    double iconSize,
    double cardPadding,
    double elevation,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = screenSize.width >= 900;
    return Card(
      color: Provider.of<TemaProveedor>(context).esModoOscuro
          ? isDesktop
                ? Colors.black
                : const Color.fromRGBO(30, 30, 30, 1)
          : isDesktop
          ? const Color.fromRGBO(244, 243, 243, 1)
          : Colors.white,
      elevation: elevation,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            vertical: cardPadding / 2,
            horizontal: cardPadding,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.blueAccent.withOpacity(0.2),
            child: Icon(
              Icons.shopping_cart,
              color: Colors.blueAccent,
              size: iconSize,
            ),
          ),
          title: Text(
            'Venta #$ventaId',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVentaInfoRow(
                  'Total:',
                  'L. $total',
                  subtitleFontSize,
                  Icons.attach_money,
                ),
                SizedBox(height: 4),
                _buildVentaInfoRow(
                  'Elementos:',
                  '$elementos',
                  subtitleFontSize,
                  Icons.shopping_bag_outlined,
                ),
                SizedBox(height: 4),
                _buildVentaInfoRow(
                  'Hora:',
                  hora,
                  subtitleFontSize,
                  Icons.access_time,
                ),
              ],
            ),
          ),
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1).withOpacity(0.2)
                  : Color.fromRGBO(60, 60, 60, 1).withOpacity(0.2),
            ),
            Column(
              children: List.generate(
                3, // Número de productos por venta
                (index) => _buildProductoItem(
                  'Producto ${index + 1}',
                  index + 1,
                  20.0 * (index + 1),
                  20.0 * (index + 1) * (index + 1),
                  subtitleFontSize,
                  iconSize,
                  cardPadding,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recibo: L. ${total + 50.0}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: subtitleFontSize + 1,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  Text(
                    'Cambio: L. 50.00',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: subtitleFontSize + 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fila de información de venta
  Widget _buildVentaInfoRow(
    String label,
    String value,
    double fontSize,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: fontSize + 2,
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white.withOpacity(0.7)
              : Colors.black.withOpacity(0.7),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.7),
          ),
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Provider.of<TemaProveedor>(context).esModoOscuro
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    );
  }

  // Item de producto en la venta
  Widget _buildProductoItem(
    String nombre,
    int cantidad,
    double precio,
    double subtotal,
    double fontSize,
    double iconSize,
    double padding,
  ) {
    return ListTile(
      leading: Icon(
        Icons.shopping_bag,
        color: Colors.blueAccent,
        size: iconSize,
      ),
      title: Text(
        nombre,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: fontSize + 1,
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.white
              : Colors.black,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            'Cantidad: $cantidad',
            style: TextStyle(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1)
                  : Color.fromRGBO(60, 60, 60, 1),
              fontSize: fontSize,
            ),
          ),
          Text(
            'Precio: L. $precio',
            style: TextStyle(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1)
                  : Color.fromRGBO(60, 60, 60, 1),
              fontSize: fontSize,
            ),
          ),
          Text(
            'SubTotal: L. $subtotal',
            style: TextStyle(
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Color.fromRGBO(220, 220, 220, 1)
                  : Color.fromRGBO(60, 60, 60, 1),
              fontSize: fontSize,
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding / 2,
      ),
    );
  }
}
