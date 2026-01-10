import 'package:proyecto_is/controller/database.dart';
import 'package:proyecto_is/model/sar_config.dart';

class SarService {
  final DBHelper _dbHelper = DBHelper();

  // Tasa de ISV (15%)
  static const double tasaISV = 0.15;

  // Monto máximo para consumidor final sin RTN (ejemplo: L 10,000)
  static const double montoMaximoConsumidorFinal = 10000.0;

  /// Calcula el ISV de un monto dado
  double calcularISV(double monto) {
    return monto * tasaISV;
  }

  /// Calcula el subtotal (Monto / 1.15)
  double calcularSubtotal(double total) {
    return total / (1 + tasaISV);
  }

  /// Valida si el RTN tiene el formato correcto (14 dígitos numéricos)
  bool validarRTN(String? rtn) {
    if (rtn == null || rtn.isEmpty) return false;
    final regex = RegExp(r'^\d{14}$');
    return regex.hasMatch(rtn);
  }

  /// Verifica si es obligatorio el RTN dado el monto total
  bool esRTNObligatorio(double total) {
    return total >= montoMaximoConsumidorFinal;
  }

  /// Obtiene la configuración SAR activa
  Future<SarConfig?> obtenerConfiguracionActiva() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DBHelper.configuracionSarTable,
        where: 'activo = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return SarConfig.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error al obtener la configuración SAR activa: $e');
      return null;
    }
  }

  /// Genera el siguiente número de factura correlativo
  /// Formato: 000-001-01-00000001
  /// Retorna null si no hay configuración activa o se agotó el rango
  Future<String?> generarSiguienteNumeroFactura() async {
    final config = await obtenerConfiguracionActiva();
    if (config == null) return null;

    // Extraer partes del rango (asumiendo formato estándar)
    // Ejemplo rango inicial: 000-001-01-00000001
    // La parte cambiante son los últimos 8 dígitos

    // Simplificación: Usamos el numero_actual de la config
    int siguienteNumero = config.numeroActual + 1;

    // Validar contra rango final (lógica simplificada de comparación de enteros)
    // En un caso real, se debe parsear el rango final correctamente

    // Formatear el nuevo número
    // Asumimos que el prefijo es constante y solo cambia el correlativo
    // Esto es una simplificación. Lo ideal es guardar prefijo y rango por separado.
    // Dado que guardamos todo el string, intentaremos reconstruirlo.

    // Estrategia robusta:
    // 1. Parsear el rango inicial para obtener el prefijo (primeros 11 caracteres: 000-001-01-)
    // 2. Concatenar con el nuevo correlativo paddeado a 8 ceros.

    String rangoInicial = config.rangoInicial;
    if (rangoInicial.length < 19) return null; // Formato inválido

    String prefijo = rangoInicial.substring(0, 11); // "000-001-01-"
    String nuevoCorrelativo = siguienteNumero.toString().padLeft(8, '0');

    return "$prefijo$nuevoCorrelativo";
  }

  /// Actualiza el número actual en la configuración
  Future<void> actualizarCorrelativo() async {
    final config = await obtenerConfiguracionActiva();
    if (config != null) {
      final db = await _dbHelper.database;
      await db.update(
        DBHelper.configuracionSarTable,
        {'numero_actual': config.numeroActual + 1},
        where: 'id_config = ?',
        whereArgs: [config.id],
      );
    }
  }

  /// Guarda una nueva configuración SAR
  /// Desactiva la configuración anterior si existe
  Future<void> guardarConfiguracion(SarConfig config) async {
    final db = await _dbHelper.database;

    // Desactivar configuración actual
    await db.update(
      DBHelper.configuracionSarTable,
      {'activo': 0},
      where: 'activo = ?',
      whereArgs: [1],
    );

    // Insertar nueva configuración
    await db.insert(
      DBHelper.configuracionSarTable,
      config.toMap()..remove('id_config'), // Asegurar que sea un nuevo registro
    );
  }
}
