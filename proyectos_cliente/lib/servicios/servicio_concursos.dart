import '../modelos/concurso.dart';
import '../modelos/proyecto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../utilidades/api_config.dart';

class ServicioConcursos {
  static ServicioConcursos? _instancia;
  static ServicioConcursos get instancia {
    _instancia ??= ServicioConcursos._();
    return _instancia!;
  }

  ServicioConcursos._();

  Future<List<Concurso>> obtenerConcursosDisponibles() async {
    try {
      final qs = await FirebaseFirestore.instance.collection('concursos').get();
      final concursos = <Concurso>[];
      for (final doc in qs.docs) {
        final data = doc.data();

        DateTime _parseFecha(dynamic valor) {
          if (valor == null) return DateTime.now();
          if (valor is Timestamp) return valor.toDate();
          if (valor is String) {
            try {
              return DateTime.parse(valor);
            } catch (_) {
              return DateTime.now();
            }
          }
          return DateTime.now();
        }

        final fechaInicio = _parseFecha(data['fecha_creacion']);
        final fechaFin = _parseFecha(data['fecha_limite_inscripcion']);
        final activo = DateTime.now().isBefore(fechaFin);

        // Cargar subcolección de categorías si existe
        final catsSnap = await doc.reference.collection('categorias').get();
        final categorias = catsSnap.docs.map((cDoc) {
          final cData = cDoc.data();
          return Categoria(
            id: cDoc.id,
            nombre: (cData['nombre'] ?? '') as String,
            descripcion: (cData['descripcion'] ?? cData['rango_ciclos'] ?? '') as String,
            concursoId: doc.id,
          );
        }).toList();

        concursos.add(
          Concurso(
            id: doc.id,
            nombre: (data['nombre'] ?? '') as String,
            descripcion: (data['descripcion'] ?? '') as String,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
            activo: activo,
            categorias: categorias,
          ),
        );
      }

      return concursos;
    } catch (fe) {
      print('Error al obtener concursos (Firestore): $fe');
      return [];
    }
  }

  Future<Concurso?> obtenerConcursoPorId(String id) async {
    try {
      final concursos = await obtenerConcursosDisponibles();
      return concursos.firstWhere((concurso) => concurso.id == id);
    } catch (e) {
      print('Error al obtener concurso por ID: $e');
      return null;
    }
  }

  Future<bool> enviarProyecto({
    required String nombreProyecto,
    required String estudianteId,
    required String concursoId,
    required String categoriaId,
    required String enlaceGithub,
    String? archivoZipNombre,
    Uint8List? archivoZipBytes,
  }) async {
    try {
      // Solo Firebase: subir directamente a Storage y guardar en Firestore

      // Fallback: subir archivo comprimido (ZIP/RAR) a Storage y guardar envio en Firestore bajo el concurso
      try {
        final concursoRef = FirebaseFirestore.instance.collection('concursos').doc(concursoId);
        // Unicidad por concurso: si ya existe algún proyecto del estudiante en este concurso, bloquear
        final existeEnConcurso = await concursoRef
            .collection('proyectos')
            .where('estudiante_id', isEqualTo: estudianteId)
            .limit(1)
            .get();
        if (existeEnConcurso.docs.isNotEmpty) {
          // Ya existe en Firestore: no duplicamos, pero creamos carpeta en backend
          try {
            final intConc = int.tryParse(concursoId) ?? 1;
            final intCat = int.tryParse(categoriaId) ?? 1;
            final intEst = 6; // TEMP: mapeo UID->ID en integración posterior

            final uri = Uri.parse('$apiBaseUrl/proyectos/crear_carpeta');
            final resp = await http.post(
              uri,
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {
                'titulo': nombreProyecto.trim(),
                'github_url': enlaceGithub.trim(),
                'estudiante_id': intEst.toString(),
                'concurso_id': intConc.toString(),
                'categoria_id': intCat.toString(),
              },
            );
            if (resp.statusCode < 200 || resp.statusCode >= 300) {
              print('Aviso: fallo crear carpeta (duplicado): ${resp.statusCode} ${resp.body}');
            } else {
              print('Carpeta creada en backend (duplicado): ${resp.body}');
            }
          } catch (apiErr) {
            print('Aviso: error API crear_carpeta (duplicado): $apiErr');
          }
          return false;
        }
        // ID determinístico por categoría+estudiante (mantener para consistencia de ruta Storage)
        final proyectoRef = concursoRef.collection('proyectos').doc('$categoriaId-$estudianteId');

        String? descargaUrl;
        // Subir archivo sólo si fue proporcionado
        if (archivoZipBytes != null && archivoZipBytes.isNotEmpty) {
          // Determinar extensión y MIME
          String extension = 'zip';
          final nombre = (archivoZipNombre ?? '').trim();
          final punto = nombre.lastIndexOf('.');
          if (punto != -1 && punto < nombre.length - 1) {
            extension = nombre.substring(punto + 1).toLowerCase();
          }
          // Simplificar tipo MIME para evitar problemas de preflight/CORS en Web
          final contentType = 'application/octet-stream';

          // Subir a Firebase Storage usando el ID del documento preservando la extensión
          final pathArchivo = 'proyectos/$concursoId/$categoriaId/$estudianteId/${proyectoRef.id}.$extension';
          final storageRef = FirebaseStorage.instance.ref(pathArchivo);
          await storageRef.putData(
            archivoZipBytes,
            SettableMetadata(contentType: contentType),
          );
          descargaUrl = await storageRef.getDownloadURL();
        }

        String categoriaNombre = '';
        try {
          final catDoc = await FirebaseFirestore.instance
              .collection('concursos')
              .doc(concursoId)
              .collection('categorias')
              .doc(categoriaId)
              .get();
          final cData = catDoc.data() ?? <String, dynamic>{};
          categoriaNombre = (cData['nombre'] ?? '') as String;
        } catch (_) {}

        final data = {
          'nombre': nombreProyecto.trim(),
          'enlace_github': enlaceGithub.trim(),
          'estado': 'pendiente',
          'fecha_envio': FieldValue.serverTimestamp(),
          'estudiante_id': estudianteId,
          'concurso_id': concursoId,
          'categoria_id': categoriaId,
        };
        if (categoriaNombre.isNotEmpty) {
          data['categoria_nombre'] = categoriaNombre;
        }
        if (descargaUrl != null) {
          data['archivo_zip'] = descargaUrl;
          if (archivoZipNombre != null) {
            data['nombre_zip'] = archivoZipNombre.trim();
          }
        }
        await proyectoRef.set(data);

        // Intentar crear la carpeta y github.txt en el backend (modo local o SharePoint)
        try {
          // Mapear IDs a enteros si es posible; usar fallback si no son numéricos
          final intConc = int.tryParse(concursoId) ?? 1;
          final intCat = int.tryParse(categoriaId) ?? 1;
          // TEMP: usar ID de estudiante de pruebas mientras se integra mapeo UID->ID
          final intEst = 6;

          final uri = Uri.parse('$apiBaseUrl/proyectos/crear_carpeta');
          final resp = await http.post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'titulo': nombreProyecto.trim(),
              'github_url': enlaceGithub.trim(),
              'estudiante_id': intEst.toString(),
              'concurso_id': intConc.toString(),
              'categoria_id': intCat.toString(),
            },
          );
          // No bloquear si falla; solo loguear
          if (resp.statusCode < 200 || resp.statusCode >= 300) {
            print('Aviso: fallo al crear carpeta en backend: ${resp.statusCode} ${resp.body}');
          }
        } catch (apiErr) {
          print('Aviso: error al llamar a API crear_carpeta: $apiErr');
        }

        return true;
      } catch (fsErr) {
        print('Error Firestore al enviar proyecto: $fsErr');
        return false;
      }
    } catch (e) {
      print('Error inesperado al enviar proyecto: $e');
      return false;
    }
  }

  Future<List<Proyecto>> obtenerProyectosEstudiante(String estudianteId) async {
    try {
      // Solo Firebase: excluir llamadas a API y consultar directamente Firestore

      // Fallback: consultar proyectos desde Firestore (collectionGroup)
      try {
        final qs = await FirebaseFirestore.instance
            .collectionGroup('proyectos')
            .where('estudiante_id', isEqualTo: estudianteId)
            .get();

        return qs.docs.map((doc) {
          final data = doc.data();
          final concursoIdFs = doc.reference.parent.parent?.id ?? (data['concurso_id'] ?? '') as String;
          final fechaEnvioTs = data['fecha_envio'];
          DateTime fechaEnvio;
          if (fechaEnvioTs is Timestamp) {
            fechaEnvio = fechaEnvioTs.toDate();
          } else if (fechaEnvioTs is String) {
            fechaEnvio = DateTime.tryParse(fechaEnvioTs) ?? DateTime.now();
          } else {
            fechaEnvio = DateTime.now();
          }
          final estadoStr = (data['estado'] ?? 'pendiente') as String;
          return Proyecto(
            id: doc.id,
            nombre: (data['nombre'] ?? data['titulo'] ?? '') as String,
            estudianteId: (data['estudiante_id'] ?? data['estudiante_uid'] ?? '') as String,
            concursoId: concursoIdFs,
            categoriaId: (data['categoria_id'] ?? '') as String,
            enlaceGithub: (data['enlace_github'] ?? data['link_github'] ?? '') as String,
            archivoZip: (data['archivo_zip'] ?? '') as String,
            estado: _estadoClienteDesdeApi(estadoStr),
            fechaEnvio: fechaEnvio,
            comentarioAdmin: (data['comentarios'] ?? data['comentario_admin']) as String?,
          );
        }).toList();
      } catch (fsErr) {
        print('Error Firestore al obtener proyectos del estudiante: $fsErr');
        return [];
      }
    } catch (e) {
      print('Error al obtener proyectos del estudiante: $e');
      return [];
    }
  }
}

EstadoProyecto _estadoClienteDesdeApi(String estado) {
  switch (estado.toLowerCase()) {
    case 'aprobado':
      return EstadoProyecto.aprobado;
    case 'rechazado':
      return EstadoProyecto.rechazado;
    default:
      return EstadoProyecto.pendiente;
  }
}