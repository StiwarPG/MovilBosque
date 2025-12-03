import 'package:flutter/material.dart';
import 'servicios_screen.dart';
import 'reservas_screen.dart';
import 'paquetes_screen.dart';

/// 🎨 Paleta de colores renovada
const Color kGreenPrimary = Color(0xFF3CA20A); // Verde más natural
const Color kGreenLight = Color(0xFFD4FCBB);
const Color kBackground = Color(0xFFF0FEE7);
const Color kGrayLight = Color(0xFFD9D9D9);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Función para cerrar sesión
  void _logout(BuildContext context) {
    // Aquí podrías limpiar tokens o preferencias de usuario si los tuvieras
    // Por ahora, simplemente redirigimos al login y eliminamos el historial de navegación
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // PopScope bloquea el botón "Atrás" de Android para que no vuelvan al login por error
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(
          title: const Text(
            'Bosque Sagrado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          backgroundColor: kGreenPrimary,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.25),
          // Ocultamos el botón de "atrás" predeterminado
          automaticallyImplyLeading: false,
          // Agregamos el botón de Salir
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: 'Cerrar Sesión',
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // 🌿 Logo centrado con la imagen solicitada
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreenLight,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  // 👇 AQUÍ ESTÁ LA IMAGEN SOLICITADA
                  // ... dentro del Container en home_screen.dart
                  child: Image.asset(
                    "assets/images/bosqueimg.jpeg",
                    height: 110,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 110, color: Colors.red);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 🌲 Mensaje de bienvenida
                const Text(
                  "¡Bienvenido a Bosque Sagrado!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kGreenPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Explora nuestros servicios, paquetes y reserva tu experiencia única en la naturaleza.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // 🪄 Botones de navegación
                _buildHomeButton(
                  context,
                  icon: Icons.home_repair_service_rounded,
                  text: 'Servicios',
                  screen: const ServiciosScreen(),
                ),
                const SizedBox(height: 20),

                _buildHomeButton(
                  context,
                  icon: Icons.book_online_rounded,
                  text: 'Reservas',
                  screen: const ReservasScreen(),
                ),
                const SizedBox(height: 20),

                _buildHomeButton(
                  context,
                  icon: Icons.card_giftcard_rounded,
                  text: 'Paquetes',
                  screen: const PaquetesScreen(),
                ),

                const SizedBox(height: 45),

                // 🌿 Footer
                Text(
                  "Bosque Sagrado - Vive la experiencia",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🧭 Botón reutilizable con diseño moderno
  Widget _buildHomeButton(
      BuildContext context, {
        required IconData icon,
        required String text,
        required Widget screen,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kGreenPrimary, Color(0xFF4BC914)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kGreenPrimary.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
