# Concurso de Proyectos EPIS - Cliente

Aplicación móvil Flutter para estudiantes que desean participar en concursos de proyectos de la Escuela Profesional de Ingeniería de Sistemas (EPIS).

## Características Principales

### Funcionalidades de Usuario (Estudiante)
- **Registro de usuario**: Los estudiantes pueden crear una cuenta con sus datos personales
- **Inicio de sesión**: Acceso seguro a la aplicación
- **Dashboard**: Vista principal con concursos disponibles
- **Exploración de concursos**: Lista de concursos activos creados por el administrador
- **Categorías de concurso**: Visualización de categorías disponibles por concurso
- **Envío de proyectos**: Subida de proyectos con enlace de GitHub y archivo ZIP
- **Seguimiento de proyectos**: Vista de proyectos enviados y su estado de revisión
- **Estados de proyecto**: Pendiente, Aprobado, Rechazado

### Datos de Registro Requeridos
- Nombres completos
- Apellidos completos
- Código universitario (10 dígitos)
- Correo electrónico
- Número telefónico (9 dígitos)
- Ciclo académico (1-10)
- Contraseña

### Flujo de Trabajo
1. **Registro/Inicio de sesión** del estudiante
2. **Visualización del dashboard** con concursos disponibles
3. **Selección de concurso** y exploración de categorías
4. **Envío de proyecto** con:
   - Nombre del proyecto
   - Enlace de repositorio GitHub
   - Archivo ZIP con código fuente
5. **Seguimiento del estado** del proyecto enviado

## Estructura del Proyecto

```
lib/
├── main.dart                       # Punto de entrada de la aplicación
├── modelos/                        # Modelos de datos
│   ├── estudiante.dart
│   ├── concurso.dart
│   └── proyecto.dart
├── pantallas/                      # Pantallas de la aplicación
│   ├── pantalla_inicio_sesion.dart
│   ├── pantalla_registro.dart
│   ├── pantalla_dashboard.dart
│   ├── pantalla_detalle_concurso.dart
│   ├── pantalla_enviar_proyecto.dart
│   └── pantalla_mis_proyectos.dart
├── servicios/                      # Servicios de API y lógica de negocio
│   ├── servicio_autenticacion.dart
│   └── servicio_concursos.dart
├── utilidades/                     # Utilidades y helpers
│   ├── validadores.dart
│   └── estilos.dart
└── widgets/                        # Widgets reutilizables
    └── widgets_personalizados.dart
```

## Dependencias Utilizadas

- **http**: Para comunicación con APIs REST
- **shared_preferences**: Para almacenamiento local de sesión
- **file_picker**: Para selección de archivos ZIP
- **url_launcher**: Para abrir enlaces de GitHub

## Instalación y Configuración

### Prerrequisitos
- Flutter SDK (>=3.9.0)
- Dart SDK
- Android Studio o VS Code
- Emulador Android o dispositivo físico

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone <url-del-repositorio>
cd proyectos_cliente
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Ejecutar la aplicación**
```bash
flutter run
```

## Configuración de la API

Actualmente la aplicación utiliza datos simulados para desarrollo. Para conectar con una API real:

1. **Actualizar URLs base** en los servicios:
   - `lib/servicios/servicio_autenticacion.dart`
   - `lib/servicios/servicio_concursos.dart`

2. **Descomentar las llamadas HTTP** y comentar las simulaciones

3. **Configurar endpoints** según la API backend

## Estados de Proyecto

- **Pendiente**: Proyecto enviado, esperando revisión del administrador
- **Aprobado**: Proyecto aceptado por el administrador
- **Rechazado**: Proyecto rechazado con comentarios del administrador

## Validaciones Implementadas

### Registro de Usuario
- **Nombres/Apellidos**: Solo letras y espacios, mínimo 2 caracteres
- **Código Universitario**: Exactamente 10 dígitos numéricos
- **Correo**: Formato de email válido
- **Teléfono**: Exactamente 9 dígitos numéricos
- **Ciclo**: Número entre 1 y 10
- **Contraseña**: Mínimo 6 caracteres

### Envío de Proyecto
- **Nombre del Proyecto**: Mínimo 3 caracteres
- **GitHub**: URL válida de repositorio GitHub
- **Archivo**: Solo archivos con extensión .zip

## Características de UI/UX

- **Diseño Material**: Siguiendo las guías de Material Design
- **Tema personalizado**: Colores corporativos azules
- **Responsive**: Adaptable a diferentes tamaños de pantalla
- **Validación en tiempo real**: Feedback inmediato en formularios
- **Loading states**: Indicadores de carga para mejor experiencia
- **Pull to refresh**: Actualización de contenido con gesto
- **Navigation**: Navegación intuitiva entre pantallas

## Arquitectura

- **Patrón MVC**: Separación clara de responsabilidades
- **Servicios singleton**: Gestión centralizada de datos
- **Widgets reutilizables**: Componentes modulares para UI
- **Validación centralizada**: Validadores reutilizables
- **Gestión de estado**: StatefulWidget para estados locales

## Funcionalidades Futuras

- [ ] Notificaciones push para cambios de estado
- [ ] Chat integrado con administradores
- [ ] Historial de versiones de proyectos
- [ ] Clasificación y rankings
- [ ] Exportación de certificados
- [ ] Modo offline básico

## Notas de Desarrollo

- **Idioma**: Código completamente en español (excepto palabras técnicas)
- **Sin emojis**: Interfaz profesional sin iconos emoji
- **Evitar ñ**: Se evita el uso de la letra ñ en nombres de variables
- **Base de datos**: Preparado para integración con API REST en la nube

## Compilación para Producción

```bash
# Android
flutter build apk --release

# iOS (requiere macOS)
flutter build ios --release
```

## Licencia

Este proyecto está desarrollado para uso académico en la Escuela Profesional de Ingeniería de Sistemas.
