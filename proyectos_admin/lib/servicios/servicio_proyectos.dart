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
        final catMap = <String, String>{};
        try {
          final catsSnap = await FirebaseFirestore.instance
              .collection('concursos')
              .doc(concursoId)
              .collection('categorias')
              .get();
          for (final c in catsSnap.docs) {
            final cd = c.data();
            final nombre = (cd['nombre'] ?? '') as String;
            if (nombre.isNotEmpty) catMap[c.id] = nombre;
          }
        } catch (_) {}
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

            // Resolver nombre de categoría con múltiples fuentes
            String catId = (data['categoria_id'] ?? '') as String;
            if (catId.isEmpty) {
              final parts = doc.id.split('-');
              if (parts.isNotEmpty) catId = parts.first;
            }
            String? catNombre = catMap[catId];
            if (catNombre == null || catNombre.isEmpty) {
              try {
                final cDoc = await FirebaseFirestore.instance
                    .collection('concursos')
                    .doc(concursoId)
                    .collection('categorias')
                    .doc(catId)
                    .get();
                final cData = cDoc.data() ?? <String, dynamic>{};
                final nombre = (cData['nombre'] ?? '') as String;
                if (nombre.isNotEmpty) catNombre = nombre;
              } catch (_) {}
              // Fallback adicional: si solo existe una categoría en el concurso, usar esa
              if ((catNombre == null || catNombre.isEmpty) && catMap.length == 1) {
                catNombre = catMap.values.first;
              }
              // Fallback: si el proyecto ya guarda el nombre en texto
              if (catNombre == null || catNombre.isEmpty) {
                final catTexto = ((data['categoria'] ?? data['categoria_nombre'] ?? '') as String).trim();
                if (catTexto.isNotEmpty) catNombre = catTexto;
              }
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
              categoriaId: catId,
              categoriaNombre: (catNombre != null && catNombre.isNotEmpty) ? catNombre : null,
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
      // Verificar asignación del jurado a la categoría
      DocumentReference<Map<String, dynamic>> refCategoria = FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId)
          .collection('categorias')
          .doc(categoriaId);
      DocumentSnapshot<Map<String, dynamic>> catSnap = await refCategoria.get();
      Map<String, dynamic> catData = catSnap.data() ?? <String, dynamic>{};
      var asignadosUids = ((catData['jurados_asignados_uids'] ?? []) as List)
          .map((e) => e.toString())
          .toList();
      var asignadosNombres = ((catData['jurados_asignados'] ?? []) as List)
          .map((e) => e.toString().toUpperCase().trim())
          .toList();
      var asignadosCorreos = ((catData['jurados_asignados_correos'] ?? []) as List)
          .map((e) => e.toString().toLowerCase().trim())
          .toList();

      // Fallback robusto: si la categoría no existe o no tiene asignaciones, intentar resolver el ID correcto
      if ((asignadosUids.isEmpty && asignadosNombres.isEmpty && asignadosCorreos.isEmpty) || !catSnap.exists) {
        final refProyectoTmp = FirebaseFirestore.instance
            .collection('concursos')
            .doc(concursoId)
            .collection('proyectos')
            .doc(proyectoId);
        final pSnap = await refProyectoTmp.get();
        final pData = pSnap.data() ?? <String, dynamic>{};
        String catId2 = (pData['categoria_id'] ?? '').toString();
        if (catId2.isEmpty) {
          final parts = proyectoId.split('-');
          if (parts.isNotEmpty) catId2 = parts.first;
        }
        if (catId2.isEmpty) {
          final nombreCat = ((pData['categoria_nombre'] ?? '') as String).trim();
          if (nombreCat.isNotEmpty) {
            final catsAll = await FirebaseFirestore.instance
                .collection('concursos')
                .doc(concursoId)
                .collection('categorias')
                .get();
            for (final c in catsAll.docs) {
              final cd = c.data();
              final nom = ((cd['nombre'] ?? '') as String).trim();
              if (nom == nombreCat) {
                catId2 = c.id;
                break;
              }
            }
          }
        }
        if (catId2.isNotEmpty) {
          refCategoria = FirebaseFirestore.instance
              .collection('concursos')
              .doc(concursoId)
              .collection('categorias')
              .doc(catId2);
          catSnap = await refCategoria.get();
          catData = catSnap.data() ?? <String, dynamic>{};
          asignadosUids = ((catData['jurados_asignados_uids'] ?? []) as List)
              .map((e) => e.toString())
              .toList();
          asignadosNombres = ((catData['jurados_asignados'] ?? []) as List)
              .map((e) => e.toString().toUpperCase().trim())
              .toList();
          asignadosCorreos = ((catData['jurados_asignados_correos'] ?? []) as List)
              .map((e) => e.toString().toLowerCase().trim())
              .toList();
        }
      }
      bool autorizado = false;
      if (asignadosUids.isNotEmpty) {
        autorizado = asignadosUids.contains(juradoUid);
      }
      if (!autorizado && (asignadosCorreos.isNotEmpty || asignadosNombres.isNotEmpty)) {
        DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
            .instance
            .collection('jurados')
            .doc(juradoUid)
            .get();
        if (!doc.exists) {
          doc = await FirebaseFirestore.instance
              .collection('jurado')
              .doc(juradoUid)
              .get();
        }
        final jd = doc.data() ?? <String, dynamic>{};
        final nombre = (jd['nombre'] ?? jd['nombres'] ?? '')
            .toString()
            .toUpperCase()
            .trim();
        final apellidos = (jd['apellidos'] ?? '')
            .toString()
            .toUpperCase()
            .trim();
        final completo = [nombre, apellidos]
            .where((s) => s.isNotEmpty)
            .join(' ')
            .trim();
        final correo = (jd['correo'] ?? jd['email'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        if (correo.isNotEmpty && asignadosCorreos.contains(correo)) {
          autorizado = true;
        }
        if (completo.isNotEmpty) {
          autorizado = asignadosNombres.contains(completo);
        }
      }
      if (!autorizado) {
        return false;
      }

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
      final asignadosUids2 = (catData['jurados_asignados_uids'] ?? []) as List?;
      final asignadosNombres2 = (catData['jurados_asignados'] ?? []) as List?;
      final asignadosCorreos2 = (catData['jurados_asignados_correos'] ?? []) as List?;
      int totalAsignados = 0;
      if (asignadosUids2 != null && asignadosUids2.isNotEmpty) {
        totalAsignados = asignadosUids2.length;
      } else if (asignadosNombres2 != null && asignadosNombres2.isNotEmpty) {
        totalAsignados = asignadosNombres2.length;
      } else if (asignadosCorreos2 != null && asignadosCorreos2.isNotEmpty) {
        totalAsignados = asignadosCorreos2.length;
      }
      final votosRecibidos = evals.length;
      await refProyecto.update({
        'votos_recibidos': votosRecibidos,
        'votos_asignados': totalAsignados,
      });

      // Solo declarar ganador cuando hayan votado TODOS los jurados asignados
      final requeridos = totalAsignados;
      if (requeridos > 0 && votosRecibidos >= requeridos) {
        final qsCategoria = await FirebaseFirestore.instance
            .collection('concursos')
            .doc(concursoId)
            .collection('proyectos')
            .where('categoria_id', isEqualTo: categoriaId)
            .get();

        if (qsCategoria.docs.isNotEmpty) {
          bool todosCompletos = true;
          for (final d in qsCategoria.docs) {
            final pd = d.data();
            final vr = ((pd['votos_recibidos'] ?? 0) as num).toInt();
            if (vr < requeridos) {
              todosCompletos = false;
              break;
            }
          }

          if (todosCompletos) {
            String? ganadorId;
            double maxP = -1;
            for (final d in qsCategoria.docs) {
              final pd = d.data();
              double p = ((pd['puntuacion'] ?? 0) as num).toDouble();
              if (p <= 0) {
                final evalsPd = ((pd['evaluaciones_jurado'] ?? <String, dynamic>{}) as Map<String, dynamic>);
                if (evalsPd.isNotEmpty) {
                  double s = 0;
                  int c = 0;
                  evalsPd.forEach((_, v) {
                    final m = (v ?? <String, dynamic>{}) as Map<String, dynamic>;
                    final t = ((m['total'] ?? 0) as num).toDouble();
                    final n = (t / 28.0) * 20.0;
                    s += n;
                    c += 1;
                  });
                  p = c > 0 ? (s / c) : 0.0;
                }
              }
              if (p > maxP) {
                maxP = p;
                ganadorId = d.id;
              }
            }
            if (ganadorId != null && maxP > 0) {
              for (final d in qsCategoria.docs) {
                final nuevoEstado = d.id == ganadorId ? 'ganador' : (pdEstado(d.data()) == 'ganador' ? 'aprobado' : null);
                if (nuevoEstado != null) {
                  await d.reference.update({'estado': nuevoEstado});
                }
              }
              await FirebaseFirestore.instance
                  .collection('concursos')
                  .doc(concursoId)
                  .collection('proyectos')
                  .doc(ganadorId)
                  .update({'puntuacion_ganador': maxP});
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
        String nombreCategoria = '';
        try {
          final catDoc = await FirebaseFirestore.instance
              .collection('concursos')
              .doc(concursoId)
              .collection('categorias')
              .doc(categoriaId)
              .get();
          final cd = catDoc.data() ?? <String, dynamic>{};
          nombreCategoria = (cd['nombre'] ?? '') as String;
        } catch (_) {}
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
            categoriaNombre: nombreCategoria.isNotEmpty
                ? nombreCategoria
                : (((data['categoria'] ?? data['categoria_nombre'] ?? '') as String).trim().isNotEmpty
                    ? ((data['categoria'] ?? data['categoria_nombre'] ?? '') as String).trim()
                    : null),
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
        return Future.wait(qs.docs.map((doc) async {
          final data = doc.data();
          DateTime _parseFecha(dynamic v) {
            if (v is Timestamp) return v.toDate();
            if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
            return DateTime.now();
          }

          final concursoIdFs = (data['concurso_id'] ?? (doc.reference.parent.parent?.id ?? '')) as String;
          String catId = (data['categoria_id'] ?? '') as String;
          if (catId.isEmpty) {
            final parts = doc.id.split('-');
            if (parts.isNotEmpty) catId = parts.first;
          }
          String? catNombre;
          if (concursoIdFs.isNotEmpty && catId.isNotEmpty) {
            try {
              final cDoc = await FirebaseFirestore.instance
                  .collection('concursos')
                  .doc(concursoIdFs)
                  .collection('categorias')
                  .doc(catId)
                  .get();
              final cData = cDoc.data() ?? <String, dynamic>{};
              final nombre = (cData['nombre'] ?? '') as String;
              if (nombre.isNotEmpty) catNombre = nombre;
            } catch (_) {}
          }
          if (catNombre == null || catNombre.isEmpty) {
            final texto = ((data['categoria'] ?? data['categoria_nombre'] ?? '') as String).trim();
            if (texto.isNotEmpty) catNombre = texto;
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
            concursoId: concursoIdFs,
            categoriaId: catId,
            categoriaNombre: (catNombre != null && catNombre.isNotEmpty) ? catNombre : null,
            fechaEnvio: _parseFecha(data['fecha_envio']),
            estado: _mapEstado(((data['estado'] ?? 'enviado') as String)),
            comentarios: (data['comentarios'] ?? '') as String?,
            puntuacion: ((data['puntuacion'] ?? 0) as num).toDouble(),
          );
        }));
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

  Future<int> completarCategoriaNombreConcurso(String concursoId) async {
    try {
      final catMap = <String, String>{};
      final catsSnap = await FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId)
          .collection('categorias')
          .get();
      for (final c in catsSnap.docs) {
        final cd = c.data();
        final nombre = (cd['nombre'] ?? '') as String;
        if (nombre.isNotEmpty) catMap[c.id] = nombre;
      }
      if (catMap.isEmpty) return 0;
      final projs = await FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId)
          .collection('proyectos')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      int updates = 0;
      for (final d in projs.docs) {
        final data = d.data();
        String catId = (data['categoria_id'] ?? '') as String;
        if (catId.isEmpty) {
          final parts = d.id.split('-');
          if (parts.isNotEmpty) catId = parts.first;
        }
        String nombre = '';
        if (catId.isNotEmpty && catMap.containsKey(catId)) {
          nombre = catMap[catId] ?? '';
        }
        if (nombre.isEmpty) {
          final texto = ((data['categoria'] ?? data['categoria_nombre'] ?? '') as String).trim();
          if (texto.isNotEmpty) nombre = texto;
        }
        if (nombre.isEmpty) continue;
        final actual = ((data['categoria_nombre'] ?? '') as String).trim();
        if (actual != nombre) {
          batch.update(d.reference, {'categoria_nombre': nombre});
          updates++;
        }
      }
      if (updates > 0) await batch.commit();
      return updates;
    } catch (_) {
      return 0;
    }
  }

  Future<int> normalizarCamposProyectosConcurso(String concursoId) async {
    try {
      int updates = 0;
      final qs = await FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId)
          .collection('proyectos')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in qs.docs) {
        final data = d.data();
        final patch = <String, dynamic>{};
        if (data['equipo_correos'] == null) patch['equipo_correos'] = [];
        if (data['equipo_ms_uids'] == null) patch['equipo_ms_uids'] = [];
        if (data['equipo_lider_uid'] == null) patch['equipo_lider_uid'] = '';
        if (data['equipo_lider_correo'] == null) patch['equipo_lider_correo'] = '';
        if (data['aval_url'] == null) patch['aval_url'] = '';
        if (data['aval_base64'] == null) patch['aval_base64'] = '';
        if (data['aval_mime'] == null) patch['aval_mime'] = '';
        if (data['aval_nombre'] == null) patch['aval_nombre'] = '';
        if (patch.isNotEmpty) {
          batch.update(d.reference, patch);
          updates++;
        }
      }
      if (updates > 0) await batch.commit();
      return updates;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> diagnosticoCategoriasConcurso(String concursoId) async {
    final resultado = <String, dynamic>{};
    try {
      final catMap = <String, String>{};
      final catsSnap = await FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId)
          .collection('categorias')
          .get();
      for (final c in catsSnap.docs) {
        final cd = c.data();
        final nombre = (cd['nombre'] ?? '') as String;
        if (nombre.isNotEmpty) catMap[c.id] = nombre;
      }
      resultado['categorias'] = catMap;
      final projs = await FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId)
          .collection('proyectos')
          .get();
      final sinCatId = <String>[];
      final catIdNoExiste = <String, String>{};
      final sinCatNombre = <String, String>{};
      for (final d in projs.docs) {
        final data = d.data();
        String catId = (data['categoria_id'] ?? '') as String;
        if (catId.isEmpty) {
          final parts = d.id.split('-');
          if (parts.isNotEmpty) catId = parts.first;
        }
        if (catId.isEmpty) {
          sinCatId.add(d.id);
          continue;
        }
        if (!catMap.containsKey(catId)) {
          catIdNoExiste[d.id] = catId;
        }
        final nombre = ((data['categoria_nombre'] ?? '') as String).trim();
        if (nombre.isEmpty) {
          sinCatNombre[d.id] = catMap[catId] ?? '';
        }
      }
      resultado['proyectos_sin_categoria_id'] = sinCatId;
      resultado['proyectos_catid_no_existe'] = catIdNoExiste;
      resultado['proyectos_sin_categoria_nombre'] = sinCatNombre;
      return resultado;
    } catch (e) {
      resultado['error'] = e.toString();
      return resultado;
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
