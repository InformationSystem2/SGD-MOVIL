import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import '../models/auth_models.dart';

class AuthService extends ChangeNotifier {
  final StorageService _storageService;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUser;

  AuthService(this._storageService) {
    _checkAutoLogin();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUser => _currentUser;

  /// Check if the user has a valid active session stored in SharedPreferences.
  Future<void> _checkAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    if (_storageService.hasValidSession) {
      _isAuthenticated = true;
      _currentUser = _storageService.username;
    } else {
      // Clear potentially expired tokens
      await _storageService.clearSession();
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login with username and password.
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(AuthRequest(username: username, password: password).toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final authResponse = AuthResponse.fromJson(data);

        await _storageService.saveSession(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          expiresInSeconds: authResponse.expiresIn,
          username: username,
        );

        _isAuthenticated = true;
        _currentUser = username;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        String msg = 'Credenciales incorrectas';
        try {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded is Map && decoded.containsKey('message')) {
            msg = decoded['message'];
          }
        } catch (_) {}
        _errorMessage = msg;
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión con el servidor. Verifique la dirección IP.';
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logs the user out and clears saved sessions.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    await _storageService.clearSession();
    _isAuthenticated = false;
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Resets the error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
