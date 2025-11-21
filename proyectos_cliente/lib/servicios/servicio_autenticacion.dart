import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/estudiante.dart';


class ServicioAutenticacion {
  static ServicioAutenticacion? _instancia;
  static ServicioAutenticacion get instancia {
    _instancia ??= ServicioAutenticacion._();
    return _instancia!;
  }

  ServicioAutenticacion._();

  Estudiante? _estudianteActual;
  Estudiante? get estudianteActual => _estudianteActual;

  bool get estaAutenticado => _estudianteActual != null;

  Future<bool> registrarEstudiante({
    required String nombres,
    required String apellidos,
    required String codigoUniversitario,
    required String correo,
    required String numeroTelefonico,
    required int ciclo,
    required String contrasena,
  }) async {
    try {
      final correoNorm = correo.trim().toLowerCase();
      const allowedDomains = ['@upt.pe', '@gmail.com'];
      final permitido = allowedDomains.any((d) => correoNorm.endsWith(d));
      if (!permitido) return false;
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correoNorm,
        password: contrasena,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .set({
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          'codigo_universitario': codigoUniversitario.trim(),
          'correo': correoNorm,
          'numero_telefono': numeroTelefonico.trim(),
          'ciclo': ciclo,
        }, SetOptions(merge: true));
        _estudianteActual = Estudiante(
          id: uid,
          nombres: nombres.trim(),
          apellidos: apellidos.trim(),
          codigoUniversitario: codigoUniversitario.trim(),
          correo: correoNorm,
          numeroTelefonico: numeroTelefonico.trim(),
          ciclo: ciclo,
        );
        await _guardarSesion();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al registrar estudiante (Firebase): $e');
      return false;
    }
  }

  Future<bool> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final correoNorm = correo.trim().toLowerCase();
      const allowedDomains = ['@upt.pe', '@gmail.com'];
      final permitido = allowedDomains.any((d) => correoNorm.endsWith(d));
      if (!permitido) return false;
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correoNorm,
        password: contrasena,
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final ref = FirebaseFirestore.instance.collection('usuarios').doc(uid);
      final snap = await ref.get();
      if (snap.exists) {
        final data = snap.data() ?? <String, dynamic>{};
        _estudianteActual = Estudiante(
          id: uid,
          nombres: (data['nombres'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          codigoUniversitario: (data['codigo_universitario'] ?? '') as String,
          correo: (data['correo'] ?? correoNorm) as String,
          numeroTelefonico: (data['numero_telefono'] ?? '') as String,
          ciclo: (data['ciclo'] ?? 0) as int,
        );
        await _guardarSesion();
        return true;
      }

      await ref.set({
        'nombres': '',
        'apellidos': '',
        'codigo_universitario': '',
        'correo': correoNorm,
        'numero_telefono': '',
        'ciclo': 0,
      }, SetOptions(merge: true));
      _estudianteActual = Estudiante(
        id: uid,
        nombres: '',
        apellidos: '',
        codigoUniversitario: '',
        correo: correoNorm,
        numeroTelefonico: '',
        ciclo: 0,
      );
      await _guardarSesion();
      return true;
    } catch (e) {
      print('Error al iniciar sesion (Firebase/Firestore): $e');
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    _estudianteActual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sesion_estudiante');
    await FirebaseAuth.instance.signOut();
  }

  Future<void> verificarSesionGuardada() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final datosEstudiante = prefs.getString('sesion_estudiante');
      if (datosEstudiante != null) {
        final json = jsonDecode(datosEstudiante);
        _estudianteActual = Estudiante.desdeJson(json);
      }
    } catch (e) {
      print('Error al verificar sesion guardada: $e');
    }
  }

  Future<void> _guardarSesion() async {
    if (_estudianteActual != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sesion_estudiante', jsonEncode(_estudianteActual!.aJson()));
    }
  }
}