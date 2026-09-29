import 'package:flutter/material.dart';
import '../models/docente_model.dart';
import '../screens/registro_asistencia_screen.dart';
import 'login_view.dart';

class MateriasDocenteView extends StatelessWidget {
  final Docente docente;

  const MateriasDocenteView({Key? key, required this.docente}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Extraemos todas las asignaturas válidas
    final todasLasAsignaturas = docente.docenteAsignaturas
        .map((e) => e.asignaturaNavigation)
        .where((mat) => mat != null)
        .cast<Asignatura>()
        .toList();

    // 2. Filtramos para que no se repitan usando un Map basado en el idAsignatura
    final Map<int, Asignatura> asignaturasUnicasMap = {};
    for (var mat in todasLasAsignaturas) {
      asignaturasUnicasMap[mat.idAsignatura] = mat;
    }
    final asignaturasUnicas = asignaturasUnicasMap.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, ${docente.nombres}'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tus Asignaturas Asignadas:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: asignaturasUnicas.isEmpty
                  ? const Center(
                      child: Text('No tienes asignaturas registradas.'),
                    )
                  : ListView.builder(
                      itemCount: asignaturasUnicas.length,
                      itemBuilder: (context, index) {
                        final asignatura = asignaturasUnicas[index];

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.indigo,
                              child: Icon(Icons.book, color: Colors.white),
                            ),
                            title: Text(
                              asignatura.nombreAsignatura,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                'Código: ${asignatura.codigoAsignatura} | Semestre: ${asignatura.semestre}'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navegamos pasando tanto la asignatura como el docente actual
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegistroAsistenciaScreen(
                                    asignatura: asignatura,
                                    docente: docente,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}