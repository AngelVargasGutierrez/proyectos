import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Elimina un usuario de Firestore
  Future<bool> eliminarUsuario(String correo, RolUsuario rol) async {
    try {
      final docId = correo.trim().replaceAll('@', '_at_').replaceAll('.', '_dot_');
      final coleccion = rol == RolUsuario.administrador ? 'administradores' : 'jurados';
      
      await FirebaseFirestore.instance.collection(coleccion).doc(docId).delete();

      return true;
    } catch (e) {
      return false;
    }
  }
}
