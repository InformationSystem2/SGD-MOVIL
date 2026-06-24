import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _keyApiUrl      = 'custom_api_url';
  static const String _keyFastapiUrl  = 'custom_fastapi_url';

  // ── URLs de producción ─────────────────────────────────────────────────────

  static String get _prodUrl =>
      dotenv.env['PROD_API_URL'] ??
      'https://si2-sgd-hc-backend-623982872710.southamerica-east1.run.app/api';

  static String get _prodFastapiUrl =>
      dotenv.env['PROD_FASTAPI_URL'] ??
      'https://si2-sgd-hc-ai-service-623982872710.southamerica-east1.run.app';

  // ── URLs por defecto para desarrollo ───────────────────────────────────────

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static String get defaultFastapiUrl {
    if (kIsWeb) return 'http://localhost:8001';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001';
    }
    return 'http://localhost:8001';
  }

  // ── Estado en memoria ──────────────────────────────────────────────────────

  static String _currentBaseUrl    = '';
  static String _currentFastapiUrl = '';

  static String get baseUrl    => _currentBaseUrl;
  static String get fastapiUrl => _currentFastapiUrl;

  // ── Inicialización ─────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (kReleaseMode) {
      _currentBaseUrl    = _prodUrl;
      _currentFastapiUrl = _prodFastapiUrl;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentBaseUrl    = prefs.getString(_keyApiUrl)     ?? defaultBaseUrl;
      _currentFastapiUrl = prefs.getString(_keyFastapiUrl) ?? defaultFastapiUrl;
    } catch (_) {
      _currentBaseUrl    = defaultBaseUrl;
      _currentFastapiUrl = defaultFastapiUrl;
    }
  }

  // ── Setters (solo debug/profile) ───────────────────────────────────────────

  static Future<void> setBaseUrl(String url) async {
    if (kReleaseMode) return;
    String formatted = _normalize(url);
    if (!formatted.endsWith('/api')) formatted = '$formatted/api';
    _currentBaseUrl = formatted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyApiUrl, formatted);
      // Actualiza FastAPI automáticamente derivando el puerto 8001
      final fastapiDerived = _derivesFastapiUrl(formatted);
      _currentFastapiUrl = fastapiDerived;
      await prefs.setString(_keyFastapiUrl, fastapiDerived);
    } catch (_) {}
  }

  static Future<void> setFastapiUrl(String url) async {
    if (kReleaseMode) return;
    _currentFastapiUrl = _normalize(url);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFastapiUrl, _currentFastapiUrl);
    } catch (_) {}
  }

  static Future<void> resetToDefault() async {
    if (kReleaseMode) return;
    _currentBaseUrl    = defaultBaseUrl;
    _currentFastapiUrl = defaultFastapiUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyApiUrl);
      await prefs.remove(_keyFastapiUrl);
    } catch (_) {}
  }

  // ── Helpers privados ───────────────────────────────────────────────────────

  static String _normalize(String url) {
    String s = url.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'http://$s';
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  /// Deriva la URL de FastAPI a partir de la URL de Spring Boot
  /// reemplazando el puerto 8080 por 8001 y quitando /api.
  /// Solo funciona para URLs con puerto explícito; de lo contrario usa el default.
  static String _derivesFastapiUrl(String springUrl) {
    final noApi = springUrl.replaceAll('/api', '');
    if (noApi.contains(':8080')) return noApi.replaceAll(':8080', ':8001');
    // Si no tiene puerto explícito no podemos derivarlo de forma segura
    return defaultFastapiUrl;
  }
}
