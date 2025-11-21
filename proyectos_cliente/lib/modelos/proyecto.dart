enum EstadoProyecto {
  pendiente,
  aprobado,
  rechazado,
  apto,
  finalizado,
  ganador,
}

class Proyecto {
  final String id;
  final String nombre;
  final String estudianteId;
  final String concursoId;
  final String categoriaId;
  final String enlaceGithub;
  final String archivoZip;
  final EstadoProyecto estado;
  final DateTime fechaEnvio;
  final String? comentarioAdmin;
  final String? categoriaNombre;
  final String? onedriveUrl;

  Proyecto({
    required this.id,
    required this.nombre,
    required this.estudianteId,
    required this.concursoId,
    required this.categoriaId,
    required this.enlaceGithub,
    required this.archivoZip,
    required this.estado,
    required this.fechaEnvio,
    this.comentarioAdmin,
    this.categoriaNombre,
    this.onedriveUrl,
  });

  factory Proyecto.desdeJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      estudianteId: json['estudiante_id'] ?? '',
      concursoId: json['concurso_id'] ?? '',
      categoriaId: json['categoria_id'] ?? '',
      enlaceGithub: json['enlace_github'] ?? '',
      archivoZip: json['archivo_zip'] ?? '',
      estado: _estadoDesdeTexto(json['estado'] ?? 'pendiente'),
      fechaEnvio: DateTime.parse(json['fecha_envio'] ?? DateTime.now().toString()),
      comentarioAdmin: json['comentario_admin'],
      categoriaNombre: json['categoria_nombre'],
      onedriveUrl: json['onedrive_url'] ?? json['onedrive_folder'] ?? json['onedrive'],
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'nombre': nombre,
      'estudiante_id': estudianteId,
      'concurso_id': concursoId,
      'categoria_id': categoriaId,
      'enlace_github': enlaceGithub,
      'archivo_zip': archivoZip,
      'estado': _estadoATexto(estado),
      'fecha_envio': fechaEnvio.toIso8601String(),
      'comentario_admin': comentarioAdmin,
      'categoria_nombre': categoriaNombre,
      'onedrive_url': onedriveUrl,
    };
  }

  static EstadoProyecto _estadoDesdeTexto(String texto) {
    switch (texto.toLowerCase()) {
      case 'aprobado':
        return EstadoProyecto.aprobado;
      case 'rechazado':
        return EstadoProyecto.rechazado;
      case 'apto':
        return EstadoProyecto.apto;
      case 'finalizado':
        return EstadoProyecto.finalizado;
      case 'ganador':
        return EstadoProyecto.ganador;
      default:
        return EstadoProyecto.pendiente;
    }
  }

  static String _estadoATexto(EstadoProyecto estado) {
    switch (estado) {
      case EstadoProyecto.aprobado:
        return 'aprobado';
      case EstadoProyecto.rechazado:
        return 'rechazado';
      case EstadoProyecto.apto:
        return 'apto';
      case EstadoProyecto.finalizado:
        return 'finalizado';
      case EstadoProyecto.ganador:
        return 'ganador';
      case EstadoProyecto.pendiente:
        return 'pendiente';
    }
  }

  String get estadoTexto {
    switch (estado) {
      case EstadoProyecto.aprobado:
        return 'Aprobado';
      case EstadoProyecto.rechazado:
        return 'Rechazado';
      case EstadoProyecto.apto:
        return 'Apto';
      case EstadoProyecto.finalizado:
        return 'Finalizado';
      case EstadoProyecto.ganador:
        return 'Ganador';
      case EstadoProyecto.pendiente:
        return 'Pendiente de revision';
    }
  }
}