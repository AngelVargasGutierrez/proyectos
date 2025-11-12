import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/administrador.dart';

class ServicioAutenticacion {
  static final ServicioAutenticacion _instancia = ServicioAutenticacion._interno();
  factory ServicioAutenticacion() => _instancia;
  ServicioAutenticacion._interno();

  Administrador? _administradorActual;

  bool get estaAutenticado => _administradorActual != null;
  Administrador? get administradorActual => _administradorActual;

  Future<bool> iniciarSesion({required String correo, required String contrasena}) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );

      final uid = cred.user?.uid;
      if (uid == null) return false;

      // Intentar cargar como administrador
      final adminDoc = await FirebaseFirestore.instance.collection('administradores').doc(uid).get();
      if (adminDoc.exists) {
        final data = adminDoc.data() ?? <String, dynamic>{};
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: (data['correo'] ?? correo.trim()) as String,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.administrador,
        );
        return true;
      }

      // Intentar cargar como jurado (soporta 'jurados' y 'jurado' y búsqueda por correo)
      // 1) Por UID en 'jurados'
      final juradoDocUid = await FirebaseFirestore.instance.collection('jurados').doc(uid).get();
      if (juradoDocUid.exists) {
        final data = juradoDocUid.data() ?? <String, dynamic>{};
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? data['nombre'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: (data['correo'] ?? correo.trim()) as String,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.jurado,
        );
        return true;
      }

      // 2) Por UID en 'jurado' (singular)
      final juradoDocUidSing = await FirebaseFirestore.instance.collection('jurado').doc(uid).get();
      if (juradoDocUidSing.exists) {
        final data = juradoDocUidSing.data() ?? <String, dynamic>{};
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? data['nombre'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: (data['correo'] ?? correo.trim()) as String,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.jurado,
        );
        return true;
      }

      // 3) Por correo en 'jurado' (singular)
      final qsJuradoSing = await FirebaseFirestore.instance
          .collection('jurado')
          .where('correo', isEqualTo: correo.trim())
          .limit(1)
          .get();
      if (qsJuradoSing.docs.isNotEmpty) {
        final data = qsJuradoSing.docs.first.data();
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? data['nombre'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: (data['correo'] ?? correo.trim()) as String,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.jurado,
        );
        return true;
      }

      // 4) Por correo en 'jurados' (plural)
      final qsJurado = await FirebaseFirestore.instance
          .collection('jurados')
          .where('correo', isEqualTo: correo.trim())
          .limit(1)
          .get();
      if (qsJurado.docs.isNotEmpty) {
        final data = qsJurado.docs.first.data();
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? data['nombre'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: (data['correo'] ?? correo.trim()) as String,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.jurado,
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registrarAdministrador({
    required String nombres,
    required String apellidos,
    required String correo,
    required String numeroTelefonico,
    required String contrasena,
  }) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
      final uid = cred.user?.uid;
      if (uid == null) return false;

      await FirebaseFirestore.instance.collection('administradores').doc(uid).set({
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'correo': correo.trim(),
        'numeroTelefonico': numeroTelefonico.trim(),
        'rol': 'administrador',
      });

      _administradorActual = Administrador(
        id: uid,
        nombres: nombres.trim(),
        apellidos: apellidos.trim(),
        correo: correo.trim(),
        numeroTelefonico: numeroTelefonico.trim(),
        rol: RolUsuario.administrador,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registrarJurado({
    required String nombres,
    required String apellidos,
    required String correo,
    required String numeroTelefonico,
    required String contrasena,
  }) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
      final uid = cred.user?.uid;
      if (uid == null) return false;

      final payload = {
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'correo': correo.trim(),
        'numeroTelefonico': numeroTelefonico.trim(),
        'rol': 'jurado',
      };
      // Guardar en ambas colecciones para compatibilidad
      await FirebaseFirestore.instance.collection('jurados').doc(uid).set(payload);
      await FirebaseFirestore.instance.collection('jurado').doc(uid).set(payload);
      return true;
    } catch (e) {
      return false;
    }
  }

  void cerrarSesion() {
    _administradorActual = null;
    FirebaseAuth.instance.signOut();
  }
}