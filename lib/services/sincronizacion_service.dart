import 'dart:async';

import 'api_service.dart';
import 'asistencia_local_service.dart';

class SincronizacionService {
  static final SincronizacionService _instancia =
      SincronizacionService._interno();

  factory SincronizacionService() {
    return _instancia;
  }

  SincronizacionService._interno();

  final ApiService _apiService = ApiService();

  Timer? _timer;

  bool _ultimaConexion = false;

  bool _sincronizando = false;

  bool _iniciado = false;

  bool _comprobandoConexion = false;

  // ============================================================
  // INICIAR SERVICIO
  // ============================================================

  void iniciar() {
    if (_iniciado) {
      return;
    }

    _iniciado = true;

    print(
      '==========================================',
    );

    print(
      'SERVICIO DE SINCRONIZACIÓN INICIADO',
    );

    print(
      '==========================================',
    );

    _comprobarConexion();

    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) async {
        await _comprobarConexion();
      },
    );
  }

  // ============================================================
  // COMPROBAR CONEXIÓN
  // ============================================================

  Future<void> _comprobarConexion() async {
    if (_comprobandoConexion) {
      return;
    }

    _comprobandoConexion = true;

    try {
      final bool hayInternet =
          await _apiService.verificarConexionReal();

      final bool cambioConexion =
          hayInternet != _ultimaConexion;

      // Actualizar primero para evitar
      // dos sincronizaciones al mismo tiempo.
      _ultimaConexion = hayInternet;

      // --------------------------------------------------------
      // INTERNET DISPONIBLE
      // --------------------------------------------------------

      if (hayInternet) {
        if (cambioConexion) {
          print(
            '==========================================',
          );

          print(
            'CONEXIÓN: ONLINE',
          );

          print(
            '==========================================',
          );

          print(
            'INTERNET RESTAURADO',
          );

          print(
            'Buscando asistencias pendientes...',
          );

          print(
            '==========================================',
          );

          await _sincronizar();
        }
      }

      // --------------------------------------------------------
      // SIN INTERNET
      // --------------------------------------------------------

      else {
        if (cambioConexion) {
          print(
            '==========================================',
          );

          print(
            'CONEXIÓN: OFFLINE',
          );

          print(
            'Esperando restauración de Internet...',
          );

          print(
            '==========================================',
          );
        }
      }
    } catch (e) {
      print(
        'Error comprobando conexión global: $e',
      );
    } finally {
      _comprobandoConexion = false;
    }
  }

  // ============================================================
  // SINCRONIZAR
  // ============================================================

  Future<void> _sincronizar() async {
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

      if (pendientes.isEmpty) {
        print(
          'No existen asistencias pendientes.',
        );

        return;
      }

      print(
        '==========================================',
      );

      print(
        'SINCRONIZACIÓN AUTOMÁTICA',
      );

      print(
        'Pendientes: ${pendientes.length}',
      );

      print(
        '==========================================',
      );

      final bool resultado =
          await _apiService.sincronizarPendientes();

      if (resultado) {
        print(
          '==========================================',
        );

        print(
          'SINCRONIZACIÓN AUTOMÁTICA COMPLETADA',
        );

        print(
          'Las asistencias ya están en SQL Server.',
        );

        print(
          '==========================================',
        );
      } else {
        print(
          'Algunas asistencias todavía permanecen pendientes.',
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
  // DETENER
  // ============================================================

  void detener() {
    _timer?.cancel();

    _timer = null;

    _iniciado = false;

    _comprobandoConexion = false;

    print(
      'Servicio de sincronización detenido.',
    );
  }
}