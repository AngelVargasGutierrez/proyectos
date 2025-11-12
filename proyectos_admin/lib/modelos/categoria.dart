class Categoria {
  final String nombre;
  final String rangoCiclos;

  Categoria({
    required this.nombre,
    required this.rangoCiclos,
  });

  Map<String, dynamic> aJson() {
    return {
      'nombre': nombre,
      'rangoCiclos': rangoCiclos,
    };
  }

  static Categoria desdeJson(Map<String, dynamic> json) {
    return Categoria(
      nombre: json['nombre'],
      rangoCiclos: json['rangoCiclos'],
    );
  }

  @override
  String toString() => '$nombre: $rangoCiclos';
}