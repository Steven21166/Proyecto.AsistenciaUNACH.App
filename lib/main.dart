import 'package:flutter/material.dart';
import 'view/login_view.dart'; // Importa la vista de login correctamente

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asistencia UNACH Movil',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LoginView(), // Establece el LoginView como pantalla inicial
    );
  }
}