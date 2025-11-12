# Esquema de datos en Firebase (Firestore)

Este archivo define las colecciones y campos para migrar toda la funcionalidad del Administrador de Concursos a Firebase.

## Colecciones Principales

- `administradores` (documentos identificados por `uid` de Firebase Auth)
  - `nombres`: string
  - `apellidos`: string
  - `correo`: string
  - `numeroTelefonico`: string

- `concursos` (documentos con ID auto-generado)
  - `nombre`: string
  - `image.png`: string (UID del administrador dueño)
  - `fecha_limite_inscripcion`: Timestamp
  - `fecha_revision`: Timestamp
  - `fecha_confirmacion_aceptados`: Timestamp
  - `fecha_creacion`: Timestamp (preferentemente `FieldValue.serverTimestamp()`)

  Subcolecciones:
  - `categorias`
    - `nombre`: string
    - `rango_ciclos`: string
  - `proyectos` (para futuras funcionalidades)
    - `titulo`: string
    - `descripcion`: string
    - `estudiante_uid`: string
    - `estado`: string (por ejemplo: `enviado`, `aceptado`, `rechazado`)

- `estudiantes` (opcional para app cliente; documentos identificados por `uid` de Firebase Auth)
  - `nombres`: string
  - `apellidos`: string
  - `correo`: string
  - `numeroTelefonico`: string

## Consultas e Índices recomendados

- `concursos` por `admin_uid` y ordenados por `fecha_creacion` descendente.
  - Índice compuesto: `admin_uid` (ASC) + `fecha_creacion` (DESC)

## Reglas de Seguridad (resumen)

- Los administradores sólo pueden leer/escribir sus propios documentos en `administradores/{uid}`.
- Los administradores sólo pueden leer/escribir `concursos` donde `admin_uid == request.auth.uid`.
- Las `categorias` dentro de un `concurso` heredan la restricción del dueño del concurso.

Consulta `firebase/firestore.rules` y `firebase/firestore.indexes.json` para ver versiones aplicables con Firebase CLI.