import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modelos/administrador.dart';

class ServicioUsuarios {
  static final ServicioUsuarios _instancia = ServicioUsuarios._interno();
  factory ServicioUsuarios() => _instancia;
  ServicioUsuarios._interno();

  /// Crea un usuario (administrador o jurado) que solo puede iniciar sesión con Microsoft
  /// No crea la cuenta en Firebase Auth, solo guarda los datos en Firestore
  Future<bool> crearUsuarioMicrosoft({
    required String nombres,
    required String apellidos,
    required String correo,
    required String numeroTelefonico,
    required RolUsuario rol,
  }) async {
    try {
      // Verificar si el correo ya existe
      final existe = await _verificarCorreoExistente(correo.trim());
      if (existe) {
        return false;
      }

      // Preparar datos del usuario
      final datos = {
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'correo': correo.trim(),
        'numeroTelefonico': numeroTelefonico.trim(),
        'rol': rol.name,
        'metodoAutenticacion': 'microsoft',
        'fechaCreacion': FieldValue.serverTimestamp(),
      };

      // Guardar en la colección correspondiente
      final coleccion = rol == RolUsuario.administrador ? 'administradores' : 'jurados';
      
      // Usar el correo como ID del documento para facilitar búsquedas
      final docId = correo.trim().replaceAll('@', '_at_').replaceAll('.', '_dot_');
      await FirebaseFirestore.instance.collection(coleccion).doc(docId).set(datos);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Crea un usuario (administrador o jurado) con correo y contraseña
  /// Crea la cuenta en Firebase Auth y guarda los datos en Firestore
  Future<bool> crearUsuarioCorreo({
    required String nombres,
    required String apellidos,
    required String correo,
    required String numeroTelefonico,
    required RolUsuario rol,
    required String contrasena,
  }) async {
    try {
      // Verificar si el correo ya existe en Firestore
      final existe = await _verificarCorreoExistente(correo.trim());
      if (existe) {
        return false;
      }

      // Crear usuario en Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );

      // Preparar datos del usuario
      final datos = {
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim(),
        'correo': correo.trim(),
        'numeroTelefonico': numeroTelefonico.trim(),
        'rol': rol.name,
        'metodoAutenticacion': 'correo',
        'uid': userCredential.user!.uid,
        'fechaCreacion': FieldValue.serverTimestamp(),
      };

      // Guardar en la colección correspondiente
      final coleccion = rol == RolUsuario.administrador ? 'administradores' : 'jurados';
      
      // Usar el UID como ID del documento (consistente con el método de registro)
      await FirebaseFirestore.instance.collection(coleccion).doc(userCredential.user!.uid).set(datos);

      // Cerrar sesión del usuario recién creado para que el admin no pierda su sesión
      await FirebaseAuth.instance.signOut();

      return true;
    } catch (e) {
      // Si falla al guardar en Firestore, intentar eliminar el usuario de Auth
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
        }
      } catch (_) {}
      return false;
    }
  }

  /// Verifica si un correo ya está registrado en alguna colección
  Future<bool> _verificarCorreoExistente(String correo) async {
    try {
      // Buscar en administradores
      final adminQuery = await FirebaseFirestore.instance
          .collection('administradores')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();
      
      if (adminQuery.docs.isNotEmpty) return true;

      // Buscar en jurados
      final juradosQuery = await FirebaseFirestore.instance
          .collection('jurados')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();
      
      if (juradosQuery.docs.isNotEmpty) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la lista de todos los usuarios (administradores y jurados)
  Future<List<Map<String, dynamic>>> obtenerTodosLosUsuarios() async {
    try {
      final List<Map<String, dynamic>> usuarios = [];

      // Obtener administradores
      final admins = await FirebaseFirestore.instance.collection('administradores').get();
      for (var doc in admins.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        usuarios.add(data);
      }

      // Obtener jurados
      final jurados = await FirebaseFirestore.instance.collection('jurados').get();
      for (var doc in jurados.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        usuarios.add(data);
      }

      return usuarios;
    } catch (e) {
      return [];
    }
  }

  /// Elimina un usuario de Firestore y Firebase Auth (si aplica)
  Future<bool> eliminarUsuario(String correo, RolUsuario rol) async {
    try {
      final coleccion = rol == RolUsuario.administrador ? 'administradores' : 'jurados';
      
      // Buscar el usuario por correo para obtener su ID y método de autenticación
      final query = await FirebaseFirestore.instance
          .collection(coleccion)
          .where('correo', isEqualTo: correo.trim())
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        // Si no se encuentra por query, intentar con el formato antiguo de ID
        final docId = correo.trim().replaceAll('@', '_at_').replaceAll('.', '_dot_');
        await FirebaseFirestore.instance.collection(coleccion).doc(docId).delete();
        return true;
      }

      // Obtener el documento del usuario
      final userDoc = query.docs.first;
      final userData = userDoc.data();
      final metodoAuth = userData['metodoAutenticacion'] as String?;
      final uid = userData['uid'] as String?;

      // Si es un usuario con autenticación por correo/contraseña, eliminarlo de Firebase Auth
      if (metodoAuth == 'correo' && uid != null) {
        try {
          // Nota: Para eliminar un usuario de Firebase Auth, necesitamos privilegios de administrador
          // o que el usuario esté actualmente autenticado. Como estamos en un contexto administrativo,
          // usaremos Cloud Functions o Admin SDK en producción.
          // Por ahora, solo eliminaremos de Firestore y el usuario quedará en Auth
          // (se recomienda implementar una Cloud Function para esto)
          
          // TODO: Implementar eliminación de Firebase Auth mediante Cloud Function
          // await FirebaseFunctions.instance.httpsCallable('eliminarUsuario').call({'uid': uid});
        } catch (e) {
          // Continuar con la eliminación de Firestore aunque falle Auth
        }
      }

      // Eliminar el documento de Firestore
      await FirebaseFirestore.instance.collection(coleccion).doc(userDoc.id).delete();

      return true;
    } catch (e) {
      return false;
    }
  }
}
