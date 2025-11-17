import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyectos_admin/servicios/servicio_proyectos.dart';
import 'package:proyectos_admin/modelos/proyecto.dart';

void main() {
  test('sincroniza proyecto a carpeta local', () async {
    final p = Proyecto(
      id: 'test1',
      nombre: 'Proyecto Demo',
      linkGithub: 'https://github.com/demo/demo',
      archivoZip: '',
      estudianteId: 'u123',
      nombreEstudiante: 'Demo',
      correoEstudiante: 'demo@example.com',
      concursoId: '1',
      categoriaId: 'cat',
      fechaEnvio: DateTime.now(),
      estado: EstadoProyecto.enviado,
    );

    await ServicioProyectos().sincronizarProyectoLocal(p);

    String slug(String s) {
      final a = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      return a.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    }

    final base = r'C:\\Users\\Angel\\UNIVERSIDAD PRIVADA DE TACNA\\SCRAPING - Documentos\\proyectos';
    final dir = Directory('$base\\concurso_${p.concursoId}\\${p.estudianteId}_${slug(p.nombre)}');
    expect(dir.existsSync(), true);
    final meta = File('${dir.path}\\metadata.json');
    expect(meta.existsSync(), true);
    final j = jsonDecode(meta.readAsStringSync()) as Map<String, dynamic>;
    expect(j['nombre'], 'Proyecto Demo');
    expect(j['github_url'], 'https://github.com/demo/demo');
  });
}
