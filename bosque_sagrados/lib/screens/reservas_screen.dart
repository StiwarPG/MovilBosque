import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

// Colores
const Color kVerdePrincipal = Color(0xFF52C809);
const Color kVerdeClaro = Color(0xFFD4FCBB);
const Color kFondoSuave = Color(0xFFF0FEE7);
const Color kGrisClaro = Color(0xFFE6E6E6);

const String baseUrl = "http://www.bosquesagrado.somee.com/api";

void main() {
  runApp(const MyApp());
}

class ApiService {
  final String base;

  ApiService({this.base = baseUrl});

  Future<List<dynamic>> getList(String endpoint) async {
    final res = await http.get(Uri.parse("$base/$endpoint"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception('Error GET $endpoint: ${res.statusCode}');
    }
  }

  Future<List<dynamic>> getReservas() => getList("Reservas");
  Future<Map<String, dynamic>> getReserva(int id) async {
    final res = await http.get(Uri.parse("$base/Reservas/$id"));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Reserva no encontrada');
  }

  Future<http.Response> createReserva(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse("$base/Reservas"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return res;
  }

  Future<http.Response> updateReserva(int id, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse("$base/Reservas/$id"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return res;
  }

  Future<http.Response> deleteReserva(int id) async {
    return await http.delete(Uri.parse("$base/Reservas/$id"));
  }

  /// createAbono: envia multipart si hay comprobante
  /// Campos camelCase según tu modelo: idReserva, fechaAbono, montoAbono, idMetodoPago, verificacion
  Future<http.StreamedResponse> createAbono({
    required int idReserva,
    required double montoAbono,
    required DateTime fechaAbono,
    int? idMetodoPago,
    File? comprobanteFile,
    String? verificacionTexto,
  }) async {
    var uri = Uri.parse("$base/Abonos");
    var request = http.MultipartRequest('POST', uri);

    request.fields['idReserva'] = idReserva.toString();
    request.fields['montoAbono'] = montoAbono.toString();
    request.fields['fechaAbono'] = DateFormat('yyyy-MM-dd').format(fechaAbono);
    if (idMetodoPago != null) request.fields['idMetodoPago'] = idMetodoPago.toString();
    if (verificacionTexto != null) request.fields['verificacion'] = verificacionTexto;

    if (comprobanteFile != null) {
      var fileStream = http.ByteStream(comprobanteFile.openRead());
      fileStream.cast();
      var length = await comprobanteFile.length();
      var multipartFile = http.MultipartFile(
        'verificacionFile', // campo adjunto - ajústalo si tu backend espera otro nombre
        fileStream,
        length,
        filename: path.basename(comprobanteFile.path),
      );
      request.files.add(multipartFile);
    }

    return await request.send();
  }

  Future<List<dynamic>> getPaquetes() => getList("Paquetes");
  Future<List<dynamic>> getSedes() => getList("Sede");
  Future<List<dynamic>> getUsuarios() => getList("Usuarios");
  Future<List<dynamic>> getCabanas() => getList("Cabanas");
  Future<List<dynamic>> getMetodosPago() => getList("MetodoPago");
  Future<List<dynamic>> getEstadosReserva() => getList("EstadosReserva");
  Future<List<dynamic>> getServiciosReserva() => getList("ServiciosReserva");
  Future<List<dynamic>> getVentas() => getList("Ventas");
}

final api = ApiService();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Reservas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kVerdePrincipal,
        scaffoldBackgroundColor: kFondoSuave,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: kVerdePrincipal,
          secondary: kVerdeClaro,
          background: kFondoSuave,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kVerdePrincipal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const ReservasScreen(),
    );
  }
}

// ==================== PANTALLA LISTADO DE RESERVAS ====================
class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  List<Map<String, dynamic>> reservas = [];
  String busqueda = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  Future<void> _loadReservas() async {
    setState(() => loading = true);
    try {
      final data = await api.getReservas();
      reservas = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando reservas: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  String _s(dynamic map, String camel, [String? pascal]) {
    // helper para leer camelCase o PascalCase
    if (map == null) return '';
    if (map[camel] != null) return map[camel].toString();
    if (pascal != null && map[pascal] != null) return map[pascal].toString();
    return '';
  }

  void verReserva(Map<String, dynamic> r) {
    final fechaReserva = _s(r, 'fechaReserva', 'FechaReserva');
    final fechaEntrada = _s(r, 'fechaEntrada', 'FechaEntrada');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Detalle de Reserva", style: TextStyle(color: kVerdePrincipal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Id: ${_s(r, 'idReserva', 'IdReserva')}"),
            Text("FechaReserva: $fechaReserva"),
            Text("FechaEntrada: $fechaEntrada"),
            Text("MontoTotal: ${_s(r, 'montoTotal', 'MontoTotal')}"),
            Text("Abono: ${_s(r, 'abono', 'Abono')}"),
            Text("Restante: ${_s(r, 'restante', 'Restante')}"),
            Text("IdUsuario: ${_s(r, 'idUsuario', 'IdUsuario')}"),
            Text("IdSede: ${_s(r, 'idSede', 'IdSede')}"),
            Text("IdCabana: ${_s(r, 'idCabana', 'IdCabana')}"),
            Text("IdPaquete: ${_s(r, 'idPaquete', 'IdPaquete')}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
        ],
      ),
    );
  }

  Future<void> _crearEditarReserva({Map<String, dynamic>? reserva}) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CrearReservaScreen(reserva: reserva)),
    );
    if (res == true) {
      await _loadReservas();
    }
  }

  Future<void> _eliminarReserva(int id) async {
    try {
      final r = await api.deleteReserva(id);
      if (r.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva eliminada')));
        await _loadReservas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminar: ${r.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtros = busqueda.toLowerCase();
    final filtradas = reservas.where((r) {
      final usuario = _s(r, 'idUsuario', 'IdUsuario').toLowerCase();
      final sede = _s(r, 'idSede', 'IdSede').toLowerCase();
      final paquete = _s(r, 'idPaquete', 'IdPaquete').toLowerCase();
      return usuario.contains(filtros) || sede.contains(filtros) || paquete.contains(filtros);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reservas')),
      body: Column(
        children: [
          Container(
            color: kVerdeClaro,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar reserva por id/usuario/sede...",
                prefixIcon: const Icon(Icons.search, color: kVerdePrincipal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => busqueda = v),
            ),
          ),
          if (loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: filtradas.isEmpty
                  ? const Center(child: Text("No hay reservas registradas"))
                  : RefreshIndicator(
                onRefresh: _loadReservas,
                child: ListView.builder(
                  itemCount: filtradas.length,
                  itemBuilder: (context, index) {
                    final r = filtradas[index];
                    final idText = _s(r, 'idReserva', 'IdReserva');
                    final totalText = _s(r, 'montoTotal', 'MontoTotal');
                    final abonoText = _s(r, 'abono', 'Abono');
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: ListTile(
                        title: Text('Reserva #$idText', style: const TextStyle(color: kVerdePrincipal, fontWeight: FontWeight.bold)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Total: $totalText'),
                          Text('Abono: $abonoText'),
                        ]),
                        trailing: Wrap(spacing: 8, children: [
                          IconButton(icon: const Icon(Icons.visibility, color: Colors.blue), onPressed: () => verReserva(r)),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _crearEditarReserva(reserva: r)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarReserva(int.tryParse(idText) ?? 0)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar Reserva'),
                onPressed: () => _crearEditarReserva(),
                style: ElevatedButton.styleFrom(backgroundColor: kVerdePrincipal),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PANTALLA CREAR/EDITAR RESERVA ====================
class CrearReservaScreen extends StatefulWidget {
  final Map<String, dynamic>? reserva;
  const CrearReservaScreen({super.key, this.reserva});

  @override
  State<CrearReservaScreen> createState() => _CrearReservaScreenState();
}

class _CrearReservaScreenState extends State<CrearReservaScreen> {
  DateTime fechaRegistro = DateTime.now();
  DateTimeRange? rangoFechas;
  int? sedeSeleccionada;
  int? paqueteSeleccionado;
  List<int> serviciosSeleccionadosIds = [];

  double precioPaquete = 0;
  double precioServicios = 0;

  bool loading = true;
  List<dynamic> paquetes = [];
  List<dynamic> sedes = [];
  List<dynamic> usuarios = [];
  List<dynamic> cabanas = [];
  List<dynamic> metodosPago = [];

  int? usuarioSeleccionado;
  int? cabanaSeleccionada;
  int? metodoPagoSeleccionado;
  int? estadoSeleccionado;

  @override
  void initState() {
    super.initState();
    _loadCatalogos();
    if (widget.reserva != null) {
      try {
        if (widget.reserva!['idSede'] != null) sedeSeleccionada = widget.reserva!['idSede'];
        if (widget.reserva!['idPaquete'] != null) paqueteSeleccionado = widget.reserva!['idPaquete'];
        if (widget.reserva!['idUsuario'] != null) usuarioSeleccionado = widget.reserva!['idUsuario'];
        if (widget.reserva!['idCabana'] != null) cabanaSeleccionada = widget.reserva!['idCabana'];
        precioPaquete = (widget.reserva!['montoTotal'] ?? 0).toDouble();
      } catch (_) {}
    }
  }

  Future<void> _loadCatalogos() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        api.getPaquetes(),
        api.getSedes(),
        api.getUsuarios(),
        api.getCabanas(),
        api.getMetodosPago(),
        api.getEstadosReserva(),
      ]);
      paquetes = results[0];
      sedes = results[1];
      usuarios = results[2];
      cabanas = results[3];
      metodosPago = results[4];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando catálogos: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  int get total => (precioPaquete + precioServicios).toInt();
  int get abono => (total * 0.5).toInt();
  int get restante => total - abono;

  Future<void> _submitReserva() async {
    if (rangoFechas == null || sedeSeleccionada == null || paqueteSeleccionado == null || usuarioSeleccionado == null || cabanaSeleccionada == null || metodoPagoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos obligatorios')));
      return;
    }

    final body = {
      "fechaReserva": DateFormat('yyyy-MM-dd').format(fechaRegistro),
      "fechaEntrada": DateFormat('yyyy-MM-dd').format(rangoFechas!.start),
      // "fechaRegistro": DateFormat('yyyy-MM-dd').format(DateTime.now()), // normalmente lo maneja el servidor
      "abono": abono.toDouble(),
      "restante": restante.toDouble(),
      "montoTotal": total.toDouble(),
      "idUsuario": usuarioSeleccionado,
      "idEstado": estadoSeleccionado ?? 1,
      "idSede": sedeSeleccionada,
      "idCabana": cabanaSeleccionada,
      "idMetodoPago": metodoPagoSeleccionado,
      "idPaquete": paqueteSeleccionado,
    };

    try {
      http.Response res;
      if (widget.reserva != null && (widget.reserva!['idReserva'] ?? widget.reserva!['IdReserva']) != null) {
        final id = widget.reserva!['idReserva'] ?? widget.reserva!['IdReserva'];
        res = await api.updateReserva(int.tryParse(id.toString()) ?? 0, body);
        if (res.statusCode == 200 || res.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva actualizada')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error actualizar: ${res.statusCode} ${res.body}')));
        }
      } else {
        res = await api.createReserva(body);
        if (res.statusCode == 201 || res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva creada')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error crear: ${res.statusCode} ${res.body}')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reserva == null ? "Crear nueva reserva" : "Editar reserva"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.reserva == null ? "Agregar Reserva" : "Editar Reserva", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kVerdePrincipal)),
            const SizedBox(height: 12),
            Text("Fecha de registro: ${DateFormat('dd/MM/yyyy').format(fechaRegistro)}"),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(rangoFechas == null ? "Seleccionar Ingreso - Salida" : "${DateFormat('dd/MM').format(rangoFechas!.start)} - ${DateFormat('dd/MM/yyyy').format(rangoFechas!.end)}"),
              onPressed: () async {
                final picked = await showDateRangePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (picked != null) setState(() => rangoFechas = picked);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kVerdePrincipal),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: usuarioSeleccionado,
              decoration: InputDecoration(labelText: "Usuario", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: usuarios.map<DropdownMenuItem<int>>((u) {
                final id = u['idUsuario'] ?? u['IdUsuario'] ?? u['id'];
                final nombre = ((u['nombre'] ?? '') + ' ' + (u['apellido'] ?? '')).trim();
                final display = nombre.isNotEmpty ? nombre : (u['nombreCompleto'] ?? u['NombreCompleto'] ?? 'Usuario $id');
                return DropdownMenuItem<int>(value: id is int ? id : int.tryParse(id.toString()) ?? 0, child: Text(display.toString()));
              }).toList(),
              onChanged: (v) => setState(() => usuarioSeleccionado = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: sedeSeleccionada,
              decoration: InputDecoration(labelText: "Sede", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: sedes.map<DropdownMenuItem<int>>((s) {
                final id = s['idSede'] ?? s['IdSede'] ?? s['id'];
                final nombre = s['nombreSede'] ?? s['NombreSede'] ?? s['ubicacionSede'] ?? 'Sede $id';
                return DropdownMenuItem<int>(value: id is int ? id : int.tryParse(id.toString()) ?? 0, child: Text(nombre.toString()));
              }).toList(),
              onChanged: (v) => setState(() => sedeSeleccionada = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: cabanaSeleccionada,
              decoration: InputDecoration(labelText: "Cabana", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: cabanas.map<DropdownMenuItem<int>>((c) {
                final id = c['idCabana'] ?? c['IdCabana'] ?? c['id'];
                final nombre = c['nombre'] ?? c['Nombre'] ?? 'Cabana $id';
                final precio = c['precio'] ?? c['Precio'] ?? '';
                return DropdownMenuItem<int>(value: id is int ? id : int.tryParse(id.toString()) ?? 0, child: Text("$nombre ${precio != '' ? '- \$${precio}' : ''}"));
              }).toList(),
              onChanged: (v) => setState(() => cabanaSeleccionada = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: paqueteSeleccionado,
              decoration: InputDecoration(labelText: "Paquete", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: paquetes.map<DropdownMenuItem<int>>((p) {
                final id = p['idPaquete'] ?? p['IdPaquete'] ?? p['id'];
                final nombre = p['nombrePaquete'] ?? p['NombrePaquete'] ?? 'Paquete $id';
                final precio = p['precioPaquete'] ?? p['PrecioPaquete'] ?? '';
                return DropdownMenuItem<int>(value: id is int ? id : int.tryParse(id.toString()) ?? 0, child: Text("$nombre ${precio != '' ? '- \$${precio}' : ''}"));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  paqueteSeleccionado = v;
                  final paquete = paquetes.firstWhere((e) => (e['idPaquete'] ?? e['IdPaquete'] ?? e['id']) == v, orElse: () => null);
                  precioPaquete = 0;
                  if (paquete != null) {
                    if (paquete['precioPaquete'] != null) precioPaquete = (paquete['precioPaquete'] as num).toDouble();
                    else if (paquete['PrecioPaquete'] != null) precioPaquete = (paquete['PrecioPaquete'] as num).toDouble();
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: metodoPagoSeleccionado,
              decoration: InputDecoration(labelText: "Método de pago", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: metodosPago.map<DropdownMenuItem<int>>((m) {
                final id = m['idMetodoPago'] ?? m['IdMetodoPago'] ?? m['id'];
                final nombre = m['nombreMetodoPago'] ?? m['NombreMetodoPago'] ?? 'Método $id';
                return DropdownMenuItem<int>(value: id is int ? id : int.tryParse(id.toString()) ?? 0, child: Text(nombre.toString()));
              }).toList(),
              onChanged: (v) => setState(() => metodoPagoSeleccionado = v),
            ),
            const SizedBox(height: 16),
            const Divider(height: 30, thickness: 1, color: kGrisClaro),
            Text("💰 Abono: \$${abono}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("💳 Restante: \$${restante}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("💵 Monto total: \$${total}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitReserva, child: const Text("Confirmar reserva"), style: ElevatedButton.styleFrom(backgroundColor: kVerdePrincipal))),
          ],
        ),
      ),
    );
  }
}

// ==================== PANTALLA CONFIRMAR ABONO ====================
class ConfirmarAbonoScreen extends StatefulWidget {
  final int idReserva;
  final int total;
  final int abono;
  final int restante;

  const ConfirmarAbonoScreen({super.key, required this.idReserva, required this.total, required this.abono, required this.restante});

  @override
  State<ConfirmarAbonoScreen> createState() => _ConfirmarAbonoScreenState();
}

class _ConfirmarAbonoScreenState extends State<ConfirmarAbonoScreen> {
  File? comprobante;
  bool sending = false;
  int? metodoPagoSeleccionado;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => comprobante = File(picked.path));
  }

  Future<void> _enviarAbono() async {
    setState(() => sending = true);
    try {
      final resp = await api.createAbono(
        idReserva: widget.idReserva,
        montoAbono: widget.abono.toDouble(),
        fechaAbono: DateTime.now(),
        idMetodoPago: metodoPagoSeleccionado,
        comprobanteFile: comprobante,
        verificacionTexto: 'subido_desde_app',
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abono creado con éxito')));
        Navigator.pop(context, true);
      } else {
        final body = await resp.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error crear abono: ${resp.statusCode} - $body')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar abono')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Confirma el abono de tu reserva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kVerdePrincipal)),
            const SizedBox(height: 12),
            Text('💰 Total: \$${widget.total}\n💵 Abono (50%): \$${widget.abono}\n💳 Restante: \$${widget.restante}', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,3))]),
              child: Column(children: [
                const Text('Escanea el código QR para realizar el pago'),
                const SizedBox(height: 8),
                Image.network("https://i.ibb.co/fkFq3Rf/qr.png", height: 150),
                const SizedBox(height: 8),
                const Text('Cuenta de ahorros: 12345678900'),
              ]),
            ),
            const SizedBox(height: 12),
            comprobante != null ? Image.file(comprobante!, height: 100) : const Text('No has adjuntado comprobante'),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _pickImage, child: const Text('Adjuntar comprobante')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sending ? null : _enviarAbono,
                child: sending ? const CircularProgressIndicator() : const Text('Confirmar pago'),
                style: ElevatedButton.styleFrom(backgroundColor: kVerdePrincipal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
