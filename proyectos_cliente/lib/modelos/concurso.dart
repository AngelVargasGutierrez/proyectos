class Concurso {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activo;
  final List<Categoria> categorias;
  final DateTime? fechaRevision;
  final DateTime? fechaConfirmacionAceptados;
  final String? basesUrl;

  Concurso({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.activo,
    required this.categorias,
    this.fechaRevision,
    this.fechaConfirmacionAceptados,
    this.basesUrl,
  });

  factory Concurso.desdeJson(Map<String, dynamic> json) {
    return Concurso(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaInicio: DateTime.parse(json['fecha_inicio'] ?? DateTime.now().toString()),
      fechaFin: DateTime.parse(json['fecha_fin'] ?? DateTime.now().toString()),
      activo: json['activo'] ?? false,
      categorias: (json['categorias'] as List<dynamic>?)
          ?.map((categoria) => Categoria.desdeJson(categoria))
          .toList() ?? [],
      fechaRevision: json['fecha_revision'] != null ? DateTime.parse(json['fecha_revision']) : null,
      fechaConfirmacionAceptados: json['fecha_confirmacion_aceptados'] != null ? DateTime.parse(json['fecha_confirmacion_aceptados']) : null,
      basesUrl: json['bases_url'],
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'activo': activo,
      'categorias': categorias.map((categoria) => categoria.aJson()).toList(),
      if (fechaRevision != null) 'fecha_revision': fechaRevision!.toIso8601String(),
      if (fechaConfirmacionAceptados != null) 'fecha_confirmacion_aceptados': fechaConfirmacionAceptados!.toIso8601String(),
      if (basesUrl != null) 'bases_url': basesUrl,
    };
  }

  bool get estaVigente {
    final ahora = DateTime.now();
    return activo && ahora.isAfter(fechaInicio) && ahora.isBefore(fechaFin);
  }
}

class Categoria {
  final String id;
  final String nombre;
  final String descripcion;
  final String concursoId;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.concursoId,
  });

  factory Categoria.desdeJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      concursoId: json['concurso_id'] ?? '',
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'concurso_id': concursoId,
    };
  }
}