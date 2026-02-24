import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_is/model/preferences.dart';
import 'package:proyecto_is/controller/repository_audit.dart';
import 'package:proyecto_is/model/audit_log.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final RepositoryAudit _repositoryAudit = RepositoryAudit();
  List<AuditLog> _logs = [];
  List<AuditLog> _filteredLogs = [];
  bool _isLoading = true;

  // Filters
  String _selectedAction = 'Todos';
  String _selectedTable = 'Todas';
  final List<String> _actions = ['Todos', 'UPDATE', 'DELETE'];
  List<String> _tables = ['Todas'];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _repositoryAudit.getAuditLogs();

    final uniqueTables = logs.map((l) => l.tabla).toSet().toList();
    uniqueTables.sort();

    setState(() {
      _logs = logs;
      _filteredLogs = logs;
      _tables = ['Todas', ...uniqueTables];
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredLogs = _logs.where((log) {
        final matchesAction =
            _selectedAction == 'Todos' || log.accion == _selectedAction;
        final matchesTable =
            _selectedTable == 'Todas' || log.tabla == _selectedTable;
        return matchesAction && matchesTable;
      }).toList();
    });
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
    } catch (e) {
      return isoString;
    }
  }

  void _showDetailsDialog(AuditLog log) {
    final themeProvider = Provider.of<TemaProveedor>(context, listen: false);
    final isDarkMode = themeProvider.esModoOscuro;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final isUpdate = log.accion == 'UPDATE';
    final isDelete = log.accion == 'DELETE';

    Color actionColor = Colors.blue;
    if (isDelete)
      actionColor = Colors.red;
    else if (isUpdate)
      actionColor = Colors.orange;

    Map<String, dynamic> detailsMap = {};
    if (log.detalles != null && log.detalles!.isNotEmpty) {
      try {
        detailsMap = jsonDecode(log.detalles!);
      } catch (e) {
        detailsMap = {'Raw': log.detalles};
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDarkMode
              ? const Color.fromRGBO(30, 30, 30, 1)
              : Colors.white,
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.history_edu_outlined, color: actionColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles del Cambio',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        '${log.accion} en ${log.tabla}',
                        style: TextStyle(
                          color: actionColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    'Registro ID',
                    '#${log.registroId}',
                    Icons.fingerprint,
                    isDarkMode,
                  ),
                  _infoRow(
                    'Usuario',
                    log.nombreUsuario ?? 'Sistema',
                    Icons.person_outline,
                    isDarkMode,
                  ),
                  _infoRow(
                    'Fecha y Hora',
                    _formatDate(log.fecha),
                    Icons.calendar_today_outlined,
                    isDarkMode,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  Text(
                    'CAMBIOS REGISTRADOS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: textColor.withOpacity(0.5),
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (detailsMap.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No hay detalles adicionales registrados.',
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ...detailsMap.entries.map((entry) {
                    final key = entry.key;
                    final value = entry.value;

                    if (log.accion == 'UPDATE' && value is Map) {
                      final oldVal = value['old'];
                      final newVal = value['new'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black26 : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[850]
                                    : Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                key.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Anterior',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red[300],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$oldVal',
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nuevo',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green[400],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$newVal',
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black12 : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$key: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(child: Text('$value')),
                          ],
                        ),
                      );
                    }
                  }).toList(),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<TemaProveedor>(context);
    final isDarkMode = themeProvider.esModoOscuro;
    final backgroundColor = isDarkMode
        ? Colors.black
        : const Color.fromRGBO(244, 243, 243, 1);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode
        ? const Color.fromRGBO(30, 30, 30, 1)
        : Colors.white;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // Obtenemos el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 900;

    // Ajustamos tamaños según el dispositivo
    final double titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Auditoría e historial',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Filtros de búsqueda',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildDropdown(
                      label: 'Acción',
                      icon: Icons.touch_app_outlined,
                      value: _selectedAction,
                      items: _actions,
                      onChanged: (val) {
                        setState(() => _selectedAction = val!);
                        _applyFilters();
                      },
                      isDark: isDarkMode,
                    ),
                    _buildDropdown(
                      label: 'Tabla',
                      icon: Icons.table_chart_outlined,
                      value: _selectedTable,
                      items: _tables,
                      onChanged: (val) {
                        setState(() => _selectedTable = val!);
                        _applyFilters();
                      },
                      isDark: isDarkMode,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron registros de auditoría.',
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  )
                : isDesktop
                ? _buildDesktopTable(isDarkMode)
                : _buildMobileList(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.blueAccent,
              ),
              dropdownColor: isDark ? Colors.grey[900] : Colors.white,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: Colors.blueAccent.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(item),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        final isUpdate = log.accion == 'UPDATE';
        final isDelete = log.accion == 'DELETE';

        Color actionColor = Colors.blue;
        IconData actionIcon = Icons.edit_note;

        if (isDelete) {
          actionColor = Colors.red;
          actionIcon = Icons.delete_forever_outlined;
        } else if (isUpdate) {
          actionColor = Colors.orange;
          actionIcon = Icons.update;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color.fromRGBO(30, 30, 30, 1)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDarkMode)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
            ],
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _showDetailsDialog(log),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: actionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(actionIcon, color: actionColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.tabla,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    log.nombreUsuario ?? 'Sistema',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: actionColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                log.accion,
                                style: TextStyle(
                                  color: actionColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(log.fecha).split(' ')[0],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fingerprint,
                              size: 14,
                              color: Colors.blueAccent.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ID: ${log.registroId}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Ver detalles >',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(bool isDarkMode) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : Colors.black87,
      fontSize: 15,
    );
    final rowTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[800];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color.fromRGBO(30, 30, 30, 1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowHeight: 60,
              dataRowHeight: 70,
              headingRowColor: MaterialStateProperty.all(
                isDarkMode ? Colors.grey[900] : Colors.grey[50],
              ),
              showCheckboxColumn: false,
              columns: [
                DataColumn(label: Text('Fecha y Hora', style: headerStyle)),
                DataColumn(label: Text('Acción', style: headerStyle)),
                DataColumn(label: Text('Módulo / Tabla', style: headerStyle)),
                DataColumn(label: Text('Usuario', style: headerStyle)),
                DataColumn(label: Text('Registro ID', style: headerStyle)),
                DataColumn(label: Text('Acciones', style: headerStyle)),
              ],
              rows: _filteredLogs.map((log) {
                final isUpdate = log.accion == 'UPDATE';
                final isDelete = log.accion == 'DELETE';
                Color actionColor = Colors.blue;
                if (isDelete)
                  actionColor = Colors.red;
                else if (isUpdate)
                  actionColor = Colors.orange;

                return DataRow(
                  onSelectChanged: (_) => _showDetailsDialog(log),
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(log.fecha).split(' ')[0],
                            style: TextStyle(
                              color: rowTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(log.fecha).split(' ')[1],
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: actionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: actionColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          log.accion,
                          style: TextStyle(
                            color: actionColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            size: 18,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log.tabla,
                            style: TextStyle(
                              color: rowTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            child: Text(
                              (log.nombreUsuario ?? 'S')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log.nombreUsuario ?? 'Sistema',
                            style: TextStyle(color: rowTextColor),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '#${log.registroId}',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      ElevatedButton.icon(
                        onPressed: () => _showDetailsDialog(log),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Detalles'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
