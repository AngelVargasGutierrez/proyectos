import '../modelos/proyecto.dart';
import 'servicio_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ServicioProyectos {
  static final ServicioProyectos _instancia = ServicioProyectos._interno();
  factory ServicioProyectos() => _instancia;
  ServicioProyectos._interno();

  Future<List<Proyecto>> obtenerProyectosPorConcurso(String concursoId) async {
    try {
      final idNum = int.parse(concursoId);
      final data =
          await ServicioApi.getJson('/proyectos/por_concurso/$idNum')
              as List<dynamic>;
      return data.map((row) => _desdeApi(row)).toList();
    } catch (e) {
      // Fallback a Firestore: leer subcoleccion proyectos del concurso
      try {
        final qs = await FirebaseFirestore.instance
            .collection('concursos')
            .doc(concursoId)
            .collection('proyectos')
            .orderBy('fecha_envio', descending: true)
            .get();

        return Future.wait(
          qs.docs.map((doc) async {
            final data = doc.data();
            final estudianteUid =
                (data['estudiante_id'] ?? data['estudiante_uid'] ?? '')
                    as String;
            String nombreEstudiante = '';
            String correoEstudiante = '';
            if (estudianteUid.isNotEmpty) {
              try {
                // Intentar obtener perfil desde 'usuarios' (cliente) y fallback a 'estudiantes'
                final uDoc = await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(estudianteUid)
                    .get();
                final uData = uDoc.data() ?? <String, dynamic>{};
                if (uData.isNotEmpty) {
                  final nombres = (uData['nombres'] ?? '') as String;
                  final apellidos = (uData['apellidos'] ?? '') as String;
                  nombreEstudiante = [
                    nombres,
                    apellidos,
                  ].where((s) => s.isNotEmpty).join(' ').trim();
                  correoEstudiante = (uData['correo'] ?? '') as String;
                } else {
                  final eDoc = await FirebaseFirestore.instance
                      .collection('estudiantes')
                      .doc(estudianteUid)
                      .get();
                  final eData = eDoc.data() ?? <String, dynamic>{};
                  final nombres = (eData['nombres'] ?? '') as String;
                  final apellidos = (eData['apellidos'] ?? '') as String;
                  nombreEstudiante = [
                    nombres,
                    apellidos,
                  ].where((s) => s.isNotEmpty).join(' ').trim();
                  correoEstudiante = (eData['correo'] ?? '') as String;
                }
              } catch (_) {}
            }

            DateTime _parseFecha(dynamic v) {
              if (v is Timestamp) return v.toDate();
              if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
              return DateTime.now();
            }

            String _estadoDesdeFs(dynamic v) {
              final s = (v ?? 'enviado').toString().toLowerCase();
              if (s == 'pendiente') return 'enviado';
              if (s == 'en_revision' || s == 'revision') return 'en_revision';
              if (s == 'aprobado') return 'aprobado';
              if (s == 'rechazado') return 'rechazado';
              if (s == 'ganador') return 'ganador';
              return 'enviado';
            }

            return Proyecto(
              id: doc.id,
              nombre: (data['nombre'] ?? data['titulo'] ?? '') as String,
              linkGithub:
                  (data['enlace_github'] ?? data['github_url'] ?? '') as String,
              archivoZip:
                  (data['archivo_zip'] ?? data['zip_url'] ?? '') as String,
              estudianteId: estudianteUid,
              nombreEstudiante: nombreEstudiante,
              correoEstudiante: correoEstudiante,
              concursoId: (data['concurso_id'] ?? concursoId) as String,
              categoriaId: (data['categoria_id'] ?? '') as String,
              fechaEnvio: _parseFecha(data['fecha_envio']),
              estado: _mapEstado(_estadoDesdeFs(data['estado'])),
              comentarios: (data['comentarios'] ?? '') as String?,
              puntuacion: ((data['puntuacion'] ?? 0) as num).toDouble(),
            );
          }),
        );
      } catch (fe) {
        return [];
      }
    }
  }

  Future<bool> enviarEvaluacionJurado({
    required String concursoId,
    required String proyectoId,
    required String categoriaId,
    required String juradoUid,
    required Map<String, int> criterios,
  }) async {
    try {
      // Persistir evaluación del jurado en Firestore y recalcular puntuación promedio
      final refProyecto = FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId)
          .collection('proyectos')
          .doc(proyectoId);

      final total = criterios.values.fold<int>(0, (a, b) => a + b);
      final evalData = {
        ...criterios,
        'total': total,
        'fecha': FieldValue.serverTimestamp(),
      };

      await refProyecto.set({
        'evaluaciones_jurado': {juradoUid: evalData},
      }, SetOptions(merge: true));

      // Obtener todas las evaluaciones y calcular promedio normalizado a 20
      final snap = await refProyecto.get();
      final data = snap.data() ?? <String, dynamic>{};
      final evals =
          (data['evaluaciones_jurado'] ?? <String, dynamic>{})
              as Map<String, dynamic>;
      if (evals.isNotEmpty) {
        double sumaNormalizada = 0;
        int conteo = 0;
        evals.forEach((_, v) {
          final m = (v ?? <String, dynamic>{}) as Map<String, dynamic>;
          final t = ((m['total'] ?? 0) as num).toDouble();
          // Normalizar de 28 a 20
          final norm = (t / 28.0) * 20.0;
          sumaNormalizada += norm;
          conteo += 1;
        });
        final promedio = conteo > 0 ? (sumaNormalizada / conteo) : 0.0;
        await refProyecto.update({'puntuacion': promedio});
      }

      // Verificar si TODOS los jurados asignados a la categoría ya votaron
      final refCategoria = FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId)
          .collection('categorias')
          .doc(categoriaId);
      final catSnap = await refCategoria.get();
      final catData = catSnap.data() ?? <String, dynamic>{};
      final asignadosUids = (catData['jurados_asignados_uids'] ?? []) as List?;
      final asignadosNombres = (catData['jurados_asignados'] ?? []) as List?;
      int totalAsignados = 0;
      if (asignadosUids != null && asignadosUids.isNotEmpty) {
        totalAsignados = asignadosUids.length;
      } else if (asignadosNombres != null && asignadosNombres.isNotEmpty) {
        totalAsignados = asignadosNombres.length;
      }
      final votosRecibidos = evals.length;

      // Solo declarar ganador si todos los jurados asignados ya votaron
      if (totalAsignados > 0 && votosRecibidos >= totalAsignados) {
        // Calcular ganador automático dentro de la categoría: mayor puntuación
        final qsCategoria = await FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId)
          .collection('proyectos')
          .where('categoria_id', isEqualTo: categoriaId)
          .get();

        if (qsCategoria.docs.isNotEmpty) {
          String? ganadorId;
          double maxP = -1;
          for (final d in qsCategoria.docs) {
            final pd = d.data();
            final p = ((pd['puntuacion'] ?? 0) as num).toDouble();
            if (p > maxP) {
              maxP = p;
              ganadorId = d.id;
            }
          }
          if (ganadorId != null && maxP > 0) {
            for (final d in qsCategoria.docs) {
              final nuevoEstado = d.id == ganadorId
                  ? 'ganador'
                  : (pdEstado(d.data()) == 'ganador' ? 'aprobado' : null);
              if (nuevoEstado != null) {
                await d.reference.update({'estado': nuevoEstado});
              }
            }
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  String pdEstado(Map<String, dynamic> data) {
    final s = (data['estado'] ?? 'enviado').toString();
    return s;
  }

  Future<List<Proyecto>> obtenerProyectosPorCategoria(
    String concursoId,
    String categoriaId,
  ) async {
    try {
      final idNum = int.parse(concursoId);
      final data =
          await ServicioApi.getJson('/proyectos/por_concurso/$idNum')
              as List<dynamic>;
      final proyectos = data.map((row) => _desdeApi(row)).toList();
      return proyectos.where((p) => p.categoriaId == categoriaId).toList();
    } catch (e) {
      // Fallback Firestore: filtrar por categoria dentro del concurso
      try {
        final qs = await FirebaseFirestore.instance
            .collection('concursos')
            .doc(concursoId)
            .collection('proyectos')
            .where('categoria_id', isEqualTo: categoriaId)
            .get();
        return qs.docs.map((doc) {
          final data = doc.data();
          DateTime _parseFecha(dynamic v) {
            if (v is Timestamp) return v.toDate();
            if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
            return DateTime.now();
          }

          return Proyecto(
            id: doc.id,
            nombre: (data['nombre'] ?? data['titulo'] ?? '') as String,
            linkGithub:
                (data['enlace_github'] ?? data['github_url'] ?? '') as String,
            archivoZip:
                (data['archivo_zip'] ?? data['zip_url'] ?? '') as String,
            estudianteId:
                (data['estudiante_id'] ?? data['estudiante_uid'] ?? '')
                    as String,
            nombreEstudiante: '',
            correoEstudiante: '',
            concursoId: (data['concurso_id'] ?? concursoId) as String,
            categoriaId: (data['categoria_id'] ?? '') as String,
            fechaEnvio: _parseFecha(data['fecha_envio']),
            estado: _mapEstado(((data['estado'] ?? 'enviado') as String)),
            comentarios: (data['comentarios'] ?? '') as String?,
            puntuacion: ((data['puntuacion'] ?? 0) as num).toDouble(),
          );
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<Proyecto>> obtenerProyectosPorEstudiante(
    String estudianteId,
  ) async {
    try {
      final idNum = int.parse(estudianteId);
      final data =
          await ServicioApi.getJson('/proyectos/estudiante/$idNum')
              as List<dynamic>;
      return data.map((row) => _desdeApi(row)).toList();
    } catch (e) {
      // Fallback Firestore: buscar en collectionGroup proyectos por estudiante_id
      try {
        final qs = await FirebaseFirestore.instance
            .collectionGroup('proyectos')
            .where('estudiante_id', isEqualTo: estudianteId)
            .get();
        return qs.docs.map((doc) {
          final data = doc.data();
          DateTime _parseFecha(dynamic v) {
            if (v is Timestamp) return v.toDate();
            if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
            return DateTime.now();
          }

          return Proyecto(
            id: doc.id,
            nombre: (data['nombre'] ?? data['titulo'] ?? '') as String,
            linkGithub:
                (data['enlace_github'] ?? data['github_url'] ?? '') as String,
            archivoZip:
                (data['archivo_zip'] ?? data['zip_url'] ?? '') as String,
            estudianteId:
                (data['estudiante_id'] ?? data['estudiante_uid'] ?? '')
                    as String,
            nombreEstudiante: '',
            correoEstudiante: '',
            concursoId:
                (data['concurso_id'] ?? (doc.reference.parent.parent?.id ?? ''))
                    as String,
            categoriaId: (data['categoria_id'] ?? '') as String,
            fechaEnvio: _parseFecha(data['fecha_envio']),
            estado: _mapEstado(((data['estado'] ?? 'enviado') as String)),
            comentarios: (data['comentarios'] ?? '') as String?,
            puntuacion: ((data['puntuacion'] ?? 0) as num).toDouble(),
          );
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<bool> actualizarEstadoProyecto({
    required String proyectoId,
    String? concursoId,
    String? nuevoEstado,
    String? comentarios,
    double? puntuacion,
  }) async {
    try {
      final idNum = int.parse(proyectoId);
      final body = {
        'estado': nuevoEstado,
        'comentarios': comentarios,
        'puntuacion': puntuacion,
      }..removeWhere((k, v) => v == null);
      final resp = await ServicioApi.patchJson(
        '/proyectos/$idNum/estado',
        body,
      );
      return (resp['updated'] ?? 0) > 0;
    } catch (e) {
      // Fallback Firestore: ubicar documento por id en collectionGroup y actualizar
      try {
        DocumentReference<Map<String, dynamic>>? ref;
        if (concursoId != null && concursoId.isNotEmpty) {
          final doc = await FirebaseFirestore.instance
              .collection('concursos')
              .doc(concursoId)
              .collection('proyectos')
              .doc(proyectoId)
              .get();
          if (doc.exists) ref = doc.reference;
        }
        if (ref == null) {
          final qs = await FirebaseFirestore.instance
              .collectionGroup('proyectos')
              .where(FieldPath.documentId, isEqualTo: proyectoId)
              .get();
          if (qs.docs.isNotEmpty) {
            ref = qs.docs.first.reference;
          }
        }
        if (ref == null) return false;
        final update = <String, dynamic>{};
        if (nuevoEstado != null) update['estado'] = nuevoEstado;
        if (comentarios != null) update['comentarios'] = comentarios;
        if (puntuacion != null) update['puntuacion'] = puntuacion;
        if (update.isEmpty) return true;
        await ref.update(update);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<String?> subirZipDeProyecto({
    required String concursoId,
    required String proyectoId,
    required String filePath,
  }) async {
    try {
      final f = File(filePath);
      if (!f.existsSync()) return null;
      final ref = FirebaseStorage.instance.ref().child(
        'concursos/$concursoId/proyectos/$proyectoId/assets.zip',
      );
      final meta = SettableMetadata(contentType: 'application/zip');
      await ref.putFile(f, meta);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<bool> actualizarZipUrlProyecto({
    required String proyectoId,
    required String zipUrl,
  }) async {
    try {
      final idNum = int.parse(proyectoId);
      final body = {'zip_url': zipUrl, 'archivo_zip': zipUrl};
      final resp = await ServicioApi.patchJson('/proyectos/$idNum/zip', body);
      return (resp['updated'] ?? 0) > 0;
    } catch (e) {
      try {
        final qs = await FirebaseFirestore.instance
            .collectionGroup('proyectos')
            .where(FieldPath.documentId, isEqualTo: proyectoId)
            .get();
        if (qs.docs.isEmpty) return false;
        final ref = qs.docs.first.reference;
        await ref.update({'zip_url': zipUrl, 'archivo_zip': zipUrl});
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> sincronizarProyectoLocal(Proyecto p) async {
    try {
      final base = r'C:\Users\Angel\UNIVERSIDAD PRIVADA DE TACNA\SCRAPING - Documentos\proyectos';
      final dirBase = Directory(base);
      if (!dirBase.existsSync()) {
        dirBase.createSync(recursive: true);
      }
      String _slug(String s) {
        final a = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
        return a.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
      }
      final sub = Directory('$base\\concurso_${p.concursoId}\\${p.estudianteId}_${_slug(p.nombre)}');
      if (!sub.existsSync()) {
        sub.createSync(recursive: true);
      }
      final meta = {
        'estudiante_id': p.estudianteId,
        'nombre': p.nombre,
        'concurso_id': p.concursoId,
        'github_url': p.linkGithub,
        'zip_url': p.archivoZip,
        'fecha_envio': p.fechaEnvio.toIso8601String(),
      };
      File('${sub.path}\\metadata.json').writeAsStringSync(jsonEncode(meta));
      if (p.linkGithub.trim().isNotEmpty) {
        File('${sub.path}\\github.txt').writeAsStringSync(p.linkGithub.trim());
      }
      final zip = p.archivoZip.trim();
      if (zip.isNotEmpty) {
        try {
          final uri = Uri.parse(zip);
          final resp = await http.get(uri);
          if (resp.statusCode == 200) {
            File('${sub.path}\\proyecto.zip').writeAsBytesSync(resp.bodyBytes);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> sincronizarProyectosLocal(List<Proyecto> lista) async {
    for (final p in lista) {
      await sincronizarProyectoLocal(p);
    }
    try {
      if (lista.isEmpty) return;
      final base = r'C:\Users\Angel\UNIVERSIDAD PRIVADA DE TACNA\SCRAPING - Documentos\proyectos';
      final concursoId = lista.first.concursoId;
      final dirConcurso = Directory('$base\\concurso_${concursoId}');
      if (!dirConcurso.existsSync()) {
        dirConcurso.createSync(recursive: true);
      }
      final items = lista.map((p) {
        String _slug(String s) {
          final a = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
          return a.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
        }
        return {
          'estudiante_id': p.estudianteId,
          'nombre': p.nombre,
          'github_url': p.linkGithub,
          'zip_url': p.archivoZip,
          'carpeta': '${p.estudianteId}_${_slug(p.nombre)}',
        };
      }).toList();
      File('${dirConcurso.path}\\index.json').writeAsStringSync(jsonEncode(items));
    } catch (_) {}
  }

  Proyecto _desdeApi(Map<String, dynamic> row) {
    return Proyecto(
      id: (row['id']).toString(),
      nombre: (row['titulo'] ?? '') as String,
      linkGithub: (row['github_url'] ?? '') as String,
      archivoZip: (row['zip_url'] ?? '') as String,
      estudianteId: (row['estudiante_id']).toString(),
      nombreEstudiante: _composeName(
        row['estudiante_nombres'],
        row['estudiante_apellidos'],
      ),
      correoEstudiante: (row['estudiante_correo'] ?? '') as String,
      concursoId: (row['concurso_id']).toString(),
      categoriaId: (row['categoria_id']).toString(),
      fechaEnvio: DateTime.parse(
        (row['fecha_envio'] ?? DateTime.now().toIso8601String()) as String,
      ),
      estado: _mapEstado((row['estado'] ?? 'enviado') as String),
      comentarios: (row['comentarios'] ?? '') as String?,
      puntuacion: ((row['puntuacion'] ?? 0) as num).toDouble(),
    );
  }

  String _composeName(dynamic nombres, dynamic apellidos) {
    final n = (nombres ?? '').toString().trim();
    final a = (apellidos ?? '').toString().trim();
    return [n, a].where((s) => s.isNotEmpty).join(' ');
  }

  EstadoProyecto _mapEstado(String estadoStr) {
    switch (estadoStr.toLowerCase()) {
      case 'enviado':
        return EstadoProyecto.enviado;
      case 'en_revision':
        return EstadoProyecto.enRevision;
      case 'aprobado':
        return EstadoProyecto.aprobado;
      case 'rechazado':
        return EstadoProyecto.rechazado;
      case 'ganador':
        return EstadoProyecto.ganador;
      default:
        return EstadoProyecto.enviado;
    }
  }
}
