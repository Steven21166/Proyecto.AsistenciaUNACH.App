import 'package:flutter/material.dart';

import '../models/asistencia_model.dart';
import '../models/docente_model.dart';
import '../services/api_service.dart';

class HistorialAsistenciaScreen extends StatefulWidget {
  final Asignatura asignatura;
  final Docente docente;

  const HistorialAsistenciaScreen({
    super.key,
    required this.asignatura,
    required this.docente,
  });

  @override
  State<HistorialAsistenciaScreen> createState() =>
      _HistorialAsistenciaScreenState();
}

class _HistorialAsistenciaScreenState
    extends State<HistorialAsistenciaScreen> {
  final ApiService _apiService = ApiService();

  List<AsistenciaEstudiante> _historial = [];
  List<Estudiante> _estudiantes = [];

  bool _cargando = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();

    _cargarHistorial();
  }

  // ============================================================
  // CARGAR HISTORIAL
  // ============================================================

  Future<void> _cargarHistorial() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final resultados =
          await _apiService.getHistorialAsistencia(
        widget.asignatura.idAsignatura,
      );

      final estudiantes =
          await _apiService.getEstudiantes();

      resultados.sort((a, b) {
        final fechaA =
            '${a.fechaAsistencia} ${a.horaRegistro}';

        final fechaB =
            '${b.fechaAsistencia} ${b.horaRegistro}';

        return fechaB.compareTo(fechaA);
      });

      print(
        'Historial mostrado en pantalla: '
        '${resultados.length} registros.',
      );

      print(
        'Estudiantes disponibles: '
        '${estudiantes.length}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _historial = resultados;
        _estudiantes = estudiantes;
        _cargando = false;
      });
    } catch (e) {
      print(
        'Error cargando historial: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo cargar el historial.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // OBTENER ESTUDIANTE
  // ============================================================

  Estudiante? _buscarEstudiante(
    int idEstudiante,
  ) {
    try {
      return _estudiantes.firstWhere(
        (e) => e.idEstudiante == idEstudiante,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // FILTRAR HISTORIAL
  // ============================================================

  List<AsistenciaEstudiante>
      get _historialFiltrado {
    if (_busqueda.trim().isEmpty) {
      return _historial;
    }

    final texto =
        _busqueda.trim().toLowerCase();

    return _historial.where((asistencia) {
      final estudiante =
          _buscarEstudiante(
        asistencia.idEstudiante,
      );

      if (estudiante == null) {
        return false;
      }

      final nombre =
          '${estudiante.nombres} ${estudiante.apellidos}'
              .toLowerCase();

      final codigo =
          estudiante.codigoEstudiante
              .toLowerCase();

      final estado =
          asistencia.estadoAsistencia
              .toLowerCase();

      final fecha =
          asistencia.fechaAsistencia
              .toLowerCase();

      return nombre.contains(texto) ||
          codigo.contains(texto) ||
          estado.contains(texto) ||
          fecha.contains(texto);
    }).toList();
  }

  // ============================================================
  // CONTAR ESTADOS
  // ============================================================

  int _cantidadEstado(String estado) {
    return _historial.where(
      (a) =>
          a.estadoAsistencia
              .toLowerCase() ==
          estado.toLowerCase(),
    ).length;
  }

  // ============================================================
  // COLOR DEL ESTADO
  // ============================================================

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Colors.green;

      case 'atraso':
        return Colors.orange;

      case 'ausente':
        return Colors.red;

      case 'justificado':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // ICONO DEL ESTADO
  // ============================================================

  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return Icons.check_circle;

      case 'atraso':
        return Icons.access_time;

      case 'ausente':
        return Icons.cancel;

      case 'justificado':
        return Icons.info;

      default:
        return Icons.help;
    }
  }

  // ============================================================
  // FORMATO FECHA
  // ============================================================

  String _formatearFecha(String fecha) {
    if (fecha.isEmpty) {
      return '-';
    }

    try {
      final DateTime fechaDate =
          DateTime.parse(fecha);

      final String dia =
          fechaDate.day.toString().padLeft(2, '0');

      final String mes =
          fechaDate.month.toString().padLeft(2, '0');

      final String anio =
          fechaDate.year.toString();

      return '$dia/$mes/$anio';
    } catch (_) {
      return fecha;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de asistencias',
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: _cargarHistorial,

        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _contenido(),
      ),
    );
  }

  // ============================================================
  // CONTENIDO
  // ============================================================

  Widget _contenido() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      children: [
        Card(
          elevation: 3,

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Asignatura',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.asignatura
                      .nombreAsignatura,

                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Código: ${widget.asignatura.codigoAsignatura}',
                ),

                const SizedBox(height: 4),

                Text(
                  'Semestre: ${widget.asignatura.semestre}',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _tarjetaResumen(
                'Total',
                _historial.length,
                Colors.blue,
                Icons.assignment,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: _tarjetaResumen(
                'Presentes',
                _cantidadEstado('Presente'),
                Colors.green,
                Icons.check_circle,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _tarjetaResumen(
                'Atrasos',
                _cantidadEstado('Atraso'),
                Colors.orange,
                Icons.access_time,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: _tarjetaResumen(
                'Ausentes',
                _cantidadEstado('Ausente'),
                Colors.red,
                Icons.cancel,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        TextField(
          decoration: InputDecoration(
            hintText:
                'Buscar estudiante, código o fecha...',

            prefixIcon:
                const Icon(Icons.search),

            suffixIcon:
                _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                        ),
                        onPressed: () {
                          setState(() {
                            _busqueda = '';
                          });
                        },
                      )
                    : null,

            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),

          onChanged: (value) {
            setState(() {
              _busqueda = value;
            });
          },
        ),

        const SizedBox(height: 18),

        if (_historialFiltrado.isEmpty)
          _sinRegistros()
        else
          ..._historialFiltrado.map(
            (asistencia) =>
                _tarjetaAsistencia(
              asistencia,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // TARJETA RESUMEN
  // ============================================================

  Widget _tarjetaResumen(
    String titulo,
    int cantidad,
    Color color,
    IconData icono,
  ) {
    return Card(
      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          children: [
            Icon(
              icono,
              color: color,
              size: 30,
            ),

            const SizedBox(height: 6),

            Text(
              cantidad.toString(),

              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
                color: color,
              ),
            ),

            Text(
              titulo,

              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA ASISTENCIA
  // ============================================================

  Widget _tarjetaAsistencia(
    AsistenciaEstudiante asistencia,
  ) {
    final estudiante =
        _buscarEstudiante(
      asistencia.idEstudiante,
    );

    final String nombre =
        estudiante == null
            ? 'Estudiante #${asistencia.idEstudiante}'
            : '${estudiante.nombres} ${estudiante.apellidos}';

    final String codigo =
        estudiante?.codigoEstudiante ??
            'ID: ${asistencia.idEstudiante}';

    final Color color =
        _colorEstado(
      asistencia.estadoAsistencia,
    );

    final IconData icono =
        _iconoEstado(
      asistencia.estadoAsistencia,
    );

    return Card(
      elevation: 2,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.12),

                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: Icon(
                icono,
                color: color,
                size: 28,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    nombre,

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    codigo,

                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 15,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        _formatearFecha(
                          asistencia
                              .fechaAsistencia,
                        ),
                      ),

                      const SizedBox(width: 15),

                      const Icon(
                        Icons.access_time,
                        size: 15,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        asistencia.horaRegistro,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),

              decoration: BoxDecoration(
                color:
                    color.withOpacity(0.12),

                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Text(
                asistencia.estadoAsistencia,

                style: TextStyle(
                  color: color,
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIN REGISTROS
  // ============================================================

  Widget _sinRegistros() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 50,
      ),

      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 70,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 15),

          const Text(
            'No existen registros',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _busqueda.isEmpty
                ? 'Esta asignatura todavía no tiene asistencias registradas.'
                : 'No se encontraron resultados para la búsqueda.',
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}