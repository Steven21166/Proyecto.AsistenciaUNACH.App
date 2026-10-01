
import 'package:flutter/material.dart';
import '../models/docente_model.dart';
import '../screens/registro_asistencia_screen.dart';
import '../screens/historial_asistencia_screen.dart';
import 'login_view.dart';

class MateriasDocenteView extends StatelessWidget {
  final Docente docente;

  const MateriasDocenteView({
    Key? key,
    required this.docente,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // OBTENER ASIGNATURAS DEL DOCENTE
    // ============================================================

    final todasLasAsignaturas = docente.docenteAsignaturas
        .map((e) => e.asignaturaNavigation)
        .where((mat) => mat != null)
        .cast<Asignatura>()
        .toList();

    // ============================================================
    // ELIMINAR ASIGNATURAS REPETIDAS
    // ============================================================

    final Map<int, Asignatura> asignaturasUnicasMap = {};

    for (final asignatura in todasLasAsignaturas) {
      asignaturasUnicasMap[asignatura.idAsignatura] = asignatura;
    }

    final asignaturasUnicas = asignaturasUnicasMap.values.toList();

    // ============================================================
    // INTERFAZ
    // ============================================================

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bienvenido, ${docente.nombres}',
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,

        // ========================================================
        // BOTÓN CERRAR SESIÓN
        // ========================================================

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginView(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),

      // ==========================================================
      // CUERPO
      // ==========================================================

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ======================================================
            // TÍTULO
            // ======================================================

            const Text(
              'Tus Asignaturas Asignadas:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 16),

            // ======================================================
            // LISTA DE ASIGNATURAS
            // ======================================================

            Expanded(
              child: asignaturasUnicas.isEmpty
                  ? const Center(
                      child: Text(
                        'No tienes asignaturas registradas.',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: asignaturasUnicas.length,

                      itemBuilder: (context, index) {
                        final asignatura =
                            asignaturasUnicas[index];

                        return Card(
                          elevation: 3,

                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),

                          child: ListTile(
                            // ==================================================
                            // ICONO
                            // ==================================================

                            leading: const CircleAvatar(
                              backgroundColor: Colors.indigo,

                              child: Icon(
                                Icons.book,
                                color: Colors.white,
                              ),
                            ),

                            // ==================================================
                            // NOMBRE DE LA ASIGNATURA
                            // ==================================================

                            title: Text(
                              asignatura.nombreAsignatura,

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // ==================================================
                            // INFORMACIÓN
                            // ==================================================

                            subtitle: Text(
                              'Código: ${asignatura.codigoAsignatura} | '
                              'Semestre: ${asignatura.semestre}',
                            ),

                            // ==================================================
                            // FLECHA
                            // ==================================================

                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),

                            // ==================================================
                            // AL TOCAR UNA ASIGNATURA
                            // ==================================================

                            onTap: () {
                              _mostrarOpciones(
                                context,
                                asignatura,
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

  // ==============================================================
  // MOSTRAR OPCIONES DE LA ASIGNATURA
  // ==============================================================

  void _mostrarOpciones(
    BuildContext context,
    Asignatura asignatura,
  ) {
    showModalBottomSheet(
      context: context,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // ==================================================
              // NOMBRE DE LA ASIGNATURA
              // ==================================================

              Padding(
                padding: const EdgeInsets.all(16),

                child: Text(
                  asignatura.nombreAsignatura,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),

              const Divider(),

              // ==================================================
              // TOMAR ASISTENCIA
              // ==================================================

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,

                  child: Icon(
                    Icons.fact_check,
                    color: Colors.white,
                  ),
                ),

                title: const Text(
                  'Tomar asistencia',

                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: const Text(
                  'Registrar asistencia de los estudiantes',
                ),

                onTap: () {
                  Navigator.pop(bottomSheetContext);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegistroAsistenciaScreen(
                        asignatura: asignatura,
                        docente: docente,
                      ),
                    ),
                  );
                },
              ),

              // ==================================================
              // HISTORIAL DE ASISTENCIAS
              // ==================================================

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,

                  child: Icon(
                    Icons.history,
                    color: Colors.white,
                  ),
                ),

                title: const Text(
                  'Historial de asistencias',

                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: const Text(
                  'Consultar asistencias registradas',
                ),

                onTap: () {
                  Navigator.pop(bottomSheetContext);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistorialAsistenciaScreen(
                        asignatura: asignatura,
                        docente: docente,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
