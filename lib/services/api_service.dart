import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Necesario para el Timeout
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../models/asistencia_model.dart'; // Contiene Estudiante y AsistenciaEstudiante
import '../models/docente_model.dart';
import 'asistencia_local_service.dart'; // El servicio local para el modo Offline

class ApiService {
  // Nota: Si pruebas en un celular físico o emulador Android y no conecta, 
  // cambia 'localhost' por la IP de tu computadora (ej: 'http://192.168.x.x:5256/api')
  final String baseUrl = 'http://localhost:5256/api';

  http.Client _getClient() {
    HttpClient client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(client);
  }

  Future<List<Estudiante>> getEstudiantes() async {
    try {
      final client = _getClient();
      final response = await client.get(Uri.parse('$baseUrl/estudiante'));

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => Estudiante.fromJson(item)).toList();
      } else {
        throw Exception('Error al cargar estudiantes: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en getEstudiantes: $e');
      return [];
    }
  }

  // --- MÉTODO COMPATIBLE CON EL NOMBRE ANTERIOR ---
  // Este método resuelve el error de compilación devolviendo un bool.
  Future<bool> registrarAsistencia(AsistenciaEstudiante asistencia) async {
    final resultado = await registrarAsistenciaConMensaje(asistencia);
    // Retorna true si guardó (sea online u offline)
    return resultado == 'online' || resultado == 'offline';
  }

  // --- MÉTODO MODIFICADO PARA SOPORTE ONLINE/OFFLINE CON RETORNO DE ESTADO ---
  Future<String> registrarAsistenciaConMensaje(AsistenciaEstudiante asistencia) async {
    try {
      final client = _getClient();
      final response = await client.post(
        Uri.parse('$baseUrl/AsistenciaEstudiante'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(asistencia.toJson()),
      ).timeout(const Duration(seconds: 5)); 

      if (response.statusCode == 200 || response.statusCode == 201) {
        return 'online'; // Sincronizado directo con la base de datos
      } else {
        await AsistenciaLocalService.guardarAsistenciaLocal(asistencia);
        return 'offline'; // Guardado localmente por error del servidor
      }
    } catch (e) {
      // Si no hay internet o vence el timeout, se va al almacenamiento local
      await AsistenciaLocalService.guardarAsistenciaLocal(asistencia);
      return 'offline'; 
    }
  }

  // --- MÉTODO PARA SINCRONIZAR LOS DATOS PENDIENTES ---
  Future<void> sincronizarAsistenciasPendientes() async {
    try {
      // 1. Obtenemos las asistencias guardadas en el celular
      final pendientes = await AsistenciaLocalService.obtenerAsistenciasPendientes();
      
      if (pendientes.isEmpty) {
        print('No hay asistencias pendientes por sincronizar.');
        return;
      }

      print('Intentando sincronizar ${pendientes.length} asistencias a la API...');
      bool todasExitosas = true;

      // 2. Intentamos enviarlas una por una a la API
      for (var asistencia in pendientes) {
        final client = _getClient();
        final response = await client.post(
          Uri.parse('$baseUrl/AsistenciaEstudiante'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode(asistencia.toJson()),
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          todasExitosas = false; // Si una falla, marcamos como false
        }
      }

      // 3. Si todas subieron correctamente, borramos la memoria local del celular
      if (todasExitosas) {
        await AsistenciaLocalService.limpiarAsistenciasPendientes();
        print('Sincronización completada con éxito. Memoria local limpiada.');
      } else {
        print('Algunas asistencias no se pudieron sincronizar. Se reintentará luego.');
      }
    } catch (e) {
      print('Error al intentar sincronizar: $e');
    }
  }

  // Historial de asistencias seguro
  Future<List<AsistenciaEstudiante>> getHistorialAsistencia(int idAsignatura) async {
    try {
      final client = _getClient();
      final response = await client.get(Uri.parse('$baseUrl/AsistenciaEstudiante/asignatura/$idAsignatura'));

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        // Mapeo seguro adaptado al modelo existente
        return body.map((item) => AsistenciaEstudiante(
          idEstudiante: item['idEstudiante'] ?? 0,
          idAsignatura: item['idAsignatura'] ?? 0,
          idDocente: item['idDocente'] ?? 0,
          fechaAsistencia: item['fechaAsistencia'] ?? '',
          horaRegistro: item['horaRegistro'] ?? '',
          estadoAsistencia: item['estadoAsistencia'] ?? 'Presente',
        )).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Excepción en getHistorialAsistencia: $e');
      return [];
    }
  }

  Future<Docente?> loginDocente(String correo, String cedula) async {
    try {
      final client = _getClient();
      final encodedCorreo = Uri.encodeComponent(correo);
      final encodedCedula = Uri.encodeComponent(cedula);

      final url = Uri.parse('$baseUrl/docente/login?correo=$encodedCorreo&cedula=$encodedCedula');
      
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Docente.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }
}