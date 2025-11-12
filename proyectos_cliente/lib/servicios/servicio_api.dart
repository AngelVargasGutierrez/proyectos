import 'dart:convert';
import 'package:http/http.dart' as http;

class ServicioApi {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  static Future<dynamic> getJson(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final resp = await http.get(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body);
    }
    throw Exception('GET $path fallo: ${resp.statusCode}');
  }

  static Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body);
    }
    throw Exception('POST $path fallo: ${resp.statusCode}');
  }

  static Future<dynamic> patchJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final resp = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body);
    }
    throw Exception('PATCH $path fallo: ${resp.statusCode}');
  }

  static Future<dynamic> deleteJson(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final resp = await http.delete(uri);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body);
    }
    throw Exception('DELETE $path fallo: ${resp.statusCode}');
  }
}