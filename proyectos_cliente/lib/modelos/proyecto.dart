enum EstadoProyecto {
  pendiente,
  aprobado,
  rechazado,
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
    };
  }

  static EstadoProyecto _estadoDesdeTexto(String texto) {
    switch (texto.toLowerCase()) {
      case 'aprobado':
        return EstadoProyecto.aprobado;
      case 'rechazado':
        return EstadoProyecto.rechazado;
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
      case EstadoProyecto.pendiente:
        return 'Pendiente de revision';
    }
  }
}