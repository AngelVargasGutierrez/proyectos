# Admin Proyectos EPIS

Aplicación Flutter para la administración de concursos de proyectos de EPIS (Escuela Profesional de Ingeniería de Sistemas).

## Características

### Funcionalidades de Administrador
- **Registro de administradores**: Nombres, apellidos, correo electrónico y número telefónico
- **Inicio de sesión**: Autenticación segura para administradores
- **Gestión de concursos**: Crear, listar y eliminar concursos de proyectos

### Gestión de Concursos
- **Creación de concursos** con los siguientes datos:
  - Nombre del concurso
  - Categorías con rangos de ciclos (ej: Categoría A: de V a VII ciclo)
  - Fecha límite para inscribirse
  - Fecha de revisión
  - Fecha de confirmación de aceptados
- **Lista de concursos**: Visualización de todos los concursos creados por el administrador
- **Estados del concurso**: Seguimiento automático del estado basado en las fechas
- **Detalles del concurso**: Vista completa de información y categorías

## Estructura del Proyecto

```
lib/
├── main.dart                           # Punto de entrada de la aplicación
├── modelos/
│   ├── administrador.dart              # Modelo de datos del administrador
│   ├── categoria.dart                  # Modelo de categorías de concurso
│   └── concurso.dart                   # Modelo de datos del concurso
├── servicios/
│   ├── servicio_autenticacion.dart     # Lógica de autenticación
│   └── servicio_concursos.dart         # Lógica de gestión de concursos
├── proveedores/
│   ├── proveedor_autenticacion.dart    # Estado de autenticación (Provider)
│   └── proveedor_concursos.dart        # Estado de concursos (Provider)
└── pantallas/
    ├── pantalla_inicio_sesion.dart     # Pantalla de inicio de sesión
    ├── pantalla_registro.dart          # Pantalla de registro
    ├── pantalla_principal.dart         # Pantalla principal con navegación
    ├── pantalla_crear_concurso.dart    # Pantalla para crear concursos
    └── pantalla_lista_concursos.dart   # Pantalla para listar concursos
```

## Dependencias

- **flutter**: Framework de desarrollo
- **provider**: Gestión de estado
- **intl**: Formateo de fechas y localización

## Instalación y Ejecución

1. **Clonar el repositorio**
2. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```
3. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```

## Uso de la Aplicación

### Para Administradores

1. **Registro**:
   - Abrir la aplicación
   - Tocar "No tienes cuenta? Regístrate aquí"
   - Completar el formulario con nombres, apellidos, correo y teléfono
   - Crear una contraseña segura

2. **Inicio de Sesión**:
   - Ingresar correo electrónico y contraseña
   - Tocar "Iniciar Sesión"

3. **Crear Concurso**:
   - Ir a la pestaña "Crear Concurso"
   - Ingresar nombre del concurso
   - Seleccionar las fechas importantes
   - Agregar categorías con sus rangos de ciclos
   - Tocar "Crear Concurso"

4. **Gestionar Concursos**:
   - Ver lista de concursos en la pestaña "Concursos"
   - Tocar en un concurso para ver detalles
   - Usar el menú de opciones para eliminar concursos

## Estados de Concurso

- **Inscripciones abiertas**: Antes de la fecha límite de inscripción
- **En proceso de revisión**: Entre fecha límite y fecha de revisión
- **Revisión completada**: Entre fecha de revisión y confirmación de aceptados
- **Finalizado**: Después de la fecha de confirmación de aceptados

## Consideraciones Técnicas

- **Almacenamiento temporal**: Los datos se almacenan en memoria durante la ejecución
- **Preparado para BD**: La estructura está lista para conectar con base de datos en la nube
- **Responsive**: Interfaz adaptada para diferentes tamaños de pantalla
- **Validaciones**: Formularios con validación completa de datos

## Próximas Mejoras

- Conexión con base de datos en la nube
- Notificaciones push
- Exportación de reportes
- Gestión de equipos participantes
- Sistema de evaluación de proyectos

## Contribución

Este proyecto forma parte del sistema de gestión de concursos de proyectos de EPIS. Para contribuir o reportar errores, contactar al equipo de desarrollo.
