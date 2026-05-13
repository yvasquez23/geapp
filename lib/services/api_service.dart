import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _tokenKey = 'jwt_token';

  // ── Token ─────────────────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Headers con JWT ───────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── GET ───────────────────────────────────────────────────────────────────────
  static Future<http.Response> get(String url,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final headers = await _authHeaders();
    return http.get(uri, headers: headers);
  }

  // ── POST ──────────────────────────────────────────────────────────────────────
  static Future<http.Response> post(String url, Map<String, dynamic> body,
      {bool auth = true}) async {
    final headers = auth ? await _authHeaders() : {'Content-Type': 'application/json'};
    return http.post(Uri.parse(url),
        headers: headers, body: jsonEncode(body));
  }

  // ── PUT ───────────────────────────────────────────────────────────────────────
  static Future<http.Response> put(String url, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.put(Uri.parse(url),
        headers: headers, body: jsonEncode(body));
  }

  // ── DELETE ────────────────────────────────────────────────────────────────────
  static Future<http.Response> delete(String url) async {
    final headers = await _authHeaders();
    return http.delete(Uri.parse(url), headers: headers);
  }
}
