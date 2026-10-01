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
  try {
    final bool hayInternet =
        await _apiService.verificarConexionReal();

    // La conexión acaba de volver
    if (!_ultimaConexion && hayInternet) {
      print('==========================================');
      print('INTERNET RESTAURADO');
      print('Buscando asistencias pendientes...');
      print('==========================================');

      await _sincronizar();
    }

    // Mostrar solamente cuando cambia el estado
    if (hayInternet != _ultimaConexion) {
      if (hayInternet) {
        print('CONEXIÓN: ONLINE');
      } else {
        print('CONEXIÓN: OFFLINE');
      }
    }

    _ultimaConexion = hayInternet;
  } catch (e) {
    print(
      'Error comprobando conexión global: $e',
    );
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

    print(
      'Servicio de sincronización detenido.',
    );
  }
}