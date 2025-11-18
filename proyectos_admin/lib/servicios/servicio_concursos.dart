import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelos/concurso.dart';
import '../modelos/categoria.dart';
import 'servicio_autenticacion.dart';

class ServicioConcursos {
  static final ServicioConcursos _instancia = ServicioConcursos._interno();
  factory ServicioConcursos() => _instancia;
  ServicioConcursos._interno();

  List<Concurso> get concursos => const [];

  Future<bool> crearConcurso({
    required String nombre,
    required List<Categoria> categorias,
    required DateTime fechaLimiteInscripcion,
    required DateTime fechaRevision,
    required DateTime fechaConfirmacionAceptados,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final correo =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
    if (uid == null) return false;

    try {
      final concursosCol = FirebaseFirestore.instance.collection('concursos');
      final concursoRef = concursosCol.doc();
      await concursoRef.set({
        'nombre': nombre.trim(),
        'admin_uid': uid,
        'fecha_limite_inscripcion': Timestamp.fromDate(fechaLimiteInscripcion),
        'fecha_revision': Timestamp.fromDate(fechaRevision),
        'fecha_confirmacion_aceptados': Timestamp.fromDate(
          fechaConfirmacionAceptados,
        ),
        'fecha_creacion': FieldValue.serverTimestamp(),
      });

      final categoriasCol = concursoRef.collection('categorias');
      for (final cat in categorias) {
        final nombres = cat.juradosAsignados;
        final uids = await _resolverUidsJurados(nombres);
        await categoriasCol.add({
          'nombre': cat.nombre.trim(),
          'rango_ciclos': cat.rangoCiclos.trim(),
          'jurados_asignados': nombres,
          'jurados_asignados_uids': uids,
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Concurso>> obtenerConcursos() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('concursos')
          .orderBy('fecha_creacion', descending: true)
          .get();
      final concursos = <Concurso>[];
      for (final doc in qs.docs) {
        final data = doc.data();
        List<Categoria> categorias = [];
        try {
          final cats = await doc.reference.collection('categorias').get();
          categorias = cats.docs
              .map(
                (c) => Categoria(
                  nombre: (c.data()['nombre'] ?? '') as String,
                  rangoCiclos: (c.data()['rango_ciclos'] ?? '') as String,
                  juradosAsignados:
                      ((c.data()['jurados_asignados'] ?? []) as List)
                          .map((e) => e.toString())
                          .toList(),
                ),
              )
              .toList();
        } catch (_) {
          categorias = [];
        }
        concursos.add(
          Concurso(
            id: doc.id,
            nombre: (data['nombre'] ?? '') as String,
            categorias: categorias,
            fechaLimiteInscripcion:
                (data['fecha_limite_inscripcion'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            fechaRevision:
                (data['fecha_revision'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            fechaConfirmacionAceptados:
                (data['fecha_confirmacion_aceptados'] as Timestamp?)
                    ?.toDate() ??
                DateTime.now(),
            fechaCreacion:
                (data['fecha_creacion'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            administradorId: (data['admin_uid'] ?? '') as String,
          ),
        );
      }
      return concursos;
    } catch (e) {
      return [];
    }
  }

  Future<List<Concurso>> obtenerConcursosDelAdministrador() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final qs = await FirebaseFirestore.instance
          .collection('concursos')
          .where('admin_uid', isEqualTo: uid)
          .get();
      final concursos = <Concurso>[];
      for (final doc in qs.docs) {
        final data = doc.data();
        List<Categoria> categorias = [];
        try {
          final cats = await doc.reference.collection('categorias').get();
          categorias = cats.docs
              .map(
                (c) => Categoria(
                  nombre: (c.data()['nombre'] ?? '') as String,
                  rangoCiclos: (c.data()['rango_ciclos'] ?? '') as String,
                  juradosAsignados:
                      ((c.data()['jurados_asignados'] ?? []) as List)
                          .map((e) => e.toString())
                          .toList(),
                ),
              )
              .toList();
        } catch (_) {
          categorias = [];
        }
        concursos.add(
          Concurso(
            id: doc.id,
            nombre: (data['nombre'] ?? '') as String,
            categorias: categorias,
            fechaLimiteInscripcion:
                (data['fecha_limite_inscripcion'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            fechaRevision:
                (data['fecha_revision'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            fechaConfirmacionAceptados:
                (data['fecha_confirmacion_aceptados'] as Timestamp?)
                    ?.toDate() ??
                DateTime.now(),
            fechaCreacion:
                (data['fecha_creacion'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            administradorId: (data['admin_uid'] ?? '') as String,
          ),
        );
      }
      concursos.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      return concursos;
    } catch (e) {
      return [];
    }
  }

  Future<bool> actualizarConcurso({
    required String concursoId,
    required String nombre,
    required List<Categoria> categorias,
    required DateTime fechaLimiteInscripcion,
    required DateTime fechaRevision,
    required DateTime fechaConfirmacionAceptados,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final correo =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
    if (uid == null) return false;

    try {
      final ref = FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId);
      await ref.update({
        'nombre': nombre.trim(),
        'fecha_limite_inscripcion': Timestamp.fromDate(fechaLimiteInscripcion),
        'fecha_revision': Timestamp.fromDate(fechaRevision),
        'fecha_confirmacion_aceptados': Timestamp.fromDate(
          fechaConfirmacionAceptados,
        ),
      });

      // Reemplazar categorías: borrar existentes y crear nuevas
      final cats = await ref.collection('categorias').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in cats.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      final nuevas = ref.collection('categorias');
      for (final cat in categorias) {
        final nombres = cat.juradosAsignados;
        final uids = await _resolverUidsJurados(nombres);
        await nuevas.add({
          'nombre': cat.nombre.trim(),
          'rango_ciclos': cat.rangoCiclos.trim(),
          'jurados_asignados': nombres,
          'jurados_asignados_uids': uids,
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> eliminarConcurso(String concursoId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final ref = FirebaseFirestore.instance
          .collection('concursos')
          .doc(concursoId);
      // Borrar subcolecciones (categorias)
      final cats = await ref.collection('categorias').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in cats.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

Future<List<String>> _resolverUidsJurados(List<String> nombres) async {
  final result = <String>[];
  final norm = nombres.map((n) => n.trim().toUpperCase()).toList();
  try {
    // Cargar solo de colección 'jurados' unificada
    final coll = await FirebaseFirestore.instance.collection('jurados').get();
    for (final d in coll.docs) {
      final data = d.data();
      final nombre = ((data['nombre'] ?? data['nombres'] ?? '') as String)
          .toUpperCase();
      final apellidos = ((data['apellidos'] ?? '') as String).toUpperCase();
      final completo = [
        nombre,
        apellidos,
      ].where((s) => s.isNotEmpty).join(' ').trim();
      if (norm.contains(completo)) result.add(d.id);
    }
  } catch (_) {}
  return result;
}
