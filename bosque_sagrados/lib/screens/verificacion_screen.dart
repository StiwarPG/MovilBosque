import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart'; // Asegúrate de importar tu Home

const Color kGreenPrimary = Color(0xFF52C809);
const Color kBackground = Color(0xFFF0FEE7);

class VerificacionScreen extends StatefulWidget {
  const VerificacionScreen({super.key});

  @override
  State<VerificacionScreen> createState() => _VerificacionScreenState();
}

class _VerificacionScreenState extends State<VerificacionScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? userEmail;

  // Recuperar el correo enviado desde Login/Registro
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo lo leemos una vez si es nulo
    if (userEmail == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        userEmail = args;
      }
    }
  }

  Future<void> _verificarCodigo() async {
    final codigo = _codeController.text.trim();
    if (codigo.isEmpty || userEmail == null) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://www.bosquesagrado.somee.com/api/Usuarios/VerificarCodigo');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": userEmail,
          "codigo": codigo
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['exito'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Verificación exitosa!')),
          );
          // Ir al Home y borrar historial para no volver al login/verificación
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseBody['mensaje'] ?? 'Código incorrecto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no llegó el correo por alguna razón, mostramos error
    if (userEmail == null) {
      return const Scaffold(body: Center(child: Text("Error: No se recibió el correo")));
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Verificación'),
        backgroundColor: kGreenPrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ingresa el código enviado a:',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            Text(
              userEmail!,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Código de 6 dígitos',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verificarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreenPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verificar', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
