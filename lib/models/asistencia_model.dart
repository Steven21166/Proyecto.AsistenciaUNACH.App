// Modelo para los Estudiantes
class Estudiante {
  final int idEstudiante;
  final String codigoEstudiante;
  final String nombres;
  final String apellidos;
  final int semestre;
  final String estado;

  Estudiante({
    required this.idEstudiante,
    required this.codigoEstudiante,
    required this.nombres,
    required this.apellidos,
    required this.semestre,
    required this.estado,
  });

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      idEstudiante: json['idEstudiante'] ?? 0,
      codigoEstudiante: json['codigoEstudiante'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      semestre: json['semestre'] ?? 0,
      estado: json['estado'] ?? '',
    );
  }
}

// Modelo para el Registro de Asistencia (que coincide con tu tabla central en SQL Server)
class AsistenciaEstudiante {
  final int? idAsistencia;
  final int idEstudiante;
  final int idAsignatura;
  final int idDocente;
  final String fechaAsistencia;
  final String horaRegistro;
  final String estadoAsistencia; // Ejemplo: 'Presente', 'Ausente', etc.

  AsistenciaEstudiante({
    this.idAsistencia,
    required this.idEstudiante,
    required this.idAsignatura,
    required this.idDocente,
    required this.fechaAsistencia,
    required this.horaRegistro,
    required this.estadoAsistencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'idAsistencia': idAsistencia,
      'idEstudiante': idEstudiante,
      'idAsignatura': idAsignatura,
      'idDocente': idDocente,
      'fechaAsistencia': fechaAsistencia,
      'horaRegistro': horaRegistro,
      'estadoAsistencia': estadoAsistencia,
    };
  }
} 