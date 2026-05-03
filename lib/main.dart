import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

//  IMPORTACIONES: Cargo las librerías necesarias - Las dos ultimas son para mi base de datos


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // WEB - EDGE
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCPVpPG77WM3a274GXW00mm4OdiTPQO2Lw",
        appId: "1:199502162114:web:c2e95b7767b932e297f35b",
        messagingSenderId: "199502162114",
        projectId: "team-connect-sport",
        authDomain: "team-connect-sport.firebaseapp.com",
        storageBucket: "team-connect-sport.firebasestorage.app",
      ),
    );
  } else {
    // ANDROID - APP
    await Firebase.initializeApp();
  }

  runApp(const TeamConnectApp());
}

class TeamConnectApp extends StatelessWidget {
  const TeamConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeamConnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4B8A),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- 1. PANTALLA DE CARGA ---
class SplashScreen extends StatefulWidget {   // Uso StatefulWidget porque la pantalla necesita realizar una acción automática al iniciarse
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();  // Temporizador: Espera 3 segundos y luego entro a la pantalla de Login
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())); // Navigator.pushReplacement: Cambia de pantalla y "borra" la anterior para que no se pueda volver atrás
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 220,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_soccer, size: 100, color: Color(0xFF1B4B8A))),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// --- 2. PANTALLA DE LOGIN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String rolSeleccionado = 'Entrenador';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Image.asset(
              'assets/images/logo.png',
              height: 160,
              errorBuilder: (c, e, s) =>
              const Icon(Icons.login, size: 80),
            ),
            const SizedBox(height: 20),
            const Text(
              "TeamConnect",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4B8A),
              ),
            ),
            const SizedBox(height: 40),

            // SELECCIONO ROL
            DropdownButtonFormField<String>(
              value: rolSeleccionado,
              decoration: const InputDecoration(
                labelText: '¿Quién eres?',
                border: OutlineInputBorder(),
              ),
              items: ['Entrenador', 'Padre/Madre']
                  .map((r) => DropdownMenuItem(
                value: r,
                child: Text(r),
              ))
                  .toList(),
              onChanged: (val) =>
                  setState(() => rolSeleccionado = val!),
            ),

            const SizedBox(height: 30),


            ElevatedButton(
              onPressed: () {
                if (rolSeleccionado == 'Entrenador') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const LoginEntrenadorScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const CodigoPadreScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4B8A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "ENTRAR AL EQUIPO",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2.1 PANTALLA DE LOGIN 2 ---

class LoginEntrenadorScreen extends StatefulWidget {
  const LoginEntrenadorScreen({super.key});

  @override
  State<LoginEntrenadorScreen> createState() => _LoginEntrenadorScreenState();
}

class _LoginEntrenadorScreenState extends State<LoginEntrenadorScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool cargando = false;

  Future<void> login() async {
    setState(() => cargando = true);

    try {
      // Login con MI BASE DE DATOS - Firebase
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );

      String uid = cred.user!.uid;

      // 🔎 Leer rol desde Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("Usuario sin datos en Firestore");
      }

      String rol = userDoc['rol'];
      String equipoId = userDoc['equipoId'];

      if (rol != "entrenador") {
        throw Exception("No eres entrenador");
      }

      // Entrar a la app
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              esEntrenador: true,
              equipoId: equipoId,
            ),
          ),
              (route) => false,
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Entrenador")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Correo",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: cargando ? null : login,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("INICIAR SESIÓN"),
            ),
          ],
        ),
      ),
    );
  }
}


// --- 3. PANTALLA PRINCIPAL ---
class HomeScreen extends StatefulWidget {
  final bool esEntrenador;
  final String equipoId;

  const HomeScreen({
    super.key,
    required this.esEntrenador,
    required this.equipoId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 180,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo.png',
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) =>
          const Icon(Icons.sports_soccer, size: 80),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Text(
              "Panel de Control",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4B8A),
              ),
            ),
            const SizedBox(height: 40),

            // 🔵 CALENDARIO
            _menuBtn(
              Icons.calendar_today,
              "Calendario",
              const Color(0xFF1B4B8A),
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => CalendarScreen(
                    esEntrenador: widget.esEntrenador,
                    equipoId: widget.equipoId,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

// 🟡 TABLÓN
            _menuBtn(
              Icons.campaign,
              "Tablón de Avisos",
              const Color(0xFFD4AF37),
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => TablonScreen(
                    esEntrenador: widget.esEntrenador,
                    equipoId: widget.equipoId,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

// 🟢 ASISTENCIA
            _menuBtn(
              Icons.grid_on,
              "Asistencia Mensual",
              const Color(0xFF4CAF50),
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => AsistenciaCuadriculaScreen(
                    esEntrenador: widget.esEntrenador,
                    equipoId: widget.equipoId,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  Widget _menuBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      tileColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: Icon(icon, color: color, size: 30),
      title: Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 15),
    );
  }

//  5. CALENDARIO
class CalendarScreen extends StatefulWidget {
  final bool esEntrenador;
  final String equipoId;

  const CalendarScreen({
    super.key,
    required this.esEntrenador,
    required this.equipoId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _dia = DateTime.now();

  String _f(DateTime d) => "${d.day}-${d.month}-${d.year}";

  void _abrirEditor() {
    final TextEditingController act = TextEditingController();
    final TextEditingController hor = TextEditingController();
    final TextEditingController lug = TextEditingController();
    String dep = "⚽";

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          title: const Text("Planificar Día"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text("⚽ Fútbol"),
                      selected: dep == "⚽",
                      onSelected: (s) => setS(() => dep = "⚽"),
                    ),
                    ChoiceChip(
                      label: const Text("🏀 Basket"),
                      selected: dep == "🏀",
                      onSelected: (s) => setS(() => dep = "🏀"),
                    ),
                  ],
                ),
                TextField(
                  controller: act,
                  decoration: const InputDecoration(labelText: "Actividad"),
                ),
                TextField(
                  controller: hor,
                  decoration: const InputDecoration(
                    labelText: "Hora (⏰)",
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
                TextField(
                  controller: lug,
                  decoration: const InputDecoration(
                    labelText: "Lugar (📍)",
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('equipos')
                    .doc(widget.equipoId)
                    .collection('eventos')
                    .doc(_f(_dia))
                    .set({
                  'actividad': act.text,
                  'hora': hor.text,
                  'direccion': lug.text,
                  'deporte': dep,
                });

                print("EVENTO GUARDADO");

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calendario")),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _dia,
            firstDate: DateTime(2024),
            lastDate: DateTime(2030),
            onDateChanged: (n) => setState(() => _dia = n),
          ),
          const Divider(),

          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipos')
                  .doc(widget.equipoId)
                  .collection('eventos')
                  .doc(_f(_dia))
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error cargando datos"));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text("No hay eventos para este día"),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF1B4B8A),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${data['deporte'] ?? '⚽'} ${data['actividad'] ?? ''}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.esEntrenador)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    snapshot.data!.reference.delete(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text("Hora: ${data['hora'] ?? ''}"),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text("Lugar: ${data['direccion'] ?? ''}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (widget.esEntrenador)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _abrirEditor,
                icon: const Icon(Icons.add),
                label: const Text("Planificar"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

//  6. TABLÓN DE AVISOS
class TablonScreen extends StatefulWidget {
  final bool esEntrenador;
  final String equipoId;

  const TablonScreen({
    super.key,
    required this.esEntrenador,
    required this.equipoId,
  });

  @override
  State<TablonScreen> createState() => _TablonScreenState();
}

class _TablonScreenState extends State<TablonScreen> {
  final TextEditingController _avisoController = TextEditingController();

  void _nuevoAviso() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Escribir Nota en el Tablón"),
        content: TextField(
          controller: _avisoController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Escribe el aviso aquí...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_avisoController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('equipos')
                    .doc(widget.equipoId)
                    .collection('avisos')
                    .add({
                  'mensaje': _avisoController.text,
                  'fecha': FieldValue.serverTimestamp(),
                });

                print("AVISO GUARDADO");

                _avisoController.clear();

                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Pinchar Nota"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8D6E63),
      appBar: AppBar(
        title: const Text("Tablón de Avisos"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: widget.esEntrenador
          ? FloatingActionButton(
        backgroundColor: Colors.yellowAccent,
        onPressed: _nuevoAviso,
        child: const Icon(Icons.edit_note, size: 35, color: Colors.black),
      )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipos')
            .doc(widget.equipoId)
            .collection('avisos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          // ⏳ Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error
          if (snapshot.hasError) {
            return const Center(child: Text("Error cargando avisos"));
          }

          // 📭 Sin datos
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay avisos todavía"));
          }

          var avisos = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: avisos.length,
            itemBuilder: (context, index) {
              var a = avisos[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade200,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    )
                  ],
                  border: Border.all(color: Colors.yellow.shade400),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.push_pin, color: Colors.red, size: 20),
                    Expanded(
                      child: Center(
                        child: Text(
                          a['mensaje'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (widget.esEntrenador)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.brown, size: 18),
                          onPressed: () => a.reference.delete(),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//  7. ASISTENCIA CUADRÍCULA
class AsistenciaCuadriculaScreen extends StatefulWidget {
  final bool esEntrenador;
  final String equipoId;

  const AsistenciaCuadriculaScreen({
    super.key,
    required this.esEntrenador,
    required this.equipoId,
  });

  @override
  State<AsistenciaCuadriculaScreen> createState() =>
      _AsistenciaCuadriculaScreenState();
}

class _AsistenciaCuadriculaScreenState
    extends State<AsistenciaCuadriculaScreen> {

  final int totalDias = 16;

  // PARA AÑADIR UN JUGADOR
  void _agregarJugador() {
    TextEditingController t = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Nuevo Jugador"),
        content: TextField(
          controller: t,
          decoration: const InputDecoration(hintText: "Nombre"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (t.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('equipos')
                    .doc(widget.equipoId)
                    .collection('jugadores')
                    .add({'nombre': t.text});

                Navigator.pop(context);
              }
            },
            child: const Text("Añadir"),
          )
        ],
      ),
    );
  }

  // PARA EDITAR NOMBRE DEL DÍA
  void _editarNombreDia(int index, String actual, Map nombresDias) {
    if (!widget.esEntrenador) return;

    TextEditingController t = TextEditingController(text: actual);

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("Día ${index + 1}"),
        content: TextField(
          controller: t,
          decoration: const InputDecoration(hintText: "Ej: Lun 10"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              nombresDias[index.toString()] = t.text;

              await FirebaseFirestore.instance
                  .collection('equipos')
                  .doc(widget.equipoId)
                  .collection('config')
                  .doc('asistencia_nombres')
                  .set({
                'dias': nombresDias,
              }, SetOptions(merge: true));

              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Asistencia"),
        actions: [
          if (widget.esEntrenador)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _agregarJugador,
            )
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipos')
            .doc(widget.equipoId)
            .collection('jugadores')
            .orderBy('nombre')
            .snapshots(),
        builder: (context, snapJug) {

          if (!snapJug.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var jugadores = snapJug.data!.docs;


          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('equipos')
                .doc(widget.equipoId)
                .collection('config')
                .doc('asistencia_nombres')
                .snapshots(),
            builder: (context, snapNom) {

              var nombresDias =
                  (snapNom.data?.data() as Map?)?['dias'] ?? {};


              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('equipos')
                    .doc(widget.equipoId)
                    .collection('asistencia_diaria')
                    .doc('mes_actual')
                    .snapshots(),
                builder: (context, snapAsis) {

                  var datos = (snapAsis.data?.data() as Map?) ?? {};

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 10,
                      columns: [
                        const DataColumn(label: Text("Jugador")),


                        ...List.generate(
                          totalDias,
                              (i) => DataColumn(
                            label: InkWell(
                              onTap: () => _editarNombreDia(
                                i,
                                nombresDias[i.toString()] ?? "D${i + 1}",
                                nombresDias,
                              ),
                              child: Text(
                                nombresDias[i.toString()] ?? "D${i + 1}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      rows: jugadores.map((jugador) {

                        String jId = jugador.id;

                        return DataRow(
                          cells: [
                            DataCell(Text(jugador['nombre'])),

                            ...List.generate(totalDias, (d) {

                              String key = "${jId}_$d";
                              int estado = datos[key] ?? 0;

                              Color color;
                              IconData? icon;

                              if (estado == 1) {
                                color = Colors.green;
                                icon = Icons.check;
                              } else if (estado == 2) {
                                color = Colors.red;
                                icon = Icons.close;
                              } else {
                                color = Colors.grey.shade300;
                                icon = null;
                              }

                              return DataCell(
                                GestureDetector(
                                  onTap: widget.esEntrenador
                                      ? () async {
                                    int nuevo = (estado + 1) % 3;

                                    await FirebaseFirestore.instance
                                        .collection('equipos')
                                        .doc(widget.equipoId)
                                        .collection('asistencia_diaria')
                                        .doc('mes_actual')
                                        .set(
                                      {key: nuevo},
                                      SetOptions(merge: true),
                                    );
                                  }
                                      : null,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: icon != null
                                        ? Icon(icon,
                                        size: 14,
                                        color: Colors.white)
                                        : null,
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- 8. CODIGO PADRE/MADRE ---

class CodigoPadreScreen extends StatefulWidget {
  const CodigoPadreScreen({super.key});

  @override
  State<CodigoPadreScreen> createState() => _CodigoPadreScreenState();
}

class _CodigoPadreScreenState extends State<CodigoPadreScreen> {

  final TextEditingController codigoController = TextEditingController();
  bool cargando = false;

  Future<void> validarCodigo() async {
    setState(() => cargando = true);

    try {
      var query = await FirebaseFirestore.instance
          .collection('equipos')
          .where('codigo', isEqualTo: codigoController.text.trim())
          .get();

      if (query.docs.isEmpty) {
        throw Exception("Código incorrecto");
      }
      String equipoId = query.docs.first.id;

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              esEntrenador: false,
              equipoId: equipoId,
            ),
          ),
              (route) => false,
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Código del Equipo")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              controller: codigoController,
              decoration: const InputDecoration(
                labelText: "Introduce el código",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: cargando ? null : validarCodigo,
              child: cargando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ENTRAR"),
            ),
          ],
        ),
      ),
    );
  }
}