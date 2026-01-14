import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_is/controller/repository_user.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/view/nuevo_usuario.dart';
import 'package:proyecto_is/view/widgets/loading.dart';

// ignore: must_be_immutable
class PerfilUsuario extends StatefulWidget {
  String docID;
  PerfilUsuario({super.key, required this.docID});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  String nombre = '';
  String apellido = '';
  String correo = '';
  String telefono = '';
  String rol = '';
  String estado = '';
  String contrasena = '';
  bool isLoading = true;
  bool _isProcessing = false;

  final repo = RepositoryUser();

  @override
  void dispose() {
    super.dispose();
  }

  ///Método para obtener el ultimo código de la orden de ttrabajo, dentro de la colección Control
  Future<void> _obtenerInfoUsuario() async {
    setState(() {
      isLoading = true;
    });
    final user = await repo.getUserById(int.parse(widget.docID));
    if (user != null) {
      setState(() {
        nombre = user.nombre;
        apellido = user.apellido;
        correo = user.correo;
        telefono = user.telefono;
        rol = user.tipo;
        estado = user.estado;
        contrasena = user.contrasena;
        isLoading = false;
      });
    }
    print('Correo: ${user?.correo}');
    print('Apellido: ${user?.apellido}');
    print('Nombre: ${user?.nombre}');
    print('Telefono: ${user?.telefono}');
    print('Tipo: ${user?.tipo}');
    print('Estado: ${user?.estado}');
    print('Contrasena: ${user?.contrasena}');
  }

  @override
  void initState() {
    super.initState();
    _obtenerInfoUsuario();
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

    return Scaffold(
      backgroundColor: Provider.of<TemaProveedor>(context).esModoOscuro
          ? Colors.black
          : const Color.fromRGBO(244, 243, 243, 1),
      appBar: AppBar(
        title: Text(
          'Información',
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
        actions: [
          isLoading
              ? Container()
              : IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: isMobile ? 24.0 : 28.0,
                    color: Provider.of<TemaProveedor>(context).esModoOscuro
                        ? Colors.white
                        : Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NuevoUsuario(
                          isEdit: true,
                          uid: widget.docID,
                          nombre: nombre,
                          apellido: apellido,
                          telefono: telefono,
                          tipo: rol,
                          estado: estado,
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      body: isLoading
          ? CargandoInventario()
          : Stack(
              children: [
                isDesktop
                    ? _buildDesktopLayout(contentPadding, cardElevation)
                    : _buildMobileTabletLayout(contentPadding, cardElevation),
                if (_isProcessing) CircularProgressIndicator(),
              ],
            ),
    );
  }

  // Layout para móvil y tablet (diseño vertical)
  Widget _buildMobileTabletLayout(double padding, double elevation) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildProductInfo(elevation)],
            ),
          ),
        ),
      ],
    );
  }

  // Layout para escritorio (diseño horizontal)
  Widget _buildDesktopLayout(double padding, double elevation) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda con información del producto
          Expanded(flex: 2, child: _buildProductInfo(elevation)),
        ],
      ),
    );
  }

  Widget _buildProductInfo(double elevation) {
    // Ajustamos tamaños según el dispositivo
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    final double titleFontSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final double infoFontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);

    return Card(
      color: Provider.of<TemaProveedor>(context).esModoOscuro
          ? const Color.fromRGBO(30, 30, 30, 1)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: elevation,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: isMobile ? 24.0 : 28.0,
                  color: Provider.of<TemaProveedor>(context).esModoOscuro
                      ? Colors.white
                      : Colors.black,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$nombre $apellido',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Provider.of<TemaProveedor>(context).esModoOscuro
                          ? Colors.white
                          : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12.0 : 16.0),
            _infoRow('Correo', correo, infoFontSize),
            _infoRow('Teléfono', telefono, infoFontSize),
            _infoRow('Rol del usuario', rol, infoFontSize),
            _infoRow('Estado', estado, infoFontSize),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              color: Provider.of<TemaProveedor>(context).esModoOscuro
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
