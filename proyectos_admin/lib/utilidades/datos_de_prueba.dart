import '../modelos/administrador.dart';
import '../modelos/concurso.dart';
import '../modelos/categoria.dart';

class DatosDePrueba {
  static void cargarDatosIniciales() {
    // Se pueden agregar datos de prueba aquí si es necesario
    // Por ahora la aplicación empieza con datos vacíos
  }

  static Administrador obtenerAdministradorEjemplo() {
    return Administrador(
      id: '1',
      nombres: 'Juan Carlos',
      apellidos: 'Pérez García',
      correo: 'admin@epis.edu.pe',
      numeroTelefonico: '987654321',
    );
  }

  static List<Categoria> obtenerCategoriasEjemplo() {
    return [
      Categoria(nombre: 'Categoria A', rangoCiclos: 'V a VII ciclo'),
      Categoria(nombre: 'Categoria B', rangoCiclos: 'VIII a X ciclo'),
    ];
  }

  static Concurso obtenerConcursoEjemplo() {
    return Concurso(
      id: '1',
      nombre: 'Concurso de Proyectos EPIS 2024',
      categorias: obtenerCategoriasEjemplo(),
      fechaLimiteInscripcion: DateTime.now().add(const Duration(days: 30)),
      fechaRevision: DateTime.now().add(const Duration(days: 45)),
      fechaConfirmacionAceptados: DateTime.now().add(const Duration(days: 60)),
      fechaCreacion: DateTime.now(),
      administradorId: '1',
    );
  }
}