class Estudiante {
  final String id;
  final String nombres;
  final String apellidos;
  final String codigoUniversitario;
  final String correo;
  final String numeroTelefonico;
  final int ciclo;

  Estudiante({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.codigoUniversitario,
    required this.correo,
    required this.numeroTelefonico,
    required this.ciclo,
  });

  factory Estudiante.desdeJson(Map<String, dynamic> json) {
    return Estudiante(
      id: json['id'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      codigoUniversitario: json['codigo_universitario'] ?? '',
      correo: json['correo'] ?? '',
      numeroTelefonico: json['numero_telefonico'] ?? '',
      ciclo: json['ciclo'] ?? 0,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'codigo_universitario': codigoUniversitario,
      'correo': correo,
      'numero_telefonico': numeroTelefonico,
      'ciclo': ciclo,
    };
  }

  String get nombreCompleto => '$nombres $apellidos';
}