import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 🎨 Nueva paleta de colores verde moderna
const Color kVerdePrincipal = Color(0xFF52C809);
const Color kVerdeClaro = Color(0xFFD4FCBB);
const Color kFondoSuave = Color(0xFFF0FEE7);
const Color kGrisClaro = Color(0xFFE6E6E6);

// ✅ 1. Modelo actualizado según tu API
class Servicio {
  final int idServicio;
  final String nombreServicio;
  final double precioServicio;
  final String descripcion;
  final String imagen;
  final bool estado;

  Servicio({
    required this.idServicio,
    required this.nombreServicio,
    required this.precioServicio,
    required this.descripcion,
    required this.imagen,
    required this.estado,
  });

  // Factory para convertir JSON a Objeto
  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      idServicio: json['idServicio'] ?? 0,
      nombreServicio: json['nombreServicio'] ?? '',
      precioServicio: (json['precioServicio'] ?? 0).toDouble(),
      descripcion: json['descripcion'] ?? '',
      imagen: json['imagen'] ?? '',
      estado: json['estado'] ?? true,
    );
  }

  // Método para convertir Objeto a JSON (para enviar a la API)
  Map<String, dynamic> toJson() {
    return {
      'idServicio': idServicio,
      'nombreServicio': nombreServicio,
      'precioServicio': precioServicio,
      'descripcion': descripcion,
      'imagen': imagen,
      'estado': estado,
    };
  }
}

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  List<Servicio> servicios = [];
  List<Servicio> serviciosFiltrados = [];
  bool isLoading = true;

  // Controladores
  final TextEditingController _buscarCtrl = TextEditingController();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _imagenCtrl = TextEditingController();

  bool mostrandoFormulario = false;
  Servicio? servicioEnEdicion;

  final String apiUrl = "http://www.bosquesagrado.somee.com/api/Servicio";

  @override
  void initState() {
    super.initState();
    _obtenerServicios();
  }

  // ✅ GET: Obtener servicios de la API
  Future<void> _obtenerServicios() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          servicios = data.map((json) => Servicio.fromJson(json)).toList();
          serviciosFiltrados = List.from(servicios);
          isLoading = false;
        });
      } else {
        _mostrarError("Error al cargar servicios: ${response.statusCode}");
      }
    } catch (e) {
      _mostrarError("Error de conexión: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ POST: Crear servicio
  Future<void> _crearServicio() async {
    if (!_validarFormulario()) return;

    setState(() => isLoading = true);
    try {
      final nuevoServicio = {
        "idServicio": 0,
        "nombreServicio": _nombreCtrl.text,
        "precioServicio": double.tryParse(_precioCtrl.text) ?? 0,
        "descripcion": _descripcionCtrl.text,
        "imagen": _imagenCtrl.text.isEmpty ? "https://via.placeholder.com/150" : _imagenCtrl.text,
        "estado": true
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(nuevoServicio),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _limpiarFormulario();
        _obtenerServicios();
        setState(() => mostrandoFormulario = false);
        _mostrarExito("Servicio creado exitosamente");
      } else {
        _mostrarError("Error al crear: ${response.body}");
      }
    } catch (e) {
      _mostrarError("Error: $e");
    }
  }

  // ✅ PUT: Editar servicio
  Future<void> _actualizarServicio() async {
    if (servicioEnEdicion == null || !_validarFormulario()) return;

    setState(() => isLoading = true);
    try {
      final id = servicioEnEdicion!.idServicio;
      final servicioEditado = {
        "idServicio": id,
        "nombreServicio": _nombreCtrl.text,
        "precioServicio": double.tryParse(_precioCtrl.text) ?? 0,
        "descripcion": _descripcionCtrl.text,
        "imagen": _imagenCtrl.text,
        "estado": true
      };

      final response = await http.put(
        Uri.parse("$apiUrl/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(servicioEditado),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        _limpiarFormulario();
        _obtenerServicios();
        setState(() => mostrandoFormulario = false);
        _mostrarExito("Servicio actualizado");
      } else {
        _mostrarError("Error al actualizar: ${response.body}");
      }
    } catch (e) {
      _mostrarError("Error: $e");
    }
  }

  // ✅ DELETE: Eliminar servicio
  Future<void> _eliminarServicio(int id) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Servicio"),
        content: const Text("¿Estás seguro de eliminar este servicio?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirmar) return;

    setState(() => isLoading = true);
    try {
      final response = await http.delete(Uri.parse("$apiUrl/$id"));

      if (response.statusCode == 204 || response.statusCode == 200) {
        _obtenerServicios();
        _mostrarExito("Servicio eliminado");
      } else {
        _mostrarError("Error al eliminar");
      }
    } catch (e) {
      _mostrarError("Error de conexión");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- Lógica Local ---

  bool _validarFormulario() {
    if (_nombreCtrl.text.isEmpty || _precioCtrl.text.isEmpty || _descripcionCtrl.text.isEmpty) {
      _mostrarError("Por favor completa todos los campos obligatorios");
      return false;
    }
    return true;
  }

  void _buscar(String texto) {
    setState(() {
      serviciosFiltrados = servicios.where((s) =>
      s.nombreServicio.toLowerCase().contains(texto.toLowerCase()) ||
          s.descripcion.toLowerCase().contains(texto.toLowerCase())
      ).toList();
    });
  }

  void _prepararEdicion(Servicio servicio) {
    setState(() {
      mostrandoFormulario = true;
      servicioEnEdicion = servicio;

      _nombreCtrl.text = servicio.nombreServicio;
      _precioCtrl.text = servicio.precioServicio.toString();
      _descripcionCtrl.text = servicio.descripcion;
      _imagenCtrl.text = servicio.imagen;
    });
  }

  void _limpiarFormulario() {
    _nombreCtrl.clear();
    _precioCtrl.clear();
    _descripcionCtrl.clear();
    _imagenCtrl.clear();
    servicioEnEdicion = null;
  }

  void _mostrarError(String msg) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _mostrarExito(String msg) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kVerdePrincipal));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondoSuave,
      appBar: AppBar(
        title: const Text(
          'Servicios',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: kVerdePrincipal,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: mostrandoFormulario ? _buildFormulario() : _buildLista(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kVerdePrincipal,
        onPressed: () {
          setState(() {
            mostrandoFormulario = !mostrandoFormulario;
            if (!mostrandoFormulario) _limpiarFormulario();
            else _limpiarFormulario();
          });
        },
        icon: Icon(
          mostrandoFormulario ? Icons.arrow_back : Icons.add,
          color: Colors.white,
        ),
        label: Text(
          mostrandoFormulario ? 'Volver' : 'Agregar Servicio',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLista() {
    return Column(
      children: [
        Container(
          color: kVerdeClaro,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _buscarCtrl,
            decoration: InputDecoration(
              hintText: "Buscar servicio...",
              prefixIcon: const Icon(Icons.search, color: kVerdePrincipal),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _buscar,
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: kVerdePrincipal))
              : serviciosFiltrados.isEmpty
              ? const Center(
            child: Text(
              "No hay servicios registrados",
              style: TextStyle(color: Colors.black54),
            ),
          )
              : ListView.builder(
            itemCount: serviciosFiltrados.length,
            itemBuilder: (context, index) {
              final s = serviciosFiltrados[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  // 👇 AQUÍ ESTÁ EL CAMBIO: Al hacer tap, vamos al detalle
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServicioDetailScreen(servicio: s),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: kVerdeClaro,
                    backgroundImage: (s.imagen.isNotEmpty && s.imagen.startsWith('http'))
                        ? NetworkImage(s.imagen)
                        : null,
                    child: (s.imagen.isEmpty || !s.imagen.startsWith('http'))
                        ? const Icon(Icons.spa, color: kVerdePrincipal)
                        : null,
                  ),
                  title: Text(
                    s.nombreServicio,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: kVerdePrincipal,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "💲 Precio: \$${s.precioServicio}",
                          style: const TextStyle(color: Colors.black87),
                        ),
                        Text(
                          "📜 ${s.descripcion}",
                          maxLines: 2, // Limitamos líneas en la lista
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _prepararEdicion(s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarServicio(s.idServicio),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                servicioEnEdicion == null ? 'Agregar Servicio' : 'Editar Servicio',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: kVerdePrincipal,
                ),
              ),
              const SizedBox(height: 20),
              _input(_nombreCtrl, 'Nombre del Servicio'),
              const SizedBox(height: 10),
              _input(_precioCtrl, 'Precio', tipo: TextInputType.number),
              const SizedBox(height: 10),
              _input(_descripcionCtrl, 'Descripción'),
              const SizedBox(height: 10),
              _input(_imagenCtrl, 'URL de Imagen (Opcional)'),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVerdePrincipal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : (servicioEnEdicion == null ? _crearServicio : _actualizarServicio),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    servicioEnEdicion == null ? 'Guardar Servicio' : 'Guardar Cambios',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
      TextEditingController controller,
      String label, {
        TextInputType tipo = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

// 👇 NUEVA CLASE: PANTALLA DE DETALLE
class ServicioDetailScreen extends StatelessWidget {
  final Servicio servicio;

  const ServicioDetailScreen({super.key, required this.servicio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondoSuave,
      appBar: AppBar(
        title: Text(
          servicio.nombreServicio,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kVerdePrincipal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen Hero
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: kVerdeClaro,
                image: (servicio.imagen.isNotEmpty && servicio.imagen.startsWith('http'))
                    ? DecorationImage(
                  image: NetworkImage(servicio.imagen),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: (servicio.imagen.isEmpty || !servicio.imagen.startsWith('http'))
                  ? const Icon(Icons.spa, size: 100, color: kVerdePrincipal)
                  : null,
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          servicio.nombreServicio,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: kVerdePrincipal,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kVerdePrincipal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kVerdePrincipal),
                        ),
                        child: Text(
                          "\$${servicio.precioServicio}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kVerdePrincipal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Divisor
                  const Divider(thickness: 1, color: kGrisClaro),

                  const SizedBox(height: 20),

                  const Text(
                    "Descripción",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    servicio.descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Botón de acción (simulado)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Aquí podrías ir a reservar
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Función de reserva próximamente")),
                        );
                      },
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                      label: const Text(
                        "Reservar este servicio",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kVerdePrincipal,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
