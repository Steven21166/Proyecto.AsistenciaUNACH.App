import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/asistencia_model.dart';
import '../models/docente_model.dart';

class ApiService {
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

  Future<bool> registrarAsistencia(AsistenciaEstudiante asistencia) async {
    try {
      final client = _getClient();
      final response = await client.post(
        Uri.parse('$baseUrl/AsistenciaEstudiante'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(asistencia.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Excepción al registrar asistencia: $e');
      return false;
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