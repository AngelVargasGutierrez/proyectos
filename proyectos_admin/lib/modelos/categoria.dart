class Categoria {
  final String nombre;
  final String rangoCiclos;
  final List<String> juradosAsignados;

  Categoria({
    required this.nombre,
    required this.rangoCiclos,
    List<String>? juradosAsignados,
  }) : juradosAsignados = juradosAsignados ?? const [];

  Map<String, dynamic> aJson() {
    return {
      'nombre': nombre,
      'rangoCiclos': rangoCiclos,
      'juradosAsignados': juradosAsignados,
    };
  }

  static Categoria desdeJson(Map<String, dynamic> json) {
    return Categoria(
      nombre: json['nombre'],
      rangoCiclos: json['rangoCiclos'],
      juradosAsignados: (json['juradosAsignados'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  @override
  String toString() => '$nombre: $rangoCiclos';
}