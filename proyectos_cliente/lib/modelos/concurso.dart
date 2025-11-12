class Concurso {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activo;
  final List<Categoria> categorias;

  Concurso({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.activo,
    required this.categorias,
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