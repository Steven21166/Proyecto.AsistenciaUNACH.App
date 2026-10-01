import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/asistencia_model.dart';
import '../models/docente_model.dart';
import '../services/api_service.dart';
import '../services/asistencia_local_service.dart';

class RegistroAsistenciaScreen extends StatefulWidget {
  final Asignatura? asignatura;
  final Docente? docente;

  const RegistroAsistenciaScreen({
    Key? key,
    this.asignatura,
    this.docente,
  }) : super(key: key);

  @override
  _RegistroAsistenciaScreenState createState() =>
      _RegistroAsistenciaScreenState();
}

class _RegistroAsistenciaScreenState
    extends State<RegistroAsistenciaScreen> {
  final ApiService _apiService = ApiService();

  late Future<List<Estudiante>> _estudiantesFuture;

  final Map<int, String> _asistenciasMap = {};

  final TextEditingController _searchController =
      TextEditingController();

  String _filtroBusqueda = '';

  late Timer _timerHora;
  Timer? _timerConexion;

  String _horaActualTexto = '';
  String _fechaTexto = '';

  bool _ultimaConexion = true;
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();

    _estudiantesFuture = _apiService.getEstudiantes();

    _actualizarTiempo();

    _timerHora = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _actualizarTiempo();
      },
    );

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _filtroBusqueda =
            _searchController.text.toLowerCase();
      });
    });

    // ==========================================================
    // INICIAR COMPROBACIÓN AUTOMÁTICA DE INTERNET
    // ==========================================================

    _iniciarDetectorConexion();
  }

  // ============================================================
  // DETECTOR AUTOMÁTICO DE CONEXIÓN
  // ============================================================

  void _iniciarDetectorConexion() {
    _timerConexion = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        if (!mounted) return;

        final bool hayInternet =
            await _verificarInternet();

        // ------------------------------------------------------
        // INTERNET ACABA DE REGRESAR
        // ------------------------------------------------------

        if (!_ultimaConexion && hayInternet) {
          print(
            'Se restauró la conexión a Internet.',
          );

          await _sincronizarAutomaticamente();
        }

        _ultimaConexion = hayInternet;
      },
    );

    // Comprobar estado inicial
    _comprobarConexionInicial();
  }

  Future<void> _comprobarConexionInicial() async {
    final bool hayInternet =
        await _verificarInternet();

    if (!mounted) return;

    _ultimaConexion = hayInternet;

    print(
      'Estado inicial de Internet: '
      '${hayInternet ? "CONECTADO" : "SIN CONEXIÓN"}',
    );
  }

  Future<bool> _verificarInternet() async {
    try {
      final resultado =
          await InternetAddress.lookup('google.com')
              .timeout(
        const Duration(seconds: 2),
      );

      return resultado.isNotEmpty &&
          resultado[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      print(
        'Error comprobando Internet: $e',
      );

      return false;
    }
  }

  // ============================================================
  // SINCRONIZACIÓN AUTOMÁTICA
  // ============================================================

  Future<void> _sincronizarAutomaticamente() async {
    if (_sincronizando) {
      print(
        'Ya existe una sincronización en proceso.',
      );

      return;
    }

    _sincronizando = true;

    try {
      final pendientes =
          await AsistenciaLocalService
              .obtenerAsistenciasPendientes();

      // --------------------------------------------------------
      // NO HAY PENDIENTES
      // --------------------------------------------------------

      if (pendientes.isEmpty) {
        print(
          'Conexión restaurada, pero no existen asistencias pendientes.',
        );

        return;
      }

      print(
        'Se restauró la conexión.',
      );

      print(
        'Sincronizando ${pendientes.length} asistencias pendientes...',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se restauró la conexión. '
              'Sincronizando ${pendientes.length} asistencias...',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      final bool resultado =
          await _apiService.sincronizarPendientes();

      if (!mounted) return;

      if (resultado) {
        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${pendientes.length} asistencias sincronizadas correctamente.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        print(
          'Sincronización automática completada.',
        );
      } else {
        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La conexión volvió, pero algunas asistencias '
              'continúan pendientes.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );

        print(
          'La sincronización no terminó completamente.',
        );
      }
    } catch (e) {
      print(
        'Error en sincronización automática: $e',
      );
    } finally {
      _sincronizando = false;
    }
  }

  // ============================================================
  // ACTUALIZAR FECHA Y HORA
  // ============================================================

  void _actualizarTiempo() {
    if (!mounted) return;

    final now = DateTime.now();

    setState(() {
      _fechaTexto =
          "${now.day.toString().padLeft(2, '0')}/"
          "${now.month.toString().padLeft(2, '0')}/"
          "${now.year}";

      _horaActualTexto =
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timerHora.cancel();
    _timerConexion?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // GUARDAR ASISTENCIA
  // ============================================================

  Future<void> _guardarAsistenciaLote(
      List<Estudiante> estudiantes) async {
    final int idAsignaturaReal =
        widget.asignatura?.idAsignatura ?? 1;

    final int idDocenteReal =
        widget.docente?.idDocente ?? 1;

    final now = DateTime.now();

    final fechaHoy =
        "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    final horaActual =
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  "Procesando asistencias...",
                ),
              ),
            ],
          ),
        );
      },
    );

    bool huboRegistrosOffline = false;
    int registrosOnline = 0;
    int registrosOffline = 0;

    // ==========================================================
    // REGISTRAR ESTUDIANTES
    // ==========================================================

    for (final estudiante in estudiantes) {
      final String estado =
          _asistenciasMap[
                  estudiante.idEstudiante] ??
              'Presente';

      final AsistenciaEstudiante registro =
          AsistenciaEstudiante(
        idEstudiante: estudiante.idEstudiante,
        idAsignatura: idAsignaturaReal,
        idDocente: idDocenteReal,
        fechaAsistencia: fechaHoy,
        horaRegistro: horaActual,
        estadoAsistencia: estado,
      );

      try {
        final String resultado =
            await _apiService.registrarAsistenciaConMensaje(
          registro,
        );

        if (resultado == 'online') {
          registrosOnline++;

          print(
            'Estudiante ${estudiante.idEstudiante}: '
            'guardado ONLINE.',
          );
        } else {
          registrosOffline++;
          huboRegistrosOffline = true;

          print(
            'Estudiante ${estudiante.idEstudiante}: '
            'guardado OFFLINE.',
          );
        }
      } catch (e) {
        registrosOffline++;
        huboRegistrosOffline = true;

        print(
          'Error registrando estudiante '
          '${estudiante.idEstudiante}: $e',
        );

        // Solo guardamos manualmente aquí si realmente
        // ocurrió una excepción inesperada.
        await AsistenciaLocalService
            .guardarAsistenciaLocal(
          registro,
        );
      }
    }

    // ==========================================================
    // COMPROBAR PANTALLA
    // ==========================================================

    if (!mounted) return;

    // ==========================================================
    // CERRAR DIÁLOGO
    // ==========================================================

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // ==========================================================
    // CASO OFFLINE
    // ==========================================================

    if (huboRegistrosOffline) {
      final pendientes =
          await AsistenciaLocalService
              .obtenerAsistenciasPendientes();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$registrosOffline asistencias guardadas '
            'localmente. '
            '${pendientes.length} pendientes de sincronizar.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );

      print(
        '========================================',
      );

      print(
        'MODO OFFLINE',
      );

      print(
        '$registrosOffline asistencias guardadas localmente.',
      );

      print(
        '${pendientes.length} asistencias pendientes.',
      );

      print(
        'Esperando restauración de Internet...',
      );

      print(
        '========================================',
      );

      // IMPORTANTE:
      // NO tomamos otra lista.
      // NO intentamos sincronizar nuevamente ahora.
      // El detector automático se encargará cuando vuelva Internet.

      return;
    }

    // ==========================================================
    // TODO SE GUARDÓ ONLINE
    // ==========================================================

    if (registrosOnline > 0) {
      print(
        '$registrosOnline asistencias registradas online.',
      );

      // También intentamos sincronizar cualquier
      // asistencia anterior que haya quedado pendiente.
      try {
        await _apiService.sincronizarPendientes();
      } catch (e) {
        print(
          'Error sincronizando pendientes anteriores: $e',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$registrosOnline asistencias guardadas correctamente.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ============================================================
  // MOSTRAR HISTORIAL
  // ============================================================

  void _mostrarHistorial(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (
            context,
            scrollController,
          ) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                            BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Historial de Asistencias',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),

                  const Text(
                    'Registros guardados anteriormente en el servidor',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const Divider(height: 24),

                  Expanded(
                    child: FutureBuilder<
                        List<AsistenciaEstudiante>>(
                      future: _apiService
                          .getHistorialAsistencia(
                        widget.asignatura
                                ?.idAsignatura ??
                            1,
                      ),
                      builder: (
                        context,
                        snapshot,
                      ) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child:
                                CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error al cargar historial:\n'
                              '${snapshot.error}',
                              textAlign:
                                  TextAlign.center,
                            ),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'No hay registros históricos '
                              'para esta materia.',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        final historial =
                            snapshot.data!;

                        return ListView.builder(
                          controller:
                              scrollController,
                          itemCount:
                              historial.length,
                          itemBuilder:
                              (context, index) {
                            final item =
                                historial[index];

                            Color colorEstado =
                                Colors.green;

                            if (item.estadoAsistencia ==
                                'Ausente') {
                              colorEstado =
                                  Colors.red;
                            }

                            if (item.estadoAsistencia ==
                                'Atraso') {
                              colorEstado =
                                  Colors.orange;
                            }

                            return Card(
                              elevation: 1,
                              margin:
                                  const EdgeInsets.only(
                                bottom: 8,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),
                              child: ListTile(
                                leading:
                                    CircleAvatar(
                                  backgroundColor:
                                      colorEstado
                                          .withOpacity(
                                    0.1,
                                  ),
                                  child: Icon(
                                    Icons.assignment,
                                    color:
                                        colorEstado,
                                  ),
                                ),
                                title: Text(
                                  'Estudiante ID: '
                                  '${item.idEstudiante}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Fecha: '
                                  '${item.fechaAsistencia} '
                                  '| Hora: '
                                  '${item.horaRegistro}',
                                ),
                                trailing: Chip(
                                  label: Text(
                                    item.estadoAsistencia,
                                    style: TextStyle(
                                      color:
                                          colorEstado,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor:
                                      colorEstado
                                          .withOpacity(
                                    0.1,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final nombreMateria =
        widget.asignatura?.nombreAsignatura ??
            'Registro de Asistencia';

    final int? semestreMateria =
        widget.asignatura?.semestre;

    final codigoMateria =
        widget.asignatura?.codigoAsignatura ??
            'S/N';

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              nombreMateria,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Semestre: '
              '${semestreMateria ?? "Gral"}'
              ' • Cod: $codigoMateria',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor:
            const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
            ),
            tooltip:
                'Historial de Asistencias',
            onPressed: () =>
                _mostrarHistorial(context),
          ),
        ],
      ),

      // ========================================================
      // LISTA DE ESTUDIANTES
      // ========================================================

      body: FutureBuilder<List<Estudiante>>(
        future: _estudiantesFuture,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar datos:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay estudiantes registrados.',
              ),
            );
          }

          final List<Estudiante>
              todosLosEstudiantes =
              snapshot.data!;

          final List<Estudiante>
              estudiantesSemestre =
              semestreMateria != null
                  ? todosLosEstudiantes
                      .where(
                        (est) =>
                            est.semestre ==
                            semestreMateria,
                      )
                      .toList()
                  : todosLosEstudiantes;

          final List<Estudiante>
              estudiantesFiltrados =
              estudiantesSemestre.where((est) {
            final nombreCompleto =
                '${est.nombres} ${est.apellidos}'
                    .toLowerCase();

            return nombreCompleto.contains(
              _filtroBusqueda,
            );
          }).toList();

          int presentes = 0;
          int atrasados = 0;
          int ausentes = 0;

          for (final est
              in estudiantesSemestre) {
            final String estado =
                _asistenciasMap[
                        est.idEstudiante] ??
                    'Presente';

            if (estado == 'Presente') {
              presentes++;
            }

            if (estado == 'Atraso') {
              atrasados++;
            }

            if (estado == 'Ausente') {
              ausentes++;
            }
          }

          return Column(
            children: [
              // ==================================================
              // FECHA Y HORA
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration:
                    const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .calendar_today_rounded,
                          size: 16,
                          color:
                              Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fechaTexto,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .access_time_rounded,
                          size: 16,
                          color:
                              Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _horaActualTexto,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ==================================================
              // CONTADORES
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          _buildCounterCard(
                        'Presentes',
                        presentes,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child:
                          _buildCounterCard(
                        'Atrasados',
                        atrasados,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child:
                          _buildCounterCard(
                        'Ausentes',
                        ausentes,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // BUSCADOR
              // ==================================================

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: TextField(
                  controller:
                      _searchController,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Buscar estudiante por nombre o apellido...',
                    hintStyle:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    prefixIcon:
                        const Icon(
                      Icons.search,
                      color:
                          Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      borderSide:
                          BorderSide(
                        color:
                            Colors.grey.shade200,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ==================================================
              // LISTA
              // ==================================================

              Expanded(
                child:
                    estudiantesFiltrados
                            .isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron estudiantes.',
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                            ),
                            itemCount:
                                estudiantesFiltrados
                                    .length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final est =
                                  estudiantesFiltrados[
                                      index];

                              _asistenciasMap
                                  .putIfAbsent(
                                est.idEstudiante,
                                () => 'Presente',
                              );

                              final String
                                  estadoActual =
                                  _asistenciasMap[
                                      est.idEstudiante]!;

                              Color badgeColor =
                                  Colors.green;

                              if (estadoActual ==
                                  'Ausente') {
                                badgeColor =
                                    Colors.red;
                              }

                              if (estadoActual ==
                                  'Atraso') {
                                badgeColor =
                                    Colors.orange;
                              }

                              return Container(
                                margin:
                                    const EdgeInsets
                                        .only(
                                  bottom: 8,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withOpacity(
                                        0.02,
                                      ),
                                      blurRadius: 6,
                                      offset:
                                          const Offset(
                                        0,
                                        2,
                                      ),
                                    ),
                                  ],
                                ),
                                child:
                                    ListTile(
                                  contentPadding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    '${est.apellidos} '
                                    '${est.nombres}',
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      fontSize: 15,
                                      color:
                                          Color(
                                        0xFF1E293B,
                                      ),
                                    ),
                                  ),
                                  subtitle:
                                      Text(
                                    'Código: '
                                    '${est.codigoEstudiante}'
                                    '  •  Semestre: '
                                    '${est.semestre}',
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(
                                        0xFF64748B,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing:
                                      Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          badgeColor
                                              .withOpacity(
                                        0.08,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        8,
                                      ),
                                      border:
                                          Border.all(
                                        color:
                                            badgeColor
                                                .withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child:
                                        DropdownButtonHideUnderline(
                                      child:
                                          DropdownButton<
                                              String>(
                                        value:
                                            estadoActual,
                                        icon:
                                            Icon(
                                          Icons
                                              .arrow_drop_down,
                                          color:
                                              badgeColor,
                                        ),
                                        style:
                                            TextStyle(
                                          color:
                                              badgeColor,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                        items:
                                            const [
                                          DropdownMenuItem(
                                            value:
                                                'Presente',
                                            child:
                                                Text(
                                              'Presente',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.green,
                                              ),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                'Atraso',
                                            child:
                                                Text(
                                              'Atrasado',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.orange,
                                              ),
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value:
                                                'Ausente',
                                            child:
                                                Text(
                                              'Ausente',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged:
                                            (
                                          String?
                                              nuevoValor,
                                        ) {
                                          if (!mounted)
                                            return;

                                          if (nuevoValor ==
                                              null) {
                                            return;
                                          }

                                          setState(() {
                                            _asistenciasMap[
                                                    est.idEstudiante] =
                                                nuevoValor;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // ==================================================
              // BOTÓN GUARDAR
              // ==================================================

              if (estudiantesSemestre
                  .isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.all(16),
                  color: Colors.white,
                  child: SizedBox(
                    width:
                        double.infinity,
                    height: 52,
                    child:
                        ElevatedButton.icon(
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF1E3A8A,
                        ),
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () =>
                          _guardarAsistenciaLote(
                        estudiantesSemestre,
                      ),
                      icon:
                          const Icon(
                        Icons
                            .cloud_upload_rounded,
                      ),
                      label:
                          const Text(
                        'Guardar Asistencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // TARJETA DE CONTADOR
  // ============================================================

  Widget _buildCounterCard(
    String titulo,
    int valor,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 12,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                color.withOpacity(0.04),
            blurRadius: 4,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$valor',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}