import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asistencia_model.dart'; // <--- Apunta al archivo unificado

class AsistenciaLocalService {
  static const String _keyAsistenciasPendientes = 'asistencias_pendientes';

  static Future<void> guardarAsistenciaLocal(AsistenciaEstudiante asistencia) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listaString = prefs.getStringList(_keyAsistenciasPendientes) ?? [];
    listaString.add(jsonEncode(asistencia.toJson()));
    await prefs.setStringList(_keyAsistenciasPendientes, listaString);
  }

  static Future<List<AsistenciaEstudiante>> obtenerAsistenciasPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listaString = prefs.getStringList(_keyAsistenciasPendientes) ?? [];
    return listaString.map((item) => AsistenciaEstudiante.fromJson(jsonDecode(item))).toList();
  }

  static Future<void> limpiarAsistenciasPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAsistenciasPendientes);
  }
}