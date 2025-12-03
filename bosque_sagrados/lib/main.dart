import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Importaciones de tus pantallas
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verificacion_screen.dart'; // 👈 IMPORTANTE: Importar la nueva pantalla

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bosque Sagrado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFB38B59),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      // Define la ruta inicial
      initialRoute: '/login',
      // Tabla de rutas
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        // 👇 AQUÍ ESTÁ LA SOLUCIÓN: Registramos la ruta que faltaba
        '/verificacion': (_) => const VerificacionScreen(),
      },
    );
  }
}
