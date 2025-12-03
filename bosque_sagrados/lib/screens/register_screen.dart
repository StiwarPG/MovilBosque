import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Asegúrate de agregar intl: ^0.18.0 en pubspec.yaml

/// 🎨 Nueva paleta verde fresca
const Color kGreenPrimary = Color(0xFF52C809);
const Color kGreenLight = Color(0xFFD4FCBB);
const Color kBackground = Color(0xFFF0FEE7);
const Color kGrayLight = Color(0xFFD9D9D9);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores
  String? _docType = 'C.C.';
  final TextEditingController _numController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController(); // Nuevo
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _celController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController(); // Nuevo
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _pass2Controller = TextEditingController();

  @override
  void dispose() {
    _numController.dispose();
    _nameController.dispose();
    _lastnameController.dispose();
    _correoController.dispose();
    _celController.dispose();
    _birthDateController.dispose();
    _passController.dispose();
    _pass2Controller.dispose();
    super.dispose();
  }

  // --- Lógica de Conexión API ---
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passController.text != _pass2Controller.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://www.bosquesagrado.somee.com/api/Usuarios');

      // Mapeo exacto a tu UsuarioDto de C#
      final Map<String, dynamic> userData = {
        "tipoDocumento": _docType,
        "numeroDocumento": _numController.text.trim(),
        "nombre": _nameController.text.trim(),
        "apellido": _lastnameController.text.trim(),
        "celular": _celController.text.trim(),
        "fechaNacimiento": _birthDateController.text, // YYYY-MM-DD
        "correo": _correoController.text.trim(),
        "contrasena": _passController.text,
        "idRol": 1, // Automático
        "estado": true,
        // idUsuario se ignora o se envía en 0
        // codigoVerificacion no se envía al crear, el backend lo genera
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registro exitoso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro exitoso. Verifica tu correo.'),
              backgroundColor: kGreenPrimary,
            ),
          );

          // Navegar a la pantalla de verificación pasando el correo
          // Asegúrate de tener definida esta ruta en tu main.dart
          Navigator.pushReplacementNamed(
              context,
              '/verificacion',
              arguments: _correoController.text.trim() // Enviamos el correo para validar después
          );
        }
      } else {
        // Error controlado por el backend (ej: correo duplicado, menor de edad)
        String mensajeError = responseBody['mensaje'] ?? 'Error desconocido';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Selector de Fecha (Valida > 18 años) ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    // Calculamos la fecha máxima permitida (hace 18 años desde hoy)
    final DateTime maxDate = DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxDate, // Empieza seleccionando hace 18 años
      firstDate: DateTime(1900),
      lastDate: maxDate, // No permite seleccionar fechas menores a 18 años
      helpText: "SELECCIONA TU FECHA DE NACIMIENTO (+18)",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kGreenPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Formato YYYY-MM-DD requerido por DateOnly de C#
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: kGrayLight),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: kGreenPrimary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width * 0.08;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kGreenPrimary,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Registro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Crear cuenta',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: kGreenPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Tipo Documento
                    DropdownButtonFormField<String>(
                      value: _docType,
                      items: const [
                        DropdownMenuItem(value: 'C.C.', child: Text('C.C.')),
                        DropdownMenuItem(value: 'T.I.', child: Text('T.I.')),
                        DropdownMenuItem(value: 'C.E.', child: Text('C.E.')),
                        DropdownMenuItem(value: 'Pasaporte', child: Text('Pasaporte')),
                      ],
                      onChanged: (v) => setState(() => _docType = v),
                      decoration: _fieldDecoration('Tipo de documento'),
                    ),
                    const SizedBox(height: 14),

                    // Número Documento
                    TextFormField(
                      controller: _numController,
                      decoration: _fieldDecoration('Número de documento'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Nombres
                    TextFormField(
                      controller: _nameController,
                      decoration: _fieldDecoration('Nombres'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Apellidos (Nuevo campo requerido por API)
                    TextFormField(
                      controller: _lastnameController,
                      decoration: _fieldDecoration('Apellidos'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Fecha Nacimiento (Nuevo campo requerido por API)
                    TextFormField(
                      controller: _birthDateController,
                      decoration: _fieldDecoration('Fecha de Nacimiento'),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (v) => v!.isEmpty ? 'Debes ser mayor de 18 años' : null,
                    ),
                    const SizedBox(height: 14),

                    // Correo
                    TextFormField(
                      controller: _correoController,
                      decoration: _fieldDecoration('Correo electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => !v!.contains('@') ? 'Correo inválido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Celular
                    TextFormField(
                      controller: _celController,
                      decoration: _fieldDecoration('Celular'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 14),

                    // Contraseña
                    TextFormField(
                      controller: _passController,
                      decoration: _fieldDecoration('Contraseña'),
                      obscureText: true,
                      validator: (v) => v!.length < 4 ? 'Mínimo 4 caracteres' : null,
                    ),
                    const SizedBox(height: 14),

                    // Confirmar Contraseña
                    TextFormField(
                      controller: _pass2Controller,
                      decoration: _fieldDecoration('Confirmar contraseña'),
                      obscureText: true,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 32),

                    // Botón Registrarse
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                          backgroundColor: kGreenPrimary,
                          shadowColor: kGreenPrimary.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Registrarse',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Pie de página
                    Text(
                      "Bosque Sagrado - Vive la experiencia",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
