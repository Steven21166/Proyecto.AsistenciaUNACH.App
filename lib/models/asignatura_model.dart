class Asignatura {
  final int idAsignatura;
  final String codigoAsignatura;
  final String nombreAsignatura;
  final int? semestre;

  Asignatura({
    required this.idAsignatura,
    required this.codigoAsignatura,
    required this.nombreAsignatura,
    this.semestre,
  });

  factory Asignatura.fromJson(Map<String, dynamic> json) {
    return Asignatura(
      idAsignatura: json['idAsignatura'],
      codigoAsignatura: json['codigoAsignatura'] ?? '',
      nombreAsignatura: json['nombreAsignatura'] ?? '',
      semestre: json['semestre'],
    );
  }
}