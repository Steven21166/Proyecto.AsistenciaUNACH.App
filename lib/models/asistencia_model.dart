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

// Modelo para el Registro de Asistencia
class AsistenciaEstudiante {
  final int? idAsistencia;
  final int idEstudiante;
  final int idAsignatura;
  final int idDocente;
  final String fechaAsistencia;
  final String horaRegistro;
  final String estadoAsistencia;

  AsistenciaEstudiante({
    this.idAsistencia,
    required this.idEstudiante,
    required this.idAsignatura,
    required this.idDocente,
    required this.fechaAsistencia,
    required this.horaRegistro,
    required this.estadoAsistencia,
  });

  // Convertir a JSON (para enviar a la API o guardar localmente)
Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'idEstudiante': idEstudiante,
      'idAsignatura': idAsignatura,
      'idDocente': idDocente,
      'fechaAsistencia': fechaAsistencia,
      'horaRegistro': horaRegistro,
      'estadoAsistencia': estadoAsistencia,
    };
    
    // Solo lo incluimos si ya tiene un valor (para cuando se actualice)
    if (idAsistencia != null) {
      data['idAsistencia'] = idAsistencia;
    }
    
    return data;
  }

  // Convertir desde JSON (para leer de la memoria local o de la API)
  factory AsistenciaEstudiante.fromJson(Map<String, dynamic> json) {
    return AsistenciaEstudiante(
      idAsistencia: json['idAsistencia'],
      idEstudiante: json['idEstudiante'] ?? 0,
      idAsignatura: json['idAsignatura'] ?? 0,
      idDocente: json['idDocente'] ?? 0,
      fechaAsistencia: json['fechaAsistencia'] ?? '',
      horaRegistro: json['horaRegistro'] ?? '',
      estadoAsistencia: json['estadoAsistencia'] ?? '',
    );
  }
}