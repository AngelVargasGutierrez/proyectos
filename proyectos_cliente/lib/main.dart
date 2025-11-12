import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'servicios/servicio_autenticacion.dart';
import 'pantallas/pantalla_inicio_sesion.dart';
import 'pantallas/pantalla_dashboard.dart';
import 'utilidades/estilos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AplicacionProyectosEPIS());
}

class AplicacionProyectosEPIS extends StatelessWidget {
  const AplicacionProyectosEPIS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Concurso de Proyectos EPIS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colores.primario,
        scaffoldBackgroundColor: Colores.fondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colores.primario,
          foregroundColor: Colores.blanco,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colores.primario,
            foregroundColor: Colores.blanco,
            shape: RoundedRectangleBorder(
              borderRadius: Estilos.bordeRedondeado,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: Estilos.bordeRedondeado,
          ),
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: Estilos.bordeRedondeado,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: Estilos.bordeRedondeado,
            borderSide: const BorderSide(color: Colores.primario),
          ),
        ),
      ),
      home: const PantallaSplash(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});

  @override
  State<PantallaSplash> createState() => _PantallaSplashState();
}

class _PantallaSplashState extends State<PantallaSplash> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    // Simular carga inicial
    await Future.delayed(const Duration(seconds: 2));
    
    // Verificar si hay una sesion guardada
    await ServicioAutenticacion.instancia.verificarSesionGuardada();
    
    if (mounted) {
      final estaAutenticado = ServicioAutenticacion.instancia.estaAutenticado;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => estaAutenticado
              ? const PantallaDashboard()
              : const PantallaInicioSesion(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.primario,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colores.blanco,
                borderRadius: Estilos.bordeRedondeadoGrande,
              ),
              child: const Icon(
                Icons.school,
                size: 80,
                color: Colores.primario,
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Concurso de Proyectos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colores.blanco,
              ),
            ),
            const Text(
              'EPIS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colores.blanco,
              ),
            ),
            const SizedBox(height: 48),
            
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colores.blanco),
            ),
          ],
        ),
      ),
    );
  }
}
