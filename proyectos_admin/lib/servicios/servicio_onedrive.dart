import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart';
import '../modelos/proyecto.dart';
import '../config/onedrive_config.dart';

class ServicioOneDrive {
  static final ServicioOneDrive _i = ServicioOneDrive._();
  factory ServicioOneDrive() => _i;
  ServicioOneDrive._();

  String _clientId = '';
  String _redirectUri = '';
  String _authority = 'https://login.microsoftonline.com/common';
  String? _token;

  Future<void> inicializar({required String clientId, String authority = 'https://login.microsoftonline.com/common', String redirectUri = ''}) async {
    _clientId = clientId;
    _authority = authority;
    _redirectUri = redirectUri;
  }

  String _base64UrlNoPad(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<String?> _getToken() async {
    if (_token != null) return _token;
    final verifierBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final codeVerifier = _base64UrlNoPad(verifierBytes);
    final codeChallenge = _base64UrlNoPad(
      (await _sha256(utf8.encode(codeVerifier))),
    );
    final authUrl = Uri.parse('$_authority/oauth2/v2.0/authorize').replace(queryParameters: {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'response_mode': 'query',
      'scope': 'User.Read Files.ReadWrite offline_access',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });
    const channel = MethodChannel('app.channel/onedrive_auth');
    await channel.invokeMethod('launchAuth', {'url': authUrl.toString()});
    String? callback;
    final started = DateTime.now();
    while (DateTime.now().difference(started).inSeconds < 120) {
      callback = await channel.invokeMethod<String>('getAuthCallback');
      if (callback != null && callback.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (callback == null || callback.isEmpty) return null;
    await channel.invokeMethod('clearAuthCallback');
    final code = Uri.parse(callback).queryParameters['code'];
    if (code == null) return null;
    final tokenUrl = Uri.parse('$_authority/oauth2/v2.0/token');
    final body = {
      'client_id': _clientId,
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': _redirectUri,
      'code_verifier': codeVerifier,
      'scope': 'openid profile User.Read Files.ReadWrite offline_access',
    };
    final resp = await http.post(tokenUrl, headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _token = data['access_token'] as String?;
      return _token;
    }
    return null;
  }

  Future<List<int>> _sha256(List<int> input) async {
    final digest = crypto.sha256.convert(input);
    return digest.bytes;
  }

  Future<bool> _ensureSegment(String parentPath, String name, String token) async {
    String enc(String s) => s.split('/').map(Uri.encodeComponent).join('/');
    final p = parentPath.isEmpty ? name : '$parentPath/$name';
    final u = Uri.parse('https://graph.microsoft.com/v1.0/sites/'
        '$sharepointHost:${Uri.encodeComponent(sharepointSitePath)}/drive/root:/${enc(p)}');
    final r = await http.get(u, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 200) return true;
    final body = jsonEncode({'name': name, 'folder': {}, '@microsoft.graph.conflictBehavior': 'rename'});
    final url = parentPath.isEmpty
        ? Uri.parse('https://graph.microsoft.com/v1.0/sites/'
            '$sharepointHost:${Uri.encodeComponent(sharepointSitePath)}/drive/root/children')
        : Uri.parse('https://graph.microsoft.com/v1.0/sites/'
            '$sharepointHost:${Uri.encodeComponent(sharepointSitePath)}/drive/root:/${enc(parentPath)}:/children');
    final resp = await http.post(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: body);
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
    String enc(String s) => s.split('/').map(Uri.encodeComponent).join('/');
    final url = Uri.parse('https://graph.microsoft.com/v1.0/sites/'
        '$sharepointHost:${Uri.encodeComponent(sharepointSitePath)}/drive/root:/${enc(path)}/${Uri.encodeComponent(name)}:/content');
    final resp = await http.put(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'text/plain'}, body: content);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<bool> _uploadBytes(String path, String name, List<int> bytes, String token) async {
    String enc(String s) => s.split('/').map(Uri.encodeComponent).join('/');
    if (bytes.length <= 4 * 1024 * 1024) {
      final url = Uri.parse('https://graph.microsoft.com/v1.0/sites/'
          '$sharepointHost:${Uri.encodeComponent(sharepointSitePath)}/drive/root:/${enc(path)}/${Uri.encodeComponent(name)}:/content');
      final resp = await http.put(url, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/octet-stream'}, body: bytes);
      return resp.statusCode >= 200 && resp.statusCode < 300;
    }
    final sessionUrl = Uri.parse('https://graph.microsoft.com/v1.0/sites/'
        '$sharepointHost:${Uri.encodeComponent(sharepointSitePath)}/drive/root:/${enc(path)}/${Uri.encodeComponent(name)}:/createUploadSession');
    final sResp = await http.post(sessionUrl, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode({}));
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

  Future<bool> sincronizarProyectoOneDrive(Proyecto p, {String? localZipPath}) async {
    final token = await _getToken();
    if (token == null) return false;
    final base = sharepointBaseFolder;
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
    // Por ahora no se usa ZIP ni índice; sólo metadata y github.txt
    return true;
  }
}
