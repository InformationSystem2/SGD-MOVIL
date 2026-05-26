import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyExpiresAt = 'expires_at';
  static const String _keyUsername = 'username';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
    required String username,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));
    
    await _prefs.setString(_keyAccessToken, accessToken);
    await _prefs.setString(_keyRefreshToken, refreshToken);
    await _prefs.setInt(_keyExpiresAt, expiresAt.millisecondsSinceEpoch);
    await _prefs.setString(_keyUsername, username);
  }

  String? get accessToken => _prefs.getString(_keyAccessToken);
  String? get refreshToken => _prefs.getString(_keyRefreshToken);
  String? get username => _prefs.getString(_keyUsername);

  DateTime? get expiresAt {
    final ms = _prefs.getInt(_keyExpiresAt);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  bool get hasValidSession {
    final token = accessToken;
    final expiry = expiresAt;
    if (token == null || expiry == null) return false;
    // Session is valid if it has more than 1 minute remaining
    return expiry.isAfter(DateTime.now().add(const Duration(minutes: 1)));
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyExpiresAt);
    await _prefs.remove(_keyUsername);
  }
}
