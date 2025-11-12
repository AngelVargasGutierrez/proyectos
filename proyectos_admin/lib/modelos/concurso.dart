import 'categoria.dart';

class Concurso {
  final String id;
  final String nombre;
  final List<Categoria> categorias;
  final DateTime fechaLimiteInscripcion;
  final DateTime fechaRevision;
  final DateTime fechaConfirmacionAceptados;
  final DateTime fechaCreacion;
  final String administradorId;

  Concurso({
    required this.id,
    required this.nombre,
    required this.categorias,
    required this.fechaLimiteInscripcion,
    required this.fechaRevision,
    required this.fechaConfirmacionAceptados,
    required this.fechaCreacion,
    required this.administradorId,
  });

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categorias': categorias.map((categoria) => categoria.aJson()).toList(),
      'fechaLimiteInscripcion': fechaLimiteInscripcion.millisecondsSinceEpoch,
      'fechaRevision': fechaRevision.millisecondsSinceEpoch,
      'fechaConfirmacionAceptados': fechaConfirmacionAceptados.millisecondsSinceEpoch,
      'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
      'administradorId': administradorId,
    };
  }

  static Concurso desdeJson(Map<String, dynamic> json) {
    return Concurso(
      id: json['id'],
      nombre: json['nombre'],
      categorias: (json['categorias'] as List)
          .map((categoria) => Categoria.desdeJson(categoria))
          .toList(),
      fechaLimiteInscripcion: DateTime.fromMillisecondsSinceEpoch(json['fechaLimiteInscripcion']),
      fechaRevision: DateTime.fromMillisecondsSinceEpoch(json['fechaRevision']),
      fechaConfirmacionAceptados: DateTime.fromMillisecondsSinceEpoch(json['fechaConfirmacionAceptados']),
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(json['fechaCreacion']),
      administradorId: json['administradorId'],
    );
  }

  bool get estaVigente {
    return DateTime.now().isBefore(fechaLimiteInscripcion);
  }

  String get estadoConcurso {
    final ahora = DateTime.now();
    if (ahora.isBefore(fechaLimiteInscripcion)) {
      return 'Inscripciones abiertas';
    } else if (ahora.isBefore(fechaRevision)) {
      return 'En proceso de revision';
    } else if (ahora.isBefore(fechaConfirmacionAceptados)) {
      return 'Revision completada';
    } else {
      return 'Finalizado';
    }
  }
}