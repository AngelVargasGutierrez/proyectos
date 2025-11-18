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
        final metodo = data['metodoAutenticacion'] ?? 'email';
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: (data['correo'] ?? correo.trim()) as String,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.administrador,
          metodoAutenticacion: metodo == 'microsoft' ? MetodoAutenticacion.microsoft : MetodoAutenticacion.email,
        );
        return true;
      }

      // Intentar cargar como jurado
      // 1) Por UID en 'jurados'
      final juradoDocUid = await FirebaseFirestore.instance.collection('jurados').doc(uid).get();
      if (juradoDocUid.exists) {
        final data = juradoDocUid.data() ?? <String, dynamic>{};
        final metodo = data['metodoAutenticacion'] ?? 'email';
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? data['nombre'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: (data['correo'] ?? correo.trim()) as String,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.jurado,
          metodoAutenticacion: metodo == 'microsoft' ? MetodoAutenticacion.microsoft : MetodoAutenticacion.email,
        );
        return true;
      }

      // 2) Por correo en 'jurados'
      final qsJurado = await FirebaseFirestore.instance
          .collection('jurados')
          .where('correo', isEqualTo: correo.trim())
          .limit(1)
          .get();
      if (qsJurado.docs.isNotEmpty) {
        final data = qsJurado.docs.first.data();
        final metodo = data['metodoAutenticacion'] ?? 'email';
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? data['nombre'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: (data['correo'] ?? correo.trim()) as String,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.jurado,
          metodoAutenticacion: metodo == 'microsoft' ? MetodoAutenticacion.microsoft : MetodoAutenticacion.email,
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
        'metodoAutenticacion': 'email',
      });

      _administradorActual = Administrador(
        id: uid,
        nombres: nombres.trim(),
        apellidos: apellidos.trim(),
        correo: correo.trim(),
        numeroTelefonico: numeroTelefonico.trim(),
        rol: RolUsuario.administrador,
        metodoAutenticacion: MetodoAutenticacion.email,
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
        'metodoAutenticacion': 'email',
      };
      // Guardar solo en colección 'jurados' unificada
      await FirebaseFirestore.instance.collection('jurados').doc(uid).set(payload);
      return true;
    } catch (e) {
      return false;
    }
  }

  void cerrarSesion() {
    _administradorActual = null;
    FirebaseAuth.instance.signOut();
  }

  Future<bool> iniciarSesionConMicrosoft() async {
    try {
      // Configurar Microsoft Provider
      final microsoftProvider = MicrosoftAuthProvider();
      microsoftProvider.setCustomParameters({
        'tenant': 'common', // Permite cuentas personales y organizacionales
      });

      // Iniciar flujo de autenticación con Microsoft
      final userCred = await FirebaseAuth.instance.signInWithProvider(microsoftProvider);
      final uid = userCred.user?.uid;
      final correo = userCred.user?.email;
      if (uid == null || correo == null) return false;

      // Verificar si el correo está en la lista de usuarios permitidos
      // Buscar en administradores
      final adminDoc = await FirebaseFirestore.instance.collection('administradores').doc(uid).get();
      if (adminDoc.exists) {
        final data = adminDoc.data() ?? <String, dynamic>{};
        // Verificar que el método de autenticación sea Microsoft
        final metodo = data['metodoAutenticacion'] ?? '';
        if (metodo != 'microsoft') {
          await FirebaseAuth.instance.signOut();
          return false;
        }
        
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: correo,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.administrador,
          metodoAutenticacion: MetodoAutenticacion.microsoft,
        );
        return true;
      }

      // Buscar en colección de correos permitidos (administradores)
      final adminQuery = await FirebaseFirestore.instance
          .collection('administradores')
          .where('correo', isEqualTo: correo.trim())
          .where('metodoAutenticacion', isEqualTo: 'microsoft')
          .limit(1)
          .get();
      
      if (adminQuery.docs.isNotEmpty) {
        final data = adminQuery.docs.first.data();
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: correo,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.administrador,
          metodoAutenticacion: MetodoAutenticacion.microsoft,
        );
        return true;
      }

      // Buscar en jurados
      final juradoQuery = await FirebaseFirestore.instance
          .collection('jurados')
          .where('correo', isEqualTo: correo.trim())
          .where('metodoAutenticacion', isEqualTo: 'microsoft')
          .limit(1)
          .get();
      
      if (juradoQuery.docs.isNotEmpty) {
        final data = juradoQuery.docs.first.data();
        _administradorActual = Administrador(
          id: uid,
          nombres: (data['nombres'] ?? data['nombre'] ?? '') as String,
          apellidos: (data['apellidos'] ?? '') as String,
          correo: correo,
          numeroTelefonico: (data['numeroTelefonico'] ?? '') as String,
          rol: RolUsuario.jurado,
          metodoAutenticacion: MetodoAutenticacion.microsoft,
        );
        return true;
      }

      // Si no está en ninguna lista, rechazar acceso
      await FirebaseAuth.instance.signOut();
      return false;
    } catch (e) {
      return false;
    }
  }
}