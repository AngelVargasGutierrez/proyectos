class Validadores {
  static String? validarNombre(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (valor.trim().length < 2) {
      return 'Debe tener al menos 2 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(valor.trim())) {
      return 'Solo se permiten letras y espacios';
    }
    return null;
  }

  static String? validarCorreo(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(valor.trim())) {
      return 'Ingrese un correo valido';
    }
    return null;
  }

  static String? validarCodigoUniversitario(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El codigo universitario es obligatorio';
    }
    if (valor.trim().length != 10) {
      return 'El codigo debe tener 10 digitos';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(valor.trim())) {
      return 'Solo se permiten numeros';
    }
    return null;
  }

  static String? validarTelefono(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El numero telefonico es obligatorio';
    }
    if (valor.trim().length != 9) {
      return 'El numero debe tener 9 digitos';
    }
    if (!RegExp(r'^\d{9}$').hasMatch(valor.trim())) {
      return 'Solo se permiten numeros';
    }
    return null;
  }

  static String? validarCiclo(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El ciclo es obligatorio';
    }
    
    final ciclo = int.tryParse(valor.trim());
    if (ciclo == null) {
      return 'Ingrese un numero valido';
    }
    
    if (ciclo < 1 || ciclo > 10) {
      return 'El ciclo debe estar entre 1 y 10';
    }
    return null;
  }

  static String? validarContrasena(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'La contrasena es obligatoria';
    }
    if (valor.length < 6) {
      return 'La contrasena debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? validarNombreProyecto(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El nombre del proyecto es obligatorio';
    }
    if (valor.trim().length < 3) {
      return 'Debe tener al menos 3 caracteres';
    }
    return null;
  }

  static String? validarEnlaceGithub(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'El enlace de GitHub es obligatorio';
    }
    
    final regex = RegExp(r'^https?://github\.com/.+/.+$');
    if (!regex.hasMatch(valor.trim())) {
      return 'Ingrese un enlace valido de GitHub';
    }
    return null;
  }
}