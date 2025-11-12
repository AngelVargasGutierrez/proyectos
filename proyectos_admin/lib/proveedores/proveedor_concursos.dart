import 'package:flutter/foundation.dart';
import '../modelos/concurso.dart';
import '../modelos/categoria.dart';
import '../servicios/servicio_concursos.dart';
import '../servicios/servicio_autenticacion.dart';
import '../modelos/administrador.dart';

class ProveedorConcursos extends ChangeNotifier {
  final ServicioConcursos _servicioConcursos = ServicioConcursos();

  List<Concurso> _concursos = [];
  List<Concurso> get concursos => List.unmodifiable(_concursos);

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  Future<bool> crearConcurso({
    required String nombre,
    required List<Categoria> categorias,
    required DateTime fechaLimiteInscripcion,
    required DateTime fechaRevision,
    required DateTime fechaConfirmacionAceptados,
  }) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final exito = await _servicioConcursos.crearConcurso(
        nombre: nombre,
        categorias: categorias,
        fechaLimiteInscripcion: fechaLimiteInscripcion,
        fechaRevision: fechaRevision,
        fechaConfirmacionAceptados: fechaConfirmacionAceptados,
      );

      if (exito) {
        await cargarConcursos();
      } else {
        _mensajeError = 'Error al crear el concurso';
      }

      _cargando = false;
      notifyListeners();
      return exito;
    } catch (e) {
      _mensajeError = 'Error al crear el concurso';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarConcursos() async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      // Mostrar concursos según rol del usuario
      final admin = ServicioAutenticacion().administradorActual;
      if (admin != null && admin.rol == RolUsuario.jurado) {
        _concursos = await _servicioConcursos.obtenerConcursos();
      } else {
        _concursos = await _servicioConcursos.obtenerConcursosDelAdministrador();
      }
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _mensajeError = 'Error al cargar los concursos';
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarConcurso({
    required String concursoId,
    required String nombre,
    required List<Categoria> categorias,
    required DateTime fechaLimiteInscripcion,
    required DateTime fechaRevision,
    required DateTime fechaConfirmacionAceptados,
  }) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final exito = await _servicioConcursos.actualizarConcurso(
        concursoId: concursoId,
        nombre: nombre,
        categorias: categorias,
        fechaLimiteInscripcion: fechaLimiteInscripcion,
        fechaRevision: fechaRevision,
        fechaConfirmacionAceptados: fechaConfirmacionAceptados,
      );

      if (exito) {
        await cargarConcursos();
      } else {
        _mensajeError = 'Error al actualizar el concurso';
      }

      _cargando = false;
      notifyListeners();
      return exito;
    } catch (e) {
      _mensajeError = 'Error al actualizar el concurso';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarConcurso(String concursoId) async {
    try {
      final exito = await _servicioConcursos.eliminarConcurso(concursoId);
      
      if (exito) {
        await cargarConcursos();
      }
      
      return exito;
    } catch (e) {
      _mensajeError = 'Error al eliminar el concurso';
      notifyListeners();
      return false;
    }
  }

  void limpiarError() {
    _mensajeError = null;
    notifyListeners();
  }
}