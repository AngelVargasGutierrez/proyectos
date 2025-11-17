import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:msal_flutter/msal_flutter.dart';
import '../modelos/proyecto.dart';

abstract class OneDriveApi {
  Future<void> inicializar({required String clientId, String authority, String redirectUri});
  Future<bool> sincronizarProyectoOneDrive(Proyecto p, {String? localZipPath});
}

class OneDriveApiImpl implements OneDriveApi {
  MSALPublicClientApplication? _app;
  String? _token;

  @override
  Future<void> inicializar({required String clientId, String authority = 'https://login.microsoftonline.com/common', String redirectUri = 'msauth://proyectos_admin'}) async {
    _app = await MSALPublicClientApplication.createPublicClientApplication(
      MSALPublicClientApplicationConfiguration(
        clientId: clientId,
        authorities: [MSALAuthority(authorityURL: authority)],
        redirectUri: redirectUri,
      ),
    );
  }

  Future<String?> _getToken() async {
    if (_token != null) return _token;
    if (_app == null) return null;
    try {
      final scopes = ['User.Read', 'Files.ReadWrite', 'offline_access'];
      final result = await _app!.acquireTokenInteractive(scopes);
      _token = result.accessToken;
      return _token;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _ensureSegment(String parentPath, String name, String token) async {
    final p = parentPath.isEmpty ? name : '$parentPath/$name';
    final u = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root:/$p');
    final r = await http.get(u, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 200) return true;
    final body = jsonEncode({'name': name, 'folder': {}, '@microsoft.graph.conflictBehavior': 'rename'});
    final url = parentPath.isEmpty
        ? Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root/children')
        : Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root:/$parentPath:/children');
    final resp = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }, body: body);
    return resp.statusCode == 201 || resp.statusCode == 200;
  }

  Future<bool> _ensurePath(String path, String token) async {
    final segs = path.split('/').where((e) => e.isNotEmpty).toList();
    String parent = '';
    for (final s in segs) {
      final ok = await _ensureSegment(parent, s, token);
      if (!ok) return false;
      parent = parent.isEmpty ? s : '$parent/$s';
    }
    return true;
  }

  Future<bool> _uploadText(String path, String name, String content, String token) async {
    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root:/$path/$name:/content');
    final resp = await http.put(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'text/plain',
    }, body: content);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<bool> _uploadSmallBytes(String path, String name, List<int> bytes, String token) async {
    final url = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root:/$path/$name:/content');
    final resp = await http.put(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/octet-stream',
    }, body: bytes);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<bool> _uploadLarge(String path, String name, List<int> bytes, String token) async {
    final sessionUrl = Uri.parse('https://graph.microsoft.com/v1.0/me/drive/root:/$path/$name:/createUploadSession');
    final sResp = await http.post(sessionUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }, body: jsonEncode({}));
    if (sResp.statusCode < 200 || sResp.statusCode >= 300) return false;
    final uploadUrl = (jsonDecode(sResp.body) as Map<String, dynamic>)['uploadUrl'] as String;
    final chunk = 5 * 1024 * 1024;
    int start = 0;
    while (start < bytes.length) {
      final end = (start + chunk > bytes.length) ? bytes.length : start + chunk;
      final slice = bytes.sublist(start, end);
      final headers = {
        'Content-Length': slice.length.toString(),
        'Content-Range': 'bytes $start-${end - 1}/${bytes.length}',
      };
      final resp = await http.put(Uri.parse(uploadUrl), headers: headers, body: slice);
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        break;
      } else if (resp.statusCode != 202) {
        return false;
      }
      start = end;
    }
    return true;
  }

  @override
  Future<bool> sincronizarProyectoOneDrive(Proyecto p, {String? localZipPath}) async {
    final token = await _getToken();
    if (token == null) return false;
    final base = 'UNIVERSIDAD PRIVADA DE TACNA/SCRAPING - Documentos/proyectos';
    final slug = p.nombre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    final concursoPath = '$base/concurso_${p.concursoId}';
    final path = '$concursoPath/${p.estudianteId}_$slug';
    final okBase = await _ensurePath(concursoPath, token);
    if (!okBase) return false;
    final okPath = await _ensurePath(path, token);
    if (!okPath) return false;
    final meta = jsonEncode({
      'estudiante_id': p.estudianteId,
      'nombre': p.nombre,
      'concurso_id': p.concursoId,
      'github_url': p.linkGithub,
      'zip_url': p.archivoZip,
      'fecha_envio': p.fechaEnvio.toIso8601String(),
    });
    final mOk = await _uploadText(path, 'metadata.json', meta, token);
    if (!mOk) return false;
    if (p.linkGithub.trim().isNotEmpty) {
      await _uploadText(path, 'github.txt', p.linkGithub.trim(), token);
    }
    List<int>? data;
    String name = 'proyecto.zip';
    if (localZipPath != null && localZipPath.isNotEmpty) {
      final f = File(localZipPath);
      if (f.existsSync()) {
        data = await f.readAsBytes();
      }
    }
    if (data == null && p.archivoZip.trim().isNotEmpty) {
      try {
        final resp = await http.get(Uri.parse(p.archivoZip.trim()));
        if (resp.statusCode == 200) {
          data = resp.bodyBytes;
        }
      } catch (_) {}
    }
    if (data != null) {
      if (data.length <= 4 * 1024 * 1024) {
        await _uploadSmallBytes(path, name, data, token);
      } else {
        await _uploadLarge(path, name, data, token);
      }
    }
    return true;
  }
}
