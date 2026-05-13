import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _usuario;
  String? _correo;
  int? _usuarioId;
  String? _errorMessage;

  bool get isLoading       => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get usuario      => _usuario;
  String? get correo       => _correo;
  int? get usuarioId       => _usuarioId;
  String? get errorMessage => _errorMessage;

  // Verificar si ya hay token al abrir la app
  Future<void> checkToken() async {
    final token = await ApiService.getToken();
    _isAuthenticated = token != null;
    notifyListeners();
  }

  Future<bool> login(String correo, String contrasena) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.login(correo, contrasena);

    _isLoading = false;
    if (result.success) {
      _isAuthenticated = true;
      _usuario         = result.usuario;
      _correo          = result.correo;
      _usuarioId       = result.usuarioId;
    } else {
      _errorMessage = result.error;
    }
    notifyListeners();
    return result.success;
  }

  Future<bool> registro(
      String usuario, String correo, String contrasena) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.registro(usuario, correo, contrasena);

    _isLoading = false;
    if (result.success) {
      _isAuthenticated = true;
      _usuario         = result.usuario;
      _correo          = result.correo;
      _usuarioId       = result.usuarioId;
    } else {
      _errorMessage = result.error;
    }
    notifyListeners();
    return result.success;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _usuario         = null;
    _correo          = null;
    _usuarioId       = null;
    notifyListeners();
  }
}
