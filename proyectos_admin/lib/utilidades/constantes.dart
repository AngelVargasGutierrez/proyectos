class Constantes {
  // Información de la aplicación
  static const String nombreApp = 'Admin Proyectos EPIS';
  static const String versionApp = '1.0.0';
  
  // Colores principales
  static const int colorPrimario = 0xFF1976D2; // Azul
  static const int colorSecundario = 0xFF388E3C; // Verde
  static const int colorError = 0xFFD32F2F; // Rojo
  static const int colorAdvertencia = 0xFFF57C00; // Naranja
  
  // Mensajes de validación
  static const String campoRequerido = 'Este campo es requerido';
  static const String correoInvalido = 'Por favor ingrese un correo válido';
  static const String contrasenaCorta = 'La contraseña debe tener al menos 6 caracteres';
  static const String contrasenasNoCoinciden = 'Las contraseñas no coinciden';
  static const String telefonoCorto = 'El número debe tener al menos 9 dígitos';
  
  // Mensajes de éxito
  static const String registroExitoso = 'Registro exitoso';
  static const String concursoCreadoExitoso = 'Concurso creado exitosamente';
  static const String concursoEliminadoExitoso = 'Concurso eliminado exitosamente';
  
  // Mensajes de error
  static const String credencialesIncorrectas = 'Credenciales incorrectas';
  static const String correoYaRegistrado = 'El correo ya está registrado';
  static const String errorGeneral = 'Ha ocurrido un error inesperado';
  static const String errorCrearConcurso = 'Error al crear el concurso';
  static const String errorCargarConcursos = 'Error al cargar los concursos';
  static const String errorEliminarConcurso = 'Error al eliminar el concurso';
  
  // Estados de concurso
  static const String inscripcionesAbiertas = 'Inscripciones abiertas';
  static const String enProcesoRevision = 'En proceso de revisión';
  static const String revisionCompletada = 'Revisión completada';
  static const String finalizado = 'Finalizado';
  
  // Formatos de fecha
  static const String formatoFecha = 'dd/MM/yyyy';
  static const String formatoFechaHora = 'dd/MM/yyyy HH:mm';
  
  // Límites y configuraciones
  static const int longitudMinimaContrasena = 6;
  static const int longitudMinimaTelefono = 9;
  static const int diasMaximosSeleccionFecha = 365;
}