import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/view/adquisicionForm.dart';
import 'package:proyecto_is/view/caja_screen.dart';
import 'package:proyecto_is/view/dashBoardCard.dart';
import 'package:proyecto_is/view/historialView.dart';
import 'package:proyecto_is/view/inventarioView.dart';
import 'package:proyecto_is/view/productoForm.dart';
import 'package:proyecto_is/view/proveedoresView.dart';
import 'package:proyecto_is/view/ventasView.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  //final CameraDescription camera;
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);

    final List<DashboardCardData> cards = [
      DashboardCardData(
        icon: Icons.point_of_sale,
        title: 'Caja',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CajaScreen()),
        ),
      ),
      DashboardCardData(
        icon: Icons.inventory,
        title: 'Inventario',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Inventario()),
        ),
      ),
      DashboardCardData(
        icon: Icons.add_shopping_cart,
        title: 'Ventas',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Ventas()),
        ),
      ),
      DashboardCardData(
        icon: Icons.add_box,
        title: 'Nuevo producto',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Nuevoproducto()),
        ),
      ),
      DashboardCardData(
        icon: Icons.people,
        title: 'Proveedores',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProveedoresView()),
        ),
      ),
      DashboardCardData(
        icon: Icons.people,
        title: 'Adquisiciones',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdquisicionForm()),
        ),
      ),
      DashboardCardData(
        icon: Icons.history,
        title: 'Historial de Ventas',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Historial()),
        ),
      ),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.black
              : const Color.fromRGBO(244, 243, 243, 1),
          child: AppBar(
            title: Text(
              'Empresa',
              style: TextStyle(
                color: Provider.of<TemaProveedor>(context).esModoOscuro
                    ? Colors.white
                    : Colors.black,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent, // Color de fondo de la barra
            leading: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: IconButton(
                key: ValueKey<bool>(
                  Provider.of<TemaProveedor>(context).esModoOscuro,
                ),
                icon: Icon(
                  Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                onPressed: () {
                  // Cambiar el tema al presionar el botón
                  Provider.of<TemaProveedor>(
                    context,
                    listen: false,
                  ).cambiarTema();
                },
                splashRadius:
                    25, // Ajusta el tamaño del efecto de onda al presionar
              ),
            ),
          ),
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        color: Provider.of<TemaProveedor>(context).esModoOscuro
            ? Colors.black
            : Color.fromRGBO(244, 243, 243, 1),
        child: DashboardGrid(cards: cards),
      ),
    );
  }
}
