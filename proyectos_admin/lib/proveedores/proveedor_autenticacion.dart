import 'package:flutter/foundation.dart';
import '../modelos/administrador.dart';
import '../servicios/servicio_autenticacion.dart';

class ProveedorAutenticacion extends ChangeNotifier {
  final ServicioAutenticacion _servicioAuth = ServicioAutenticacion();

  Administrador? get administradorActual => _servicioAuth.administradorActual;
  bool get estaAutenticado => _servicioAuth.estaAutenticado;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  Future<bool> registrar({
    required String nombres,
    required String apellidos,
    required String correo,
    required String numeroTelefonico,
    required String contrasena,
  }) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final exito = await _servicioAuth.registrarAdministrador(
        nombres: nombres,
        apellidos: apellidos,
        correo: correo,
        numeroTelefonico: numeroTelefonico,
        contrasena: contrasena,
      );

      if (!exito) {
        _mensajeError = 'El correo ya esta registrado';
      }

      _cargando = false;
      notifyListeners();
      return exito;
    } catch (e) {
      _mensajeError = 'Error al registrar administrador';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final exito = await _servicioAuth.iniciarSesion(
        correo: correo,
        contrasena: contrasena,
      );

      if (!exito) {
        _mensajeError = 'Credenciales incorrectas';
      }

      _cargando = false;
      notifyListeners();
      return exito;
    } catch (e) {
      _mensajeError = 'Error al iniciar sesion';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  void cerrarSesion() {
    _servicioAuth.cerrarSesion();
    notifyListeners();
  }

  void limpiarError() {
    _mensajeError = null;
    notifyListeners();
  }
}