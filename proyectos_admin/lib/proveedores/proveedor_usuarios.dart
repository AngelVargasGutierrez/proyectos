import 'package:flutter/foundation.dart';
import '../modelos/administrador.dart';
import '../servicios/servicio_usuarios.dart';

class ProveedorUsuarios extends ChangeNotifier {
  final ServicioUsuarios _servicioUsuarios = ServicioUsuarios();

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  String? _mensajeExito;
  String? get mensajeExito => _mensajeExito;

  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> get usuarios => _usuarios;

  Future<bool> crearUsuario({
    required String nombres,
    required String apellidos,
    required String correo,
    required String numeroTelefonico,
    required RolUsuario rol,
  }) async {
    _cargando = true;
    _mensajeError = null;
    _mensajeExito = null;
    notifyListeners();

    try {
      final exito = await _servicioUsuarios.crearUsuarioMicrosoft(
        nombres: nombres,
        apellidos: apellidos,
        correo: correo,
        numeroTelefonico: numeroTelefonico,
        rol: rol,
      );

      if (exito) {
        _mensajeExito = 'Usuario creado exitosamente';
        await cargarUsuarios(); // Recargar la lista
      } else {
        _mensajeError = 'El correo ya está registrado';
      }

      _cargando = false;
      notifyListeners();
      return exito;
    } catch (e) {
      _mensajeError = 'Error al crear usuario: $e';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarUsuarios() async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      _usuarios = await _servicioUsuarios.obtenerTodosLosUsuarios();
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _mensajeError = 'Error al cargar usuarios';
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarUsuario(String correo, String rol) async {
    _cargando = true;
    _mensajeError = null;
    _mensajeExito = null;
    notifyListeners();

    try {
      final rolUsuario = rol.toLowerCase() == 'jurado' 
          ? RolUsuario.jurado 
          : RolUsuario.administrador;

      final exito = await _servicioUsuarios.eliminarUsuario(correo, rolUsuario);

      if (exito) {
        _mensajeExito = 'Usuario eliminado exitosamente';
        await cargarUsuarios(); // Recargar la lista
      } else {
        _mensajeError = 'Error al eliminar usuario';
      }

      _cargando = false;
      notifyListeners();
      return exito;
    } catch (e) {
      _mensajeError = 'Error al eliminar usuario: $e';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  void limpiarMensajes() {
    _mensajeError = null;
    _mensajeExito = null;
    notifyListeners();
  }
}
