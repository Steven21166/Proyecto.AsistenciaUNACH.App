import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'materias_docente_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _correoController =
      TextEditingController();

  final TextEditingController _cedulaController =
      TextEditingController();

  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _intentarLogin() async {
    final correo = _correoController.text.trim();
    final cedula = _cedulaController.text.trim();

    // ----------------------------------------------------------
    // VALIDAR CAMPOS
    // ----------------------------------------------------------

    if (correo.isEmpty || cedula.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor ingrese correo y cédula.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --------------------------------------------------------
      // INTENTAR LOGIN
      //
      // ApiService decide automáticamente:
      //
      // ONLINE  -> API
      // OFFLINE -> docente guardado localmente
      // --------------------------------------------------------

      final docente = await _apiService.loginDocente(
        correo,
        cedula,
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // LOGIN CORRECTO
      // --------------------------------------------------------

      if (docente != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MateriasDocenteView(
              docente: docente,
            ),
          ),
        );
      }

      // --------------------------------------------------------
      // LOGIN INCORRECTO
      // --------------------------------------------------------

      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Correo o Cédula incorrectos.',
            ),
          ),
        );
      }
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo iniciar sesión: $e',
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // FINALIZAR CARGA
    // ----------------------------------------------------------

    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Card(
            elevation: 5,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),

            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  // ==================================================
                  // ICONO
                  // ==================================================

                  const Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // TÍTULO
                  // ==================================================

                  const Text(
                    'Asistencia UNACH',

                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // CORREO
                  // ==================================================

                  TextField(
                    controller: _correoController,

                    keyboardType:
                        TextInputType.emailAddress,

                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(
                        Icons.email,
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // CÉDULA
                  // ==================================================

                  TextField(
                    controller: _cedulaController,

                    keyboardType:
                        TextInputType.number,

                    obscureText: true,

                    decoration: const InputDecoration(
                      labelText: 'Cédula (Contraseña)',
                      prefixIcon: Icon(
                        Icons.lock,
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // BOTÓN INGRESAR
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.indigo,

                        foregroundColor:
                            Colors.white,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),

                      onPressed:
                          _isLoading
                              ? null
                              : _intentarLogin,

                      child: _isLoading
                          ? const SizedBox(
                              width: 25,
                              height: 25,

                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )

                          : const Text(
                              'Ingresar',

                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LIBERAR CONTROLADORES
  // ============================================================

  @override
  void dispose() {
    _correoController.dispose();
    _cedulaController.dispose();

    super.dispose();
  }
}