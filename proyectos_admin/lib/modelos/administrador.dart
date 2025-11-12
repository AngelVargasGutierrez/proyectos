enum RolUsuario {
  administrador,
  jurado,
}

class Administrador {
  final String id;
  final String nombres;
  final String apellidos;
  final String correo;
  final String numeroTelefonico;
  final RolUsuario rol;

  Administrador({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.numeroTelefonico,
    required this.rol,
  });

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'correo': correo,
      'numeroTelefonico': numeroTelefonico,
      'rol': rol.name,
    };
  }

  static Administrador desdeJson(Map<String, dynamic> json) {
    return Administrador(
      id: json['id'],
      nombres: json['nombres'],
      apellidos: json['apellidos'],
      correo: json['correo'],
      numeroTelefonico: json['numeroTelefonico'],
      rol: _rolFromString(json['rol'] ?? 'administrador'),
    );
  }

  String get nombreCompleto => '$nombres $apellidos';

  static RolUsuario _rolFromString(String s) {
    switch (s.toLowerCase()) {
      case 'jurado':
        return RolUsuario.jurado;
      default:
        return RolUsuario.administrador;
    }
  }
}