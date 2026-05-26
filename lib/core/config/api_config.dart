import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _keyApiUrl = 'custom_api_url';
  
  // Default base URL depending on platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Default to Android Emulator host IP pointing to machine localhost
      return 'http://10.0.2.2:8080/api';
    } else {
      // For Linux, macOS, Windows desktops, and iOS simulators running on host machine
      return 'http://localhost:8080/api';
    }
  }

  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl;

  /// Loads custom base URL if saved in preferences, otherwise defaults to platform default.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentBaseUrl = prefs.getString(_keyApiUrl) ?? defaultBaseUrl;
    } catch (e) {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  /// Sets and persists a new base URL.
  static Future<void> setBaseUrl(String url) async {
    // Basic formatting
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'http://$formattedUrl';
    }
    if (formattedUrl.endsWith('/')) {
      formattedUrl = formattedUrl.substring(0, formattedUrl.length - 1);
    }
    if (!formattedUrl.endsWith('/api')) {
      formattedUrl = '$formattedUrl/api';
    }

    _currentBaseUrl = formattedUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyApiUrl, formattedUrl);
    } catch (_) {
      // SharedPreferences error ignored in tests
    }
  }

  /// Reset to the platform default
  static Future<void> resetToDefault() async {
    _currentBaseUrl = defaultBaseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyApiUrl);
    } catch (_) {}
  }
}
