import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// 🎨 Paleta de colores verde moderna (Igual a Servicios)
const Color kVerdePrincipal = Color(0xFF52C809);
const Color kVerdeClaro = Color(0xFFD4FCBB);
const Color kFondoSuave = Color(0xFFF0FEE7);
const Color kGrisClaro = Color(0xFFE6E6E6);

// 🔗 CONSTANTES DE API
const String API_PAQUETES = "http://bosquesagrado.somee.com/api/Paquetes";
const String API_SERVICIOS = "http://bosquesagrado.somee.com/api/Servicio";
const String API_SEDES = "http://bosquesagrado.somee.com/api/Sede";
const String API_SERVICIO_POR_PAQUETE = "http://bosquesagrado.somee.com/api/ServicioPorPaquete";
const String API_SEDE_POR_PAQUETE = "http://bosquesagrado.somee.com/api/SedePorPaquete";

// ✅ 1. MODELOS
class Paquete {
  final int idPaquete;
  final String nombrePaquete;
  final double precioPaquete;
  final int personas;
  final int dias;
  final double descuento;
  final String imagen;
  final bool estado;

  Paquete({
    required this.idPaquete,
    required this.nombrePaquete,
    required this.precioPaquete,
    required this.personas,
    required this.dias,
    required this.descuento,
    required this.imagen,
    required this.estado,
  });

  factory Paquete.fromJson(Map<String, dynamic> json) {
    return Paquete(
      idPaquete: json['idPaquete'] ?? 0,
      nombrePaquete: json['nombrePaquete'] ?? '',
      precioPaquete: (json['precioPaquete'] ?? 0).toDouble(),
      personas: json['personas'] ?? 0,
      dias: json['dias'] ?? 0,
      descuento: (json['descuento'] ?? 0).toDouble(),
      imagen: json['imagen'] ?? '',
      estado: json['estado'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idPaquete': idPaquete,
      'nombrePaquete': nombrePaquete,
      'precioPaquete': precioPaquete,
      'personas': personas,
      'dias': dias,
      'descuento': descuento,
      'imagen': imagen,
      'estado': estado,
    };
  }
}

class Servicio {
  final int idServicio;
  final String nombreServicio;
  bool seleccionado;

  Servicio({required this.idServicio, required this.nombreServicio, this.seleccionado = false});

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      idServicio: json['idServicio'] ?? 0,
      nombreServicio: json['nombreServicio'] ?? 'Sin nombre',
    );
  }
}

class Sede {
  final int idSede;
  final String nombreSede;
  final String ubicacionSede;

  Sede({required this.idSede, required this.nombreSede, required this.ubicacionSede});

  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      idSede: json['idSede'] ?? 0,
      nombreSede: json['nombreSede'] ?? 'Sin nombre',
      ubicacionSede: json['ubicacionSede'] ?? '',
    );
  }
}

// 📱 PANTALLA PRINCIPAL
class PaquetesScreen extends StatefulWidget {
  const PaquetesScreen({super.key});

  @override
  State<PaquetesScreen> createState() => _PaquetesScreenState();
}

class _PaquetesScreenState extends State<PaquetesScreen> {
  List<Paquete> paquetes = [];
  List<Paquete> paquetesFiltrados = [];

  // Listas para selects
  List<Servicio> serviciosDisponibles = [];
  List<Sede> sedesDisponibles = [];

  bool isLoading = true;

  // Controladores Formulario
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController();
  final TextEditingController _personasCtrl = TextEditingController();
  final TextEditingController _diasCtrl = TextEditingController();
  final TextEditingController _descuentoCtrl = TextEditingController();
  final TextEditingController _busquedaCtrl = TextEditingController();

  // Variables de Selección
  File? _imagenSeleccionada;
  String _imagenBase64 = "";
  final ImagePicker _picker = ImagePicker();

  int? _sedeSeleccionadaId;
  List<int> _serviciosSeleccionadosIds = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => isLoading = true);
    await Future.wait([
      _obtenerPaquetes(),
      _obtenerServicios(),
      _obtenerSedes(),
    ]);
    setState(() => isLoading = false);
  }

  // --- APIS GET ---
  Future<void> _obtenerPaquetes() async {
    try {
      final response = await http.get(Uri.parse(API_PAQUETES));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          paquetes = data.map((json) => Paquete.fromJson(json)).toList();
          paquetesFiltrados = List.from(paquetes);
        });
      }
    } catch (e) {
      debugPrint("Error paquetes: $e");
    }
  }

  Future<void> _obtenerServicios() async {
    try {
      final response = await http.get(Uri.parse(API_SERVICIOS));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          serviciosDisponibles = data.map((json) => Servicio.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error servicios: $e");
    }
  }

  Future<void> _obtenerSedes() async {
    try {
      final response = await http.get(Uri.parse(API_SEDES));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          sedesDisponibles = data.map((json) => Sede.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error sedes: $e");
    }
  }

  // --- LÓGICA DE CREACIÓN (POST) ---
  Future<void> _crearPaqueteCompleto() async {
    if (!_validarCampos()) return;
    Navigator.pop(context);
    setState(() => isLoading = true);

    try {
      String imagenFinal = _imagenBase64.isNotEmpty ? _imagenBase64 : "https://via.placeholder.com/150";

      final nuevoPaquete = {
        "idPaquete": 0,
        "nombrePaquete": _nombreCtrl.text,
        "precioPaquete": double.tryParse(_precioCtrl.text) ?? 0,
        "personas": int.tryParse(_personasCtrl.text) ?? 1,
        "dias": int.tryParse(_diasCtrl.text) ?? 1,
        "descuento": double.tryParse(_descuentoCtrl.text) ?? 0,
        "imagen": imagenFinal,
        "estado": true
      };

      final responsePaquete = await http.post(
        Uri.parse(API_PAQUETES),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(nuevoPaquete),
      );

      if (responsePaquete.statusCode == 200 || responsePaquete.statusCode == 201) {
        final paqueteCreado = jsonDecode(responsePaquete.body);
        final int idPaquete = paqueteCreado['idPaquete'];

        if (_sedeSeleccionadaId != null) {
          await http.post(
            Uri.parse(API_SEDE_POR_PAQUETE),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "idSedePorPaquete": 0,
              "idSede": _sedeSeleccionadaId,
              "idPaquete": idPaquete,
              "estado": true
            }),
          );
        }

        for (int idServicio in _serviciosSeleccionadosIds) {
          await http.post(
            Uri.parse(API_SERVICIO_POR_PAQUETE),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "idServicioPorPaquete": 0,
              "idServicio": idServicio,
              "idPaquete": idPaquete,
              "estado": true
            }),
          );
        }

        _obtenerPaquetes();
        _mostrarSnack("Paquete creado exitosamente", kVerdePrincipal);
      } else {
        _mostrarSnack("Error al crear: ${responsePaquete.body}", Colors.red);
      }
    } catch (e) {
      _mostrarSnack("Error crítico: $e", Colors.red);
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  // --- LÓGICA DE EDICIÓN (PUT) ---
  Future<void> _editarPaqueteBase(int idPaquete, String imagenOriginal) async {
    if (!_validarCampos()) return;
    Navigator.pop(context);
    setState(() => isLoading = true);

    try {
      String imagenFinal = _imagenBase64.isNotEmpty ? _imagenBase64 : imagenOriginal;

      final paqueteEditado = {
        "idPaquete": idPaquete,
        "nombrePaquete": _nombreCtrl.text,
        "precioPaquete": double.tryParse(_precioCtrl.text) ?? 0,
        "personas": int.tryParse(_personasCtrl.text) ?? 1,
        "dias": int.tryParse(_diasCtrl.text) ?? 1,
        "descuento": double.tryParse(_descuentoCtrl.text) ?? 0,
        "imagen": imagenFinal,
        "estado": true
      };

      final response = await http.put(
        Uri.parse("$API_PAQUETES/$idPaquete"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(paqueteEditado),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _obtenerPaquetes();
        _mostrarSnack("Paquete actualizado correctamente", kVerdePrincipal);
      } else {
        _mostrarSnack("Error al actualizar: ${response.body}", Colors.red);
      }
    } catch (e) {
      _mostrarSnack("Error: $e", Colors.red);
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  // --- ELIMINAR ---
  Future<void> _eliminarPaquete(int id) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Paquete"),
        content: const Text("¿Seguro que deseas eliminar este paquete?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirmar) return;

    setState(() => isLoading = true);
    try {
      final response = await http.delete(Uri.parse("$API_PAQUETES/$id"));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _obtenerPaquetes();
        _mostrarSnack("Paquete eliminado", kVerdePrincipal);
      } else {
        _mostrarSnack("Error al eliminar", Colors.red);
      }
    } catch (e) {
      _mostrarSnack("Error de conexión", Colors.red);
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  // --- IMAGEN ---
  Future<void> _seleccionarImagen(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imagenSeleccionada = File(pickedFile.path));
      List<int> imageBytes = await _imagenSeleccionada!.readAsBytes();
      _imagenBase64 = "data:image/jpeg;base64,${base64Encode(imageBytes)}";
    }
  }

  // --- HELPERS ---
  void _mostrarSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  bool _validarCampos() {
    if (_nombreCtrl.text.isEmpty || _precioCtrl.text.isEmpty) {
      _mostrarSnack("Nombre y precio son obligatorios", Colors.orange);
      return false;
    }
    return true;
  }

  void _filtrar(String texto) {
    setState(() {
      paquetesFiltrados = paquetes.where((p) => p.nombrePaquete.toLowerCase().contains(texto.toLowerCase())).toList();
    });
  }

  // --- HELPER IMAGEN PARA LISTA Y DIÁLOGO ---
  // Devuelve un ImageProvider o un Widget según el caso
  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(url.split(',').last));
      } catch (e) {
        return const NetworkImage("https://via.placeholder.com/150");
      }
    } else if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    return const NetworkImage("https://via.placeholder.com/150");
  }

  Widget _buildImagenPreview(String url) {
    if (url.startsWith('data:image')) {
      try { return Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover); } catch (e) { return const Icon(Icons.error); }
    }
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.broken_image));
  }

  // --- UI DIÁLOGO (CREAR / EDITAR) ---
  void _mostrarDialogoPaquete({Paquete? paquete}) {
    _imagenSeleccionada = null;
    _imagenBase64 = "";
    _sedeSeleccionadaId = null;
    _serviciosSeleccionadosIds = [];

    for (var s in serviciosDisponibles) { s.seleccionado = false; }

    if (paquete != null) {
      _nombreCtrl.text = paquete.nombrePaquete;
      _precioCtrl.text = paquete.precioPaquete.toString();
      _personasCtrl.text = paquete.personas.toString();
      _diasCtrl.text = paquete.dias.toString();
      _descuentoCtrl.text = paquete.descuento.toString();
      _imagenBase64 = paquete.imagen;
    } else {
      _nombreCtrl.clear();
      _precioCtrl.clear();
      _personasCtrl.clear();
      _diasCtrl.clear();
      _descuentoCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(paquete == null ? 'Nuevo Paquete' : 'Editar Paquete',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kVerdePrincipal)),
                      const SizedBox(height: 16),

                      // FOTO
                      GestureDetector(
                        onTap: () => _mostrarOpcionesFoto(setStateDialog),
                        child: Container(
                          height: 120, width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: kVerdeClaro),
                          ),
                          child: _imagenSeleccionada != null
                              ? Image.file(_imagenSeleccionada!, fit: BoxFit.cover)
                              : (paquete != null && paquete.imagen.isNotEmpty)
                              ? _buildImagenPreview(paquete.imagen)
                              : const Icon(Icons.add_a_photo, color: kVerdePrincipal, size: 40),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // CAMPOS
                      _input(_nombreCtrl, 'Nombre'),
                      const SizedBox(height: 10),
                      _input(_precioCtrl, 'Precio', tipo: TextInputType.number),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _input(_personasCtrl, 'Personas', tipo: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: _input(_diasCtrl, 'Días', tipo: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _input(_descuentoCtrl, 'Descuento %', tipo: TextInputType.number),

                      const Divider(height: 30, color: kVerdePrincipal),

                      if (paquete == null) ...[
                        DropdownButtonFormField<int>(
                          value: _sedeSeleccionadaId,
                          decoration: _inputDecoration('Asignar Sede'),
                          items: sedesDisponibles.map((sede) {
                            return DropdownMenuItem(value: sede.idSede, child: Text(sede.nombreSede));
                          }).toList(),
                          onChanged: (val) => setStateDialog(() => _sedeSeleccionadaId = val),
                        ),
                        const SizedBox(height: 15),
                        const Text("Asignar Servicios", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: serviciosDisponibles.length,
                            itemBuilder: (context, index) {
                              final serv = serviciosDisponibles[index];
                              return CheckboxListTile(
                                title: Text(serv.nombreServicio, style: const TextStyle(fontSize: 14)),
                                value: serv.seleccionado,
                                activeColor: kVerdePrincipal,
                                dense: true,
                                onChanged: (bool? val) {
                                  setStateDialog(() {
                                    serv.seleccionado = val ?? false;
                                    if (serv.seleccionado) {
                                      _serviciosSeleccionadosIds.add(serv.idServicio);
                                    } else {
                                      _serviciosSeleccionadosIds.remove(serv.idServicio);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "Para modificar servicios o sedes, por favor elimine y cree el paquete nuevamente.",
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                          textAlign: TextAlign.center,
                        )
                      ],

                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kVerdePrincipal),
                        onPressed: () {
                          if (paquete == null) {
                            _crearPaqueteCompleto();
                          } else {
                            _editarPaqueteBase(paquete.idPaquete, paquete.imagen);
                          }
                        },
                        child: Text(paquete == null ? 'Guardar Configuración' : 'Actualizar Paquete',
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarOpcionesFoto(Function setStateDialog) {
    showModalBottomSheet(
        context: context,
        builder: (b) => Container(
          height: 120,
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Cámara'), onTap: () { Navigator.pop(context); _seleccionarImagen(ImageSource.camera).then((_) => setStateDialog((){})); }),
            ListTile(leading: const Icon(Icons.image), title: const Text('Galería'), onTap: () { Navigator.pop(context); _seleccionarImagen(ImageSource.gallery).then((_) => setStateDialog((){})); }),
          ]),
        )
    );
  }

  Widget _input(TextEditingController c, String label, {TextInputType tipo = TextInputType.text}) {
    return TextField(controller: c, keyboardType: tipo, decoration: _inputDecoration(label));
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondoSuave,
      appBar: AppBar(
        title: const Text(
          'Paquetes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: kVerdePrincipal,
        elevation: 1,
      ),
      body: Column(
        children: [
          // ✅ DISEÑO DE BUSCADOR IGUAL A SERVICIOS
          Container(
            color: kVerdeClaro,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: "Buscar paquete...",
                prefixIcon: const Icon(Icons.search, color: kVerdePrincipal),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filtrar,
            ),
          ),

          // ✅ LISTA DISEÑO IGUAL A SERVICIOS
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: kVerdePrincipal))
                : paquetesFiltrados.isEmpty
                ? const Center(child: Text("No hay paquetes registrados", style: TextStyle(color: Colors.black54)))
                : ListView.builder(
              itemCount: paquetesFiltrados.length,
              itemBuilder: (ctx, i) {
                final p = paquetesFiltrados[i];
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
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaqueteDetailScreen(paquete: p))),
                    // ✅ Círculo de Imagen igual a Servicios
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: kVerdeClaro,
                      backgroundImage: _getImageProvider(p.imagen),
                      child: (p.imagen.isEmpty || (!p.imagen.startsWith('http') && !p.imagen.startsWith('data')))
                          ? const Icon(Icons.card_giftcard, color: kVerdePrincipal)
                          : null,
                    ),
                    title: Text(
                      p.nombrePaquete,
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
                          Text("💲 Precio: \$${p.precioPaquete.toStringAsFixed(0)}", style: const TextStyle(color: Colors.black87)),
                          Text("👥 Personas: ${p.personas} | 📅 ${p.dias} Días", style: const TextStyle(color: Colors.black54)),
                          if(p.descuento > 0) Text("🔥 ${p.descuento}% Descuento", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _mostrarDialogoPaquete(paquete: p)
                        ),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarPaquete(p.idPaquete)
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kVerdePrincipal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Agregar Paquete", style: TextStyle(color: Colors.white)),
        onPressed: () => _mostrarDialogoPaquete(),
      ),
    );
  }
}

// 👇 PANTALLA DETALLE
class PaqueteDetailScreen extends StatefulWidget {
  final Paquete paquete;
  const PaqueteDetailScreen({super.key, required this.paquete});

  @override
  State<PaqueteDetailScreen> createState() => _PaqueteDetailScreenState();
}

class _PaqueteDetailScreenState extends State<PaqueteDetailScreen> {
  List<String> nombresServicios = [];
  Sede? sedeAsignada;
  bool loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _cargarDetallesRelacionados();
  }

  Future<void> _cargarDetallesRelacionados() async {
    try {
      final respServicios = await http.get(Uri.parse(API_SERVICIOS));
      final List<dynamic> allServiciosJson = jsonDecode(respServicios.body);
      final allServicios = allServiciosJson.map((j) => Servicio.fromJson(j)).toList();

      final respSedes = await http.get(Uri.parse(API_SEDES));
      final List<dynamic> allSedesJson = jsonDecode(respSedes.body);
      final allSedes = allSedesJson.map((j) => Sede.fromJson(j)).toList();

      final respSxP = await http.get(Uri.parse(API_SERVICIO_POR_PAQUETE));
      final List<dynamic> sxpList = jsonDecode(respSxP.body);
      final misRelacionesServ = sxpList.where((item) => item['idPaquete'] == widget.paquete.idPaquete).toList();

      List<String> tempNombres = [];
      for (var rel in misRelacionesServ) {
        final servEncontrado = allServicios.firstWhere(
              (s) => s.idServicio == rel['idServicio'],
          orElse: () => Servicio(idServicio: 0, nombreServicio: 'Desconocido'),
        );
        tempNombres.add(servEncontrado.nombreServicio);
      }

      final respSedeP = await http.get(Uri.parse(API_SEDE_POR_PAQUETE));
      final List<dynamic> sedePList = jsonDecode(respSedeP.body);
      final miRelacionSede = sedePList.firstWhere(
            (item) => item['idPaquete'] == widget.paquete.idPaquete,
        orElse: () => null,
      );

      Sede? tempSede;
      if (miRelacionSede != null) {
        tempSede = allSedes.firstWhere(
              (s) => s.idSede == miRelacionSede['idSede'],
          orElse: () => Sede(idSede: 0, nombreSede: 'Desconocida', ubicacionSede: ''),
        );
      }

      if (mounted) {
        setState(() {
          nombresServicios = tempNombres;
          sedeAsignada = tempSede;
          loadingDetails = false;
        });
      }

    } catch (e) {
      debugPrint("Error cargando detalles: $e");
      if (mounted) setState(() => loadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.paquete.nombrePaquete, style: const TextStyle(color: Colors.white)), backgroundColor: kVerdePrincipal),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250, width: double.infinity,
              child: widget.paquete.imagen.startsWith('data')
                  ? Image.memory(base64Decode(widget.paquete.imagen.split(',').last), fit: BoxFit.cover)
                  : Image.network(widget.paquete.imagen, fit: BoxFit.cover, errorBuilder: (c,o,s) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50))),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.paquete.nombrePaquete, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kVerdePrincipal))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: kVerdePrincipal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text("\$${widget.paquete.precioPaquete}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kVerdePrincipal)),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _chip(Icons.people, "${widget.paquete.personas} Personas"),
                    _chip(Icons.calendar_today, "${widget.paquete.dias} Días"),
                    if(widget.paquete.descuento > 0) _chip(Icons.percent, "${widget.paquete.descuento}% Desc.", color: Colors.orange),
                  ]),

                  const SizedBox(height: 20),
                  const Divider(),

                  if (loadingDetails)
                    const Center(child: CircularProgressIndicator(color: kVerdePrincipal))
                  else ...[
                    if (sedeAsignada != null) ...[
                      const Text("Sede Disponible", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: kVerdePrincipal),
                          title: Text(sedeAsignada!.nombreSede, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(sedeAsignada!.ubicacionSede),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (nombresServicios.isNotEmpty) ...[
                      const Text("Servicios Incluidos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: nombresServicios.map((nombre) => Chip(
                          label: Text(nombre),
                          backgroundColor: kFondoSuave,
                          avatar: const Icon(Icons.check_circle, size: 18, color: kVerdePrincipal),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      const Text("Este paquete no tiene servicios asociados.", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                    ]
                  ],

                  const Divider(),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kVerdePrincipal, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: (){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente: Reservar"))); },
                      child: const Text("Reservar Ahora", style: TextStyle(color: Colors.white, fontSize: 18))
                  ))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color color = kVerdePrincipal}) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.all(4),
    );
  }
}