# Guía de Desarrollo - Proyectos Cliente

## Resumen de la Aplicación

La aplicación "Concurso de Proyectos EPIS - Cliente" es una aplicación Flutter completa que permite a los estudiantes:

1. **Registrarse** con sus datos académicos
2. **Iniciar sesión** de forma segura
3. **Ver concursos disponibles** en el dashboard
4. **Explorar categorías** de cada concurso
5. **Enviar proyectos** con GitHub y archivos ZIP
6. **Seguir el estado** de sus proyectos enviados

## Datos de Prueba

Para probar la aplicación, puedes usar cualquier correo y contraseña en el inicio de sesión. El sistema está configurado con datos de prueba que incluyen:

- **Estudiante de prueba**: Juan Carlos Perez Lopez (código: 2020123456)
- **Concursos disponibles**: 
  - Concurso de Innovación Tecnológica 2024
  - Hackathon EPIS 2024
- **Categorías de ejemplo**: Desarrollo Web, Aplicaciones Móviles, IA, etc.

## Principales Componentes

### Modelos de Datos
- `Estudiante`: Información del usuario registrado
- `Concurso`: Datos de concursos con fechas y categorías
- `Proyecto`: Proyectos enviados con estados de revisión

### Servicios
- `ServicioAutenticacion`: Manejo de registro, login y sesiones
- `ServicioConcursos`: Gestión de concursos y envío de proyectos

### Pantallas Principales
- `PantallaInicioSesion`: Login de usuarios
- `PantallaRegistro`: Registro de nuevos estudiantes
- `PantallaDashboard`: Vista principal con concursos
- `PantallaDetalleConcurso`: Información y categorías del concurso
- `PantallaEnviarProyecto`: Formulario de envío de proyectos
- `PantallaMisProyectos`: Lista de proyectos enviados por el usuario

## Validaciones Implementadas

Todas las validaciones están centralizadas en `lib/utilidades/validadores.dart`:

- **Nombres/Apellidos**: Solo letras, mínimo 2 caracteres
- **Código Universitario**: Exactamente 10 dígitos
- **Email**: Formato válido de correo electrónico
- **Teléfono**: Exactamente 9 dígitos
- **Ciclo**: Entre 1 y 10
- **URLs GitHub**: Formato válido de repositorio GitHub

## Funcionalidades Destacadas

### Persistencia de Sesión
- El usuario permanece logueado entre sesiones
- Usa `SharedPreferences` para almacenar datos de sesión

### Manejo de Archivos
- Selección de archivos ZIP usando `file_picker`
- Validación de tipos de archivo permitidos

### Enlaces Externos
- Apertura de repositorios GitHub con `url_launcher`
- Validación de URLs antes de abrirlas

### Estados de Proyecto
- **Pendiente**: Color amarillo, icono de reloj
- **Aprobado**: Color verde, icono de check
- **Rechazado**: Color rojo, icono de cancelar

## Integración con Backend

Actualmente usa datos simulados. Para conectar con API real:

1. **Actualizar URLs** en `servicio_autenticacion.dart` y `servicio_concursos.dart`
2. **Descomentar** las llamadas HTTP
3. **Comentar** las simulaciones de datos
4. **Ajustar** los modelos según la respuesta de la API

### Endpoints Esperados

```
POST /auth/registro     - Registro de estudiante
POST /auth/login        - Inicio de sesión
GET  /concursos/disponibles - Lista de concursos activos
POST /proyectos         - Envío de proyecto
GET  /proyectos/estudiante/:id - Proyectos del estudiante
```

## Ejecutar la Aplicación

1. **Instalar dependencias**:
```bash
flutter pub get
```

2. **Ejecutar en desarrollo**:
```bash
flutter run
```

3. **Compilar para producción**:
```bash
flutter build apk --release
```

## Personalización

### Colores y Tema
Edita `lib/utilidades/estilos.dart` para cambiar:
- Colores primarios y secundarios
- Estilos de texto
- Espaciados y bordes

### Datos de Prueba
Modifica los servicios para cambiar:
- Información del estudiante de prueba
- Concursos y categorías disponibles
- Estados de proyectos de ejemplo

## Estructura de Carpetas Recomendada para Backend

```
api/
├── auth/
│   ├── registro
│   └── login
├── concursos/
│   ├── disponibles
│   └── [id]/categorias
├── proyectos/
│   ├── crear
│   └── estudiante/[id]
└── uploads/
    └── archivos-zip/
```

## Consideraciones de Seguridad

- Las contraseñas deben hashearse en el backend
- Implementar tokens JWT para autenticación
- Validar archivos ZIP en el servidor
- Limitar el tamaño de archivos subidos

## Testing

Para crear tests unitarios y de integración:

```bash
flutter test
```

Ubicar tests en:
- `test/unit/` - Tests unitarios
- `test/widget/` - Tests de widgets
- `test/integration/` - Tests de integración

¡La aplicación está lista para usar y expandir según tus necesidades!