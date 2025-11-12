class Proyecto {
  final String id;
  final String nombre;
  final String linkGithub;
  final String archivoZip; // URL o path del archivo ZIP
  final String estudianteId;
  final String nombreEstudiante;
  final String correoEstudiante;
  final String concursoId;
  final String categoriaId;
  final DateTime fechaEnvio;
  final EstadoProyecto estado;
  final String? comentarios;
  final double? puntuacion;

  Proyecto({
    required this.id,
    required this.nombre,
    required this.linkGithub,
    required this.archivoZip,
    required this.estudianteId,
    required this.nombreEstudiante,
    required this.correoEstudiante,
    required this.concursoId,
    required this.categoriaId,
    required this.fechaEnvio,
    required this.estado,
    this.comentarios,
    this.puntuacion,
  });

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'nombre': nombre,
      'linkGithub': linkGithub,
      'archivoZip': archivoZip,
      'estudianteId': estudianteId,
      'nombreEstudiante': nombreEstudiante,
      'correoEstudiante': correoEstudiante,
      'concursoId': concursoId,
      'categoriaId': categoriaId,
      'fechaEnvio': fechaEnvio.millisecondsSinceEpoch,
      'estado': estado.name,
      'comentarios': comentarios,
      'puntuacion': puntuacion,
    };
  }

  static Proyecto desdeJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'],
      nombre: json['nombre'],
      linkGithub: json['linkGithub'],
      archivoZip: json['archivoZip'],
      estudianteId: json['estudianteId'],
      nombreEstudiante: json['nombreEstudiante'],
      correoEstudiante: json['correoEstudiante'],
      concursoId: json['concursoId'],
      categoriaId: json['categoriaId'],
      fechaEnvio: DateTime.fromMillisecondsSinceEpoch(json['fechaEnvio']),
      estado: EstadoProyecto.values.byName(json['estado']),
      comentarios: json['comentarios'],
      puntuacion: json['puntuacion']?.toDouble(),
    );
  }

  String get estadoTexto {
    switch (estado) {
      case EstadoProyecto.enviado:
        return 'Enviado';
      case EstadoProyecto.enRevision:
        return 'En Revision';
      case EstadoProyecto.aprobado:
        return 'Aprobado';
      case EstadoProyecto.rechazado:
        return 'Rechazado';
      case EstadoProyecto.ganador:
        return 'Ganador';
    }
  }
}

enum EstadoProyecto {
  enviado,
  enRevision,
  aprobado,
  rechazado,
  ganador,
}