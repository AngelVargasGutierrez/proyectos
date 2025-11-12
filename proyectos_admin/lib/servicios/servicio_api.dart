import 'dart:convert';
import 'package:http/http.dart' as http;

class ServicioApi {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Uri _uri(String path, [Map<String, String>? query]) {
    final url = path.startsWith('/') ? '$baseUrl$path' : '$baseUrl/$path';
    return Uri.parse(url).replace(queryParameters: query);
  }

  static const Map<String, String> headersJson = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final res = await http.post(_uri(path), headers: headersJson, body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('POST $path fallo: ${res.statusCode} ${res.body}');
  }

  static Future<dynamic> getJson(String path, [Map<String, String>? query]) async {
    final res = await http.get(_uri(path, query));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception('GET $path fallo: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) async {
    final res = await http.patch(_uri(path), headers: headersJson, body: jsonEncode(body));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('PATCH $path fallo: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> deleteJson(String path) async {
    final res = await http.delete(_uri(path));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('DELETE $path fallo: ${res.statusCode} ${res.body}');
  }
}