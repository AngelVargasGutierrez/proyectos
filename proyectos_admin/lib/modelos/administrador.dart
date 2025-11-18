enum RolUsuario {
  administrador,
  jurado,
}

enum MetodoAutenticacion {
  email,
  microsoft,
}

class Administrador {
  final String id;
  final String nombres;
  final String apellidos;
  final String correo;
  final String numeroTelefonico;
  final RolUsuario rol;
  final MetodoAutenticacion metodoAutenticacion;

  Administrador({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.numeroTelefonico,
    required this.rol,
    this.metodoAutenticacion = MetodoAutenticacion.email,
  });

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'correo': correo,
      'numeroTelefonico': numeroTelefonico,
      'rol': rol.name,
      'metodoAutenticacion': metodoAutenticacion.name,
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
      metodoAutenticacion: _metodoFromString(json['metodoAutenticacion'] ?? 'email'),
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

  static MetodoAutenticacion _metodoFromString(String s) {
    switch (s.toLowerCase()) {
      case 'microsoft':
        return MetodoAutenticacion.microsoft;
      default:
        return MetodoAutenticacion.email;
    }
  }
}