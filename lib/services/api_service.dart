import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../models/asistencia_model.dart';
import '../models/docente_model.dart';
import 'asistencia_local_service.dart';

class ApiService {
  // ============================================================
  // URL DE LA API
  // ============================================================

  // Android Emulator
  final String baseUrl = 'https://desktop-1cffthh.tailc8f3f2.ts.net/api';

  // Celular físico:
  // final String baseUrl = 'http://192.168.1.100:5256/api';

  // ============================================================
  // CLIENTE HTTP
  // ============================================================

  http.Client _getClient() {
    final HttpClient client = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    return IOClient(client);
  }

  // ============================================================
  // VERIFICAR CONEXIÓN REAL CON LA API
  // ============================================================

  Future<bool> verificarConexionReal() async {
    try {
      final uri = Uri.parse(baseUrl);

      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(seconds: 2),
      );

      socket.destroy();

      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // OBTENER ESTUDIANTES
  // ============================================================

  Future<List<Estudiante>> getEstudiantes() async {
    final bool hayRed = await verificarConexionReal();

    // ----------------------------------------------------------
    // SIN INTERNET
    // ----------------------------------------------------------

    if (!hayRed) {
      print(
        'Sin Internet. Cargando estudiantes desde almacenamiento local...',
      );

      return await AsistenciaLocalService
          .obtenerEstudiantesLocales();
    }

    // ----------------------------------------------------------
    // CON INTERNET
    // ----------------------------------------------------------

    try {
      final client = _getClient();

      final response = await client
          .get(
            Uri.parse('$baseUrl/estudiante'),
          )
          .timeout(
            const Duration(seconds: 5),
          );

      client.close();

      if (response.statusCode == 200) {
        final List<dynamic> body =
            json.decode(response.body);

        final List<Estudiante> estudiantes = body
            .map(
              (item) => Estudiante.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        await AsistenciaLocalService
            .guardarEstudiantesLocales(
          estudiantes,
        );

        print(
          '${estudiantes.length} estudiantes obtenidos desde la API.',
        );

        print(
          'Estudiantes guardados correctamente en caché local.',
        );

        return estudiantes;
      }

      print(
        'Servidor respondió con código ${response.statusCode}.',
      );

      print(
        'Intentando cargar estudiantes locales...',
      );

      return await AsistenciaLocalService
          .obtenerEstudiantesLocales();
    } on TimeoutException {
      print(
        'Timeout obteniendo estudiantes.',
      );

      return await AsistenciaLocalService
          .obtenerEstudiantesLocales();
    } on SocketException {
      print(
        'Error de conexión obteniendo estudiantes.',
      );

      return await AsistenciaLocalService
          .obtenerEstudiantesLocales();
    } catch (e) {
      print(
        'Error obteniendo estudiantes: $e',
      );

      return await AsistenciaLocalService
          .obtenerEstudiantesLocales();
    }
  }

  // ============================================================
  // REGISTRAR ASISTENCIA
  //
  // RETORNA:
  // true  = se registró directamente en servidor
  // false = quedó pendiente localmente
  // ============================================================

  Future<bool> registrarAsistencia(
    AsistenciaEstudiante asistencia,
  ) async {
    final String resultado =
        await registrarAsistenciaConMensaje(
      asistencia,
    );

    return resultado == 'online';
  }

  // ============================================================
  // REGISTRAR ASISTENCIA CON RESULTADO
  //
  // RETORNA:
  //
  // online  -> se guardó en SQL Server
  // offline -> se guardó en cola local
  // error   -> hubo un error del servidor
  // ============================================================

  Future<String> registrarAsistenciaConMensaje(
    AsistenciaEstudiante asistencia,
  ) async {
    try {
      final client = _getClient();

      final response = await client
          .post(
            Uri.parse(
              '$baseUrl/AsistenciaEstudiante',
            ),
            headers: {
              'Content-Type':
                  'application/json; charset=UTF-8',
            },
            body: jsonEncode(
              asistencia.toJson(),
            ),
          )
          .timeout(
            const Duration(seconds: 5),
          );

      client.close();

      // --------------------------------------------------------
      // REGISTRO CORRECTO
      // --------------------------------------------------------

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        print(
          'Asistencia registrada correctamente en el servidor.',
        );

        return 'online';
      }

      // --------------------------------------------------------
      // ERROR DEL SERVIDOR
      // --------------------------------------------------------

      print(
        'Error del servidor al registrar asistencia.',
      );

      print(
        'Código HTTP: ${response.statusCode}',
      );

      print(
        'Respuesta: ${response.body}',
      );

      return 'error';
    } on TimeoutException {
      print(
        'Timeout registrando asistencia.',
      );

      print(
        'Guardando asistencia localmente...',
      );

      await AsistenciaLocalService
          .guardarAsistenciaLocal(
        asistencia,
      );

      return 'offline';
    } on SocketException {
      print(
        'Se perdió la conexión durante el registro.',
      );

      print(
        'Guardando asistencia localmente...',
      );

      await AsistenciaLocalService
          .guardarAsistenciaLocal(
        asistencia,
      );

      return 'offline';
    } catch (e) {
      print(
        'Error registrando asistencia: $e',
      );

      await AsistenciaLocalService
          .guardarAsistenciaLocal(
        asistencia,
      );

      return 'offline';
    }
  }

  // ============================================================
  // ENVIAR ASISTENCIA DIRECTAMENTE AL SERVIDOR
  // ============================================================

  Future<bool> _enviarAsistenciaAlServidor(
    AsistenciaEstudiante asistencia,
  ) async {
    try {
      final client = _getClient();

      final response = await client
          .post(
            Uri.parse(
              '$baseUrl/AsistenciaEstudiante',
            ),
            headers: {
              'Content-Type':
                  'application/json; charset=UTF-8',
            },
            body: jsonEncode(
              asistencia.toJson(),
            ),
          )
          .timeout(
            const Duration(seconds: 5),
          );

      client.close();

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        print(
          'Asistencia enviada correctamente al servidor.',
        );

        return true;
      }

      print(
        'No se pudo sincronizar una asistencia.',
      );

      print(
        'Código HTTP: ${response.statusCode}',
      );

      print(
        'Respuesta: ${response.body}',
      );

      return false;
    } on TimeoutException {
      print(
        'Timeout durante la sincronización.',
      );

      return false;
    } on SocketException {
      print(
        'Conexión perdida durante la sincronización.',
      );

      return false;
    } catch (e) {
      print(
        'Error enviando asistencia al servidor: $e',
      );

      return false;
    }
  }

  // ============================================================
  // SINCRONIZAR ASISTENCIAS PENDIENTES
  // ============================================================

  Future<bool> sincronizarPendientes() async {
    try {
      final List<AsistenciaEstudiante> pendientes =
          await AsistenciaLocalService
              .obtenerAsistenciasPendientes();

      if (pendientes.isEmpty) {
        print(
          'No existen asistencias pendientes.',
        );

        return true;
      }

      print(
        '==========================================',
      );

      print(
        'ASISTENCIAS PENDIENTES: ${pendientes.length}',
      );

      print(
        '==========================================',
      );

      final List<AsistenciaEstudiante>
          pendientesRestantes = [];

      // --------------------------------------------------------
      // ENVIAR UNA POR UNA
      // --------------------------------------------------------

      for (final asistencia in pendientes) {
        print(
          'Sincronizando asistencia:',
        );

        print(
          'Estudiante: ${asistencia.idEstudiante}',
        );

        print(
          'Asignatura: ${asistencia.idAsignatura}',
        );

        print(
          'Docente: ${asistencia.idDocente}',
        );

        print(
          'Estado: ${asistencia.estadoAsistencia}',
        );

        final bool exito =
            await _enviarAsistenciaAlServidor(
          asistencia,
        );

        if (!exito) {
          pendientesRestantes.add(
            asistencia,
          );

          print(
            'La asistencia permanecerá pendiente.',
          );
        } else {
          print(
            'Asistencia sincronizada correctamente.',
          );
        }
      }

      // --------------------------------------------------------
      // TODAS SINCRONIZADAS
      // --------------------------------------------------------

      if (pendientesRestantes.isEmpty) {
        await AsistenciaLocalService
            .limpiarAsistenciasPendientes();

        print(
          '==========================================',
        );

        print(
          'SINCRONIZACIÓN COMPLETADA',
        );

        print(
          'Todas las asistencias fueron enviadas.',
        );

        print(
          'Cola local vaciada correctamente.',
        );

        print(
          '==========================================',
        );

        return true;
      }

      // --------------------------------------------------------
      // QUEDARON PENDIENTES
      // --------------------------------------------------------

      print(
        'Quedaron '
        '${pendientesRestantes.length} '
        'asistencias pendientes.',
      );

      await AsistenciaLocalService
          .guardarAsistenciasPendientes(
        pendientesRestantes,
      );

      print(
        'Las asistencias fallidas permanecen guardadas localmente.',
      );

      return false;
    } catch (e) {
      print(
        'Error sincronizando asistencias pendientes: $e',
      );

      return false;
    }
  }

  // ============================================================
  // COMPATIBILIDAD
  // ============================================================

  Future<void> sincronizarAsistenciasPendientes() async {
    await sincronizarPendientes();
  }

  // ============================================================
  // HISTORIAL DE ASISTENCIA
  // ============================================================

  Future<List<AsistenciaEstudiante>>
      getHistorialAsistencia(
    int idAsignatura,
  ) async {
    try {
      final client = _getClient();

      final response = await client
          .get(
            Uri.parse(
              '$baseUrl/AsistenciaEstudiante/asignatura/$idAsignatura',
            ),
          )
          .timeout(
            const Duration(seconds: 5),
          );

      client.close();

      if (response.statusCode == 200) {
        final List<dynamic> body =
            json.decode(response.body);

        final List<AsistenciaEstudiante>
            historial =
            body.map((item) {
          return AsistenciaEstudiante(
            idAsistencia:
                item['idAsistencia'],
            idEstudiante:
                item['idEstudiante'] ?? 0,
            idAsignatura:
                item['idAsignatura'] ?? 0,
            idDocente:
                item['idDocente'] ?? 0,
            fechaAsistencia:
                item['fechaAsistencia'] ?? '',
            horaRegistro:
                item['horaRegistro'] ?? '',
            estadoAsistencia:
                item['estadoAsistencia'] ??
                    'Presente',
          );
        }).toList();

        // Más recientes primero
        historial.sort((a, b) {
          final fechaA =
              '${a.fechaAsistencia} ${a.horaRegistro}';

          final fechaB =
              '${b.fechaAsistencia} ${b.horaRegistro}';

          return fechaB.compareTo(fechaA);
        });

        await AsistenciaLocalService
            .guardarHistorialLocal(
          idAsignatura,
          historial,
        );

        print(
          'Historial recibido desde SQL Server: '
          '${historial.length} registros.',
        );

        return historial;
      }

      print(
        'Servidor respondió con código ${response.statusCode}.',
      );

      return await AsistenciaLocalService
          .obtenerHistorialLocal(
        idAsignatura,
      );
    } on TimeoutException {
      print(
        'Timeout consultando historial.',
      );

      return await AsistenciaLocalService
          .obtenerHistorialLocal(
        idAsignatura,
      );
    } on SocketException {
      print(
        'Error de conexión consultando historial.',
      );

      return await AsistenciaLocalService
          .obtenerHistorialLocal(
        idAsignatura,
      );
    } catch (e) {
      print(
        'Excepción en getHistorialAsistencia: $e',
      );

      return await AsistenciaLocalService
          .obtenerHistorialLocal(
        idAsignatura,
      );
    }
  }

  // ============================================================
  // LOGIN DOCENTE
  // ============================================================

  Future<Docente?> loginDocente(
    String correo,
    String cedula,
  ) async {
    try {
      final client = _getClient();

      final String encodedCorreo =
          Uri.encodeComponent(
        correo.trim(),
      );

      final String encodedCedula =
          Uri.encodeComponent(
        cedula.trim(),
      );

      final Uri url = Uri.parse(
        '$baseUrl/docente/login'
        '?correo=$encodedCorreo'
        '&cedula=$encodedCedula',
      );

      final response = await client
          .get(url)
          .timeout(
            const Duration(seconds: 5),
          );

      client.close();

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        final Docente docente =
            Docente.fromJson(
          Map<String, dynamic>.from(data),
        );

        await AsistenciaLocalService
            .guardarDocenteLocal(
          docente,
        );

        await AsistenciaLocalService
            .guardarCredencialesDocente(
          correo,
          cedula,
        );

        print(
          'Login online exitoso.',
        );

        print(
          'Docente guardado localmente.',
        );

        return docente;
      }

      print(
        'Login rechazado por el servidor.',
      );

      return null;
    } on TimeoutException {
      print(
        'Timeout durante el login.',
      );

      print(
        'Intentando iniciar sesión desde caché local...',
      );

      return await _intentarLoginLocal(
        correo,
        cedula,
      );
    } on SocketException {
      print(
        'Error de conexión durante el login.',
      );

      print(
        'Intentando iniciar sesión desde caché local...',
      );

      return await _intentarLoginLocal(
        correo,
        cedula,
      );
    } catch (e) {
      print(
        'Error en login: $e',
      );

      print(
        'Intentando iniciar sesión desde caché local...',
      );

      return await _intentarLoginLocal(
        correo,
        cedula,
      );
    }
  }

  // ============================================================
  // LOGIN LOCAL
  // ============================================================

  Future<Docente?> _intentarLoginLocal(
    String correo,
    String cedula,
  ) async {
    try {
      final bool credencialesCorrectas =
          await AsistenciaLocalService
              .validarCredencialesDocente(
        correo,
        cedula,
      );

      if (!credencialesCorrectas) {
        print(
          'Correo o cédula incorrectos para login offline.',
        );

        return null;
      }

      final Docente? docenteLocal =
          await AsistenciaLocalService
              .obtenerDocenteLocal();

      if (docenteLocal == null) {
        print(
          'No existe un docente guardado localmente.',
        );

        return null;
      }

      print(
        'Login offline exitoso.',
      );

      print(
        'Docente recuperado: ${docenteLocal.correo}',
      );

      return docenteLocal;
    } catch (e) {
      print(
        'Error intentando login local: $e',
      );

      return null;
    }
  }
}