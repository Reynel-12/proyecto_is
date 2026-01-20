import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/view/adquisicionForm.dart';
import 'package:proyecto_is/view/caja_screen.dart';
import 'package:proyecto_is/view/dashBoardCard.dart';
import 'package:proyecto_is/view/historialView.dart';
import 'package:proyecto_is/view/inventarioView.dart';
import 'package:proyecto_is/view/login_view.dart';
import 'package:proyecto_is/view/productoForm.dart';
import 'package:proyecto_is/view/proveedoresView.dart';
import 'package:proyecto_is/view/usuarios_view.dart';
import 'package:proyecto_is/view/ventasView.dart';
import 'package:proyecto_is/view/configuracion_sar_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  //final CameraDescription camera;
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    obtenerTipo();
  }

  String tipo = '';
  String userFullname = '';

  void deletePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('email');
    prefs.remove('password');
    prefs.remove('user');
    prefs.remove('tipo');
    prefs.remove('estado');
  }

  Future<void> obtenerTipo() async {
    final prefs = await SharedPreferences.getInstance();
    String? tipo = prefs.getString('tipo');
    String? fullname = prefs.getString('user_fullname');
    setState(() {
      this.tipo = tipo ?? '';
      userFullname = fullname ?? 'Usuario';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);

    bool isAdmin = tipo == 'Administrador';

    final List<DashboardCardData> cards = [
      if (isAdmin)
        DashboardCardData(
          icon: Icons.point_of_sale,
          title: 'Caja',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CajaScreen()),
          ),
        ),
      DashboardCardData(
        icon: Icons.shopping_cart_checkout,
        title: 'Ventas',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Ventas()),
        ),
      ),
      DashboardCardData(
        icon: Icons.history,
        title: 'Historial de ventas',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Historial()),
        ),
      ),
      if (isAdmin)
        DashboardCardData(
          icon: Icons.inventory,
          title: 'Inventario',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Inventario()),
          ),
        ),
      if (isAdmin)
        DashboardCardData(
          icon: Icons.production_quantity_limits,
          title: 'Nuevo producto',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Nuevoproducto()),
          ),
        ),
      if (isAdmin)
        DashboardCardData(
          icon: Icons.shopping_bag,
          title: 'Adquisiciones',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdquisicionForm()),
          ),
        ),
      if (isAdmin)
        DashboardCardData(
          icon: Icons.local_shipping,
          title: 'Proveedores',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProveedoresView()),
          ),
        ),
      if (isAdmin)
        DashboardCardData(
          icon: Icons.manage_accounts,
          title: 'Usuarios',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Usuarios()),
          ),
        ),
      if (isAdmin)
        DashboardCardData(
          icon: Icons.settings,
          title: 'Configuración SAR',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConfiguracionSarView()),
          ),
        ),
      DashboardCardData(
        icon: Icons.logout,
        title: 'Cerrar sesión',
        onTap: () {
          deletePreferences();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Login()),
          );
        },
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
            actions: [
              AnimatedSwitcher(
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
                  splashRadius: 25,
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Provider.of<TemaProveedor>(context).esModoOscuro
              ? Colors.black
              : Colors.white,
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.grey[900]
                      : Colors.blueAccent,
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.black
                        : Colors.blueAccent,
                  ),
                ),
                accountName: Text(
                  userFullname,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(
                  tipo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...cards.map((card) {
                      return ListTile(
                        leading: Icon(
                          card.icon,
                          color:
                              Provider.of<TemaProveedor>(context).esModoOscuro
                              ? Colors.white
                              : Colors.blueAccent,
                        ),
                        title: Text(
                          card.title,
                          style: TextStyle(
                            color:
                                Provider.of<TemaProveedor>(context).esModoOscuro
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          card.onTap();
                        },
                      );
                    }).toList(),
                    const Divider(),
                    SwitchListTile(
                      title: const Text(
                        'Modo noche',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      secondary: Icon(
                        Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: Provider.of<TemaProveedor>(context).esModoOscuro
                            ? Colors.amber
                            : Colors.blueAccent,
                      ),
                      value: Provider.of<TemaProveedor>(context).esModoOscuro,
                      onChanged: (bool value) {
                        Provider.of<TemaProveedor>(
                          context,
                          listen: false,
                        ).cambiarTema();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
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
