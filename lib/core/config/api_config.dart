import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _keyApiUrl = 'custom_api_url';

  /// URL de producción leída del .env — solo se usa en release builds.
  static String get _prodUrl =>
      dotenv.env['PROD_API_URL'] ??
      'https://si2-sgd-hc-backend-623982872710.southamerica-east1.run.app/api';

  /// URL por defecto para desarrollo según plataforma.
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static String _currentBaseUrl = '';

  static String get baseUrl => _currentBaseUrl;

  /// En release siempre usa la URL del .env.
  /// En debug/profile carga la URL guardada por el usuario (o el default).
  static Future<void> init() async {
    if (kReleaseMode) {
      _currentBaseUrl = _prodUrl;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentBaseUrl = prefs.getString(_keyApiUrl) ?? defaultBaseUrl;
    } catch (_) {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  /// Solo disponible en modo debug/profile.
  static Future<void> setBaseUrl(String url) async {
    if (kReleaseMode) return;
    String formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (!formatted.endsWith('/api')) {
      formatted = '$formatted/api';
    }
    _currentBaseUrl = formatted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyApiUrl, formatted);
    } catch (_) {}
  }

  /// Solo disponible en modo debug/profile.
  static Future<void> resetToDefault() async {
    if (kReleaseMode) return;
    _currentBaseUrl = defaultBaseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyApiUrl);
    } catch (_) {}
  }
}
