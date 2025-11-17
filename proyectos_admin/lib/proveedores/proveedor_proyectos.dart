import 'package:flutter/foundation.dart';
import '../modelos/proyecto.dart';
import '../servicios/servicio_proyectos.dart';
import '../servicios/servicio_onedrive.dart';
import '../config/onedrive_config.dart';

class ProveedorProyectos extends ChangeNotifier {
  final ServicioProyectos _servicioProyectos = ServicioProyectos();

  List<Proyecto> _proyectos = [];
  List<Proyecto> get proyectos => List.unmodifiable(_proyectos);

  Map<EstadoProyecto, int> _estadisticas = {};
  Map<EstadoProyecto, int> get estadisticas => Map.unmodifiable(_estadisticas);

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _mensajeError;
  String? get mensajeError => _mensajeError;

  String? _concursoActual;
  String? get concursoActual => _concursoActual;

  Future<void> cargarProyectosPorConcurso(String concursoId) async {
    _cargando = true;
    _mensajeError = null;
    _concursoActual = concursoId;
    notifyListeners();

    try {
      _proyectos = await _servicioProyectos.obtenerProyectosPorConcurso(
        concursoId,
      );
      _estadisticas = _calcularEstadisticas(_proyectos);
      await _servicioProyectos.sincronizarProyectosLocal(_proyectos);
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _mensajeError = 'Error al cargar los proyectos';
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarProyectosPorCategoria(
    String concursoId,
    String categoria,
  ) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      _proyectos = await _servicioProyectos.obtenerProyectosPorCategoria(
        concursoId,
        categoria,
      );
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _mensajeError = 'Error al cargar los proyectos de la categoria';
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarEstadoProyecto(
    String proyectoId,
    EstadoProyecto nuevoEstado, {
    String? comentarios,
    double? puntuacion,
  }) async {
    try {
      final exito = await _servicioProyectos.actualizarEstadoProyecto(
        proyectoId: proyectoId,
        concursoId: _concursoActual,
        nuevoEstado: _estadoDb(nuevoEstado),
        comentarios: comentarios,
        puntuacion: puntuacion,
      );

      if (exito && _concursoActual != null) {
        // Recargar proyectos para mostrar cambios
        await cargarProyectosPorConcurso(_concursoActual!);
      }

      return exito;
    } catch (e) {
      _mensajeError = 'Error al actualizar el estado';
      notifyListeners();
      return false;
    }
  }

  Future<bool> enviarEvaluacionJurado({
    required String concursoId,
    required String proyectoId,
    required String categoriaId,
    required String juradoUid,
    required Map<String, int> criterios,
  }) async {
    try {
      final exito = await _servicioProyectos.enviarEvaluacionJurado(
        concursoId: concursoId,
        proyectoId: proyectoId,
        categoriaId: categoriaId,
        juradoUid: juradoUid,
        criterios: criterios,
      );
      if (exito) {
        // Recargar lista dentro del concurso para reflejar cambios de puntuación/ganador
        if (_concursoActual != null) {
          await cargarProyectosPorConcurso(_concursoActual!);
        } else {
          await cargarProyectosPorConcurso(concursoId);
        }
      }
      return exito;
    } catch (e) {
      _mensajeError = 'Error al enviar evaluación del jurado';
      notifyListeners();
      return false;
    }
  }

  List<Proyecto> filtrarPorEstado(EstadoProyecto estado) {
    return _proyectos.where((proyecto) => proyecto.estado == estado).toList();
  }

  List<Proyecto> filtrarPorCategoria(String categoria) {
    return _proyectos
        .where((proyecto) => proyecto.categoriaId == categoria)
        .toList();
  }

  void limpiarError() {
    _mensajeError = null;
    notifyListeners();
  }

  void limpiar() {
    _proyectos.clear();
    _estadisticas.clear();
    _concursoActual = null;
    _mensajeError = null;
    _cargando = false;
    notifyListeners();
  }

  Future<bool> subirZipYActualizarProyecto({
    required String concursoId,
    required String proyectoId,
    required String filePath,
  }) async {
    _cargando = true;
    notifyListeners();
    try {
      final url = await _servicioProyectos.subirZipDeProyecto(
        concursoId: concursoId,
        proyectoId: proyectoId,
        filePath: filePath,
      );
      if (url == null) {
        _cargando = false;
        notifyListeners();
        return false;
      }
      final ok = await _servicioProyectos.actualizarZipUrlProyecto(
        proyectoId: proyectoId,
        zipUrl: url,
      );
      if (ok) {
        if (_concursoActual != null) {
          await cargarProyectosPorConcurso(_concursoActual!);
        }
        try {
          final p = _proyectos.firstWhere((e) => e.id == proyectoId);
          await _servicioProyectos.sincronizarProyectoLocal(p);
          await ServicioOneDrive().inicializar(
            clientId: onedriveClientId,
            authority: onedriveAuthority,
            redirectUri: onedriveRedirectUriAndroid,
          );
          await ServicioOneDrive().sincronizarProyectoOneDrive(
            p,
            localZipPath: filePath,
          );
        } catch (_) {}
      }
      _cargando = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _cargando = false;
      _mensajeError = 'Error al subir el ZIP';
      notifyListeners();
      return false;
    }
  }

  Map<EstadoProyecto, int> _calcularEstadisticas(List<Proyecto> lista) {
    final mapa = <EstadoProyecto, int>{
      EstadoProyecto.enviado: 0,
      EstadoProyecto.enRevision: 0,
      EstadoProyecto.aprobado: 0,
      EstadoProyecto.rechazado: 0,
      EstadoProyecto.ganador: 0,
    };
    for (final p in lista) {
      mapa[p.estado] = (mapa[p.estado] ?? 0) + 1;
    }
    return mapa;
  }

  String _estadoDb(EstadoProyecto e) {
    switch (e) {
      case EstadoProyecto.enviado:
        return 'enviado';
      case EstadoProyecto.enRevision:
        return 'en_revision';
      case EstadoProyecto.aprobado:
        return 'aprobado';
      case EstadoProyecto.rechazado:
        return 'rechazado';
      case EstadoProyecto.ganador:
        return 'ganador';
    }
  }
}
