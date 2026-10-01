import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/asistencia_model.dart';
import '../models/docente_model.dart';

class AsistenciaLocalService {
  // ============================================================
  // CLAVES DE ALMACENAMIENTO LOCAL
  // ============================================================

  static const String _keyAsistenciasPendientes =
      'asistencias_pendientes';

  static const String _keyEstudiantesCache =
      'estudiantes_cache';

  static const String _keyDocenteCache =
      'docente_cache';

  static const String _keyCorreoDocente =
      'correo_docente_local';

  static const String _keyCedulaDocente =
      'cedula_docente_local';

  // ============================================================
  // GUARDAR DOCENTE LOCALMENTE
  // ============================================================

  static Future<void> guardarDocenteLocal(
    Docente docente,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final data = {
      'idDocente': docente.idDocente,
      'nombres': docente.nombres,
      'apellidos': docente.apellidos,
      'correo': docente.correo,

      'docenteAsignaturas':
          docente.docenteAsignaturas.map((da) {
        return {
          'idAsignatura': da.idAsignatura,

          'idAsignaturaNavigation':
              da.asignaturaNavigation == null
                  ? null
                  : {
                      'idAsignatura':
                          da.asignaturaNavigation!
                              .idAsignatura,

                      'codigoAsignatura':
                          da.asignaturaNavigation!
                              .codigoAsignatura,

                      'nombreAsignatura':
                          da.asignaturaNavigation!
                              .nombreAsignatura,

                      'semestre':
                          da.asignaturaNavigation!
                              .semestre,
                    },
        };
      }).toList(),
    };

    await prefs.setString(
      _keyDocenteCache,
      jsonEncode(data),
    );

    print(
      'Docente guardado localmente.',
    );
  }

  // ============================================================
  // GUARDAR CREDENCIALES PARA LOGIN OFFLINE
  // ============================================================

  static Future<void> guardarCredencialesDocente(
    String correo,
    String cedula,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _keyCorreoDocente,
      correo.trim().toLowerCase(),
    );

    await prefs.setString(
      _keyCedulaDocente,
      cedula.trim(),
    );

    print(
      'Credenciales guardadas para login offline.',
    );
  }

  // ============================================================
  // VALIDAR CREDENCIALES OFFLINE
  // ============================================================

  static Future<bool> validarCredencialesDocente(
    String correo,
    String cedula,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? correoGuardado =
        prefs.getString(
      _keyCorreoDocente,
    );

    final String? cedulaGuardada =
        prefs.getString(
      _keyCedulaDocente,
    );

    if (correoGuardado == null ||
        cedulaGuardada == null) {
      print(
        'No existen credenciales guardadas localmente.',
      );

      return false;
    }

    final bool correoCorrecto =
        correoGuardado.trim().toLowerCase() ==
            correo.trim().toLowerCase();

    final bool cedulaCorrecta =
        cedulaGuardada.trim() ==
            cedula.trim();

    print(
      'Validación offline -> '
      'correo: $correoCorrecto, '
      'cédula: $cedulaCorrecta',
    );

    return correoCorrecto && cedulaCorrecta;
  }

  // ============================================================
  // OBTENER DOCENTE LOCAL
  // ============================================================

  static Future<Docente?> obtenerDocenteLocal() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? dataString =
        prefs.getString(
      _keyDocenteCache,
    );

    if (dataString == null ||
        dataString.isEmpty) {
      print(
        'No existe ningún docente en caché local.',
      );

      return null;
    }

    try {
      final data =
          jsonDecode(dataString);

      return Docente.fromJson(
        Map<String, dynamic>.from(data),
      );
    } catch (e) {
      print(
        'Error leyendo docente local: $e',
      );

      return null;
    }
  }

  // ============================================================
  // ELIMINAR DOCENTE LOCAL
  // ============================================================

  static Future<void> eliminarDocenteLocal() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _keyDocenteCache,
    );

    print(
      'Docente eliminado del almacenamiento local.',
    );
  }

  // ============================================================
  // GUARDAR ESTUDIANTES LOCALMENTE
  // ============================================================

  static Future<void> guardarEstudiantesLocales(
    List<Estudiante> estudiantes,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final listaString =
        estudiantes.map((e) {
      return jsonEncode({
        'idEstudiante':
            e.idEstudiante,

        'codigoEstudiante':
            e.codigoEstudiante,

        'nombres':
            e.nombres,

        'apellidos':
            e.apellidos,

        'semestre':
            e.semestre,

        'estado':
            e.estado,
      });
    }).toList();

    await prefs.setStringList(
      _keyEstudiantesCache,
      listaString,
    );

    print(
      '${estudiantes.length} estudiantes guardados localmente.',
    );
  }

  // ============================================================
  // OBTENER ESTUDIANTES LOCALES
  // ============================================================

  static Future<List<Estudiante>>
      obtenerEstudiantesLocales() async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> listaString =
        prefs.getStringList(
              _keyEstudiantesCache,
            ) ??
            [];

    if (listaString.isEmpty) {
      print(
        'No existen estudiantes guardados localmente.',
      );

      return [];
    }

    try {
      return listaString.map((item) {
        return Estudiante.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(item),
          ),
        );
      }).toList();
    } catch (e) {
      print(
        'Error leyendo estudiantes locales: $e',
      );

      return [];
    }
  }

  // ============================================================
  // GUARDAR UNA ASISTENCIA EN COLA LOCAL
  // ============================================================

  static Future<void> guardarAsistenciaLocal(
    AsistenciaEstudiante asistencia,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> listaString =
        prefs.getStringList(
              _keyAsistenciasPendientes,
            ) ??
            [];

    listaString.add(
      jsonEncode(
        asistencia.toJson(),
      ),
    );

    await prefs.setStringList(
      _keyAsistenciasPendientes,
      listaString,
    );

    print(
      'Asistencia guardada en cola local.',
    );

    print(
      'Total pendientes: ${listaString.length}',
    );
  }

  // ============================================================
  // OBTENER ASISTENCIAS PENDIENTES
  // ============================================================

  static Future<List<AsistenciaEstudiante>>
      obtenerAsistenciasPendientes() async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> listaString =
        prefs.getStringList(
              _keyAsistenciasPendientes,
            ) ??
            [];

    if (listaString.isEmpty) {
      print(
        'No existen asistencias pendientes.',
      );

      return [];
    }

    try {
      final List<AsistenciaEstudiante>
          pendientes = [];

      for (final item in listaString) {
        try {
          final data =
              jsonDecode(item);

          pendientes.add(
            AsistenciaEstudiante.fromJson(
              Map<String, dynamic>.from(data),
            ),
          );
        } catch (e) {
          print(
            'Error leyendo una asistencia pendiente: $e',
          );
        }
      }

      print(
        'Asistencias pendientes encontradas: ${pendientes.length}',
      );

      return pendientes;
    } catch (e) {
      print(
        'Error obteniendo asistencias pendientes: $e',
      );

      return [];
    }
  }

  // ============================================================
  // GUARDAR LISTA DE ASISTENCIAS PENDIENTES
  // ============================================================

  static Future<void> guardarAsistenciasPendientes(
    List<AsistenciaEstudiante> asistencias,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> lista =
        asistencias.map((asistencia) {
      return jsonEncode(
        asistencia.toJson(),
      );
    }).toList();

    await prefs.setStringList(
      _keyAsistenciasPendientes,
      lista,
    );

    print(
      '${asistencias.length} asistencias permanecen pendientes.',
    );
  }

  // ============================================================
  // LIMPIAR ASISTENCIAS PENDIENTES
  // ============================================================

  static Future<void>
      limpiarAsistenciasPendientes() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _keyAsistenciasPendientes,
    );

    print(
      'Cola de asistencias pendientes eliminada.',
    );
  }

  // ============================================================
  // CANTIDAD DE ASISTENCIAS PENDIENTES
  // ============================================================

  static Future<int>
      cantidadAsistenciasPendientes() async {
    final prefs =
        await SharedPreferences.getInstance();

    final List<String> lista =
        prefs.getStringList(
              _keyAsistenciasPendientes,
            ) ??
            [];

    return lista.length;
  }

  // ============================================================
  // HISTORIAL LOCAL
  // ============================================================

  static String _keyHistorial(
    int idAsignatura,
  ) {
    return 'historial_cache_$idAsignatura';
  }

  // ============================================================
  // GUARDAR HISTORIAL LOCAL
  // ============================================================

  static Future<void> guardarHistorialLocal(
    int idAsignatura,
    List<AsistenciaEstudiante> asistencias,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final lista =
        asistencias
            .map(
              (asistencia) =>
                  asistencia.toJson(),
            )
            .toList();

    await prefs.setString(
      _keyHistorial(idAsignatura),
      jsonEncode(lista),
    );

    print(
      'Historial guardado localmente: '
      '${asistencias.length} registros.',
    );
  }

  // ============================================================
  // OBTENER HISTORIAL LOCAL
  // ============================================================

  static Future<List<AsistenciaEstudiante>>
      obtenerHistorialLocal(
    int idAsignatura,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? dataString =
        prefs.getString(
      _keyHistorial(idAsignatura),
    );

    if (dataString == null ||
        dataString.isEmpty) {
      print(
        'No existe historial local para esta asignatura.',
      );

      return [];
    }

    try {
      final data =
          jsonDecode(dataString);

      if (data is! List) {
        return [];
      }

      return data.map((item) {
        return AsistenciaEstudiante.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();
    } catch (e) {
      print(
        'Error leyendo historial local: $e',
      );

      return [];
    }
  }
}