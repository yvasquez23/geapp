import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthResult {
  final bool success;
  final String? token;
  final int? usuarioId;
  final String? usuario;
  final String? correo;
  final String? error;

  AuthResult({
    required this.success,
    this.token,
    this.usuarioId,
    this.usuario,
    this.correo,
    this.error,
  });
}

class AuthService {
  static Future<AuthResult> login(String correo, String contrasena) async {
    try {
      final response = await ApiService.post(
        ApiConfig.login,
        {'correo': correo, 'contraseña': contrasena},
        auth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.saveToken(data['token']);
        return AuthResult(
          success:    true,
          token:      data['token'],
          usuarioId:  data['usuario_id'],
          usuario:    data['usuario'],
          correo:     data['correo'],
        );
      } else if (response.statusCode == 401) {
        return AuthResult(success: false, error: 'Credenciales inválidas');
      } else if (response.statusCode == 429) {
        return AuthResult(success: false, error: 'Demasiados intentos. Espera un momento.');
      } else {
        return AuthResult(success: false, error: 'Error del servidor (${response.statusCode})');
      }
    } catch (e) {
      return AuthResult(success: false, error: 'No se pudo conectar al servidor');
    }
  }

  static Future<AuthResult> registro(
      String usuario, String correo, String contrasena) async {
    try {
      final response = await ApiService.post(
        ApiConfig.registro,
        {'usuario': usuario, 'correo': correo, 'contraseña': contrasena},
        auth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.saveToken(data['token']);
        return AuthResult(
          success:   true,
          token:     data['token'],
          usuarioId: data['usuario_id'] ?? data['usuarioId'],
          usuario:   data['usuario'],
          correo:    data['correo'],
        );
      } else {
        String msg = 'Error al registrarse (${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          msg = data['message'] ?? msg;
        } catch (_) {}
        return AuthResult(success: false, error: msg);
      }
    } catch (e) {
      return AuthResult(success: false, error: 'No se pudo conectar al servidor');
    }
  }

  static Future<void> logout() async {
    await ApiService.clearToken();
  }
}
