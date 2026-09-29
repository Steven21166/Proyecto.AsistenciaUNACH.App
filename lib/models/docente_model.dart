class Docente {
  final int idDocente;
  final String nombres;
  final String apellidos;
  final String correo;
  final List<DocenteAsignatura> docenteAsignaturas;

  Docente({
    required this.idDocente,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.docenteAsignaturas,
  });

  factory Docente.fromJson(Map<String, dynamic> json) {
    var rawList = json['docenteAsignaturas'];
    List<DocenteAsignatura> asignaturasList = [];

    if (rawList != null && rawList is List) {
      asignaturasList = rawList
          .where((i) => i != null && i is Map<String, dynamic>)
          .map((i) => DocenteAsignatura.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return Docente(
      idDocente: json['idDocente'] ?? 0,
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      correo: json['correo'] ?? '',
      docenteAsignaturas: asignaturasList,
    );
  }
}

class DocenteAsignatura {
  final int idAsignatura;
  final Asignatura? asignaturaNavigation;

  DocenteAsignatura({
    required this.idAsignatura,
    this.asignaturaNavigation,
  });

  factory DocenteAsignatura.fromJson(Map<String, dynamic> json) {
    var navData = json['idAsignaturaNavigation'];
    return DocenteAsignatura(
      idAsignatura: json['idAsignatura'] ?? 0,
      asignaturaNavigation: navData != null && navData is Map<String, dynamic>
          ? Asignatura.fromJson(navData)
          : null,
    );
  }
}

class Asignatura {
  final int idAsignatura;
  final String codigoAsignatura;
  final String nombreAsignatura;
  final int semestre;

  Asignatura({
    required this.idAsignatura,
    required this.codigoAsignatura,
    required this.nombreAsignatura,
    required this.semestre,
  });

  factory Asignatura.fromJson(Map<String, dynamic> json) {
    return Asignatura(
      idAsignatura: json['idAsignatura'] ?? 0,
      codigoAsignatura: json['codigoAsignatura'] ?? '',
      nombreAsignatura: json['nombreAsignatura'] ?? '',
      semestre: json['semestre'] ?? 0,
    );
  }
}