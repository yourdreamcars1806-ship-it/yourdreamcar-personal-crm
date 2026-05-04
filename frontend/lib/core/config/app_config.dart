import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend base URL resolution order:
/// 1) Compile-time `--dart-define=API_BASE_URL=...` (production builds)
/// 2) Value saved on Login screen (`SharedPreferences`)
/// 3) Platform default (`10.0.2.2` Android emulator → host PC, etc.)
class AppConfig {
  AppConfig._();

  static const _prefsKey = 'api_base_url';

  static String? _persistedUrl;

  /// Call from `main()` before [runApp] so first HTTP requests see saved URL.
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey)?.trim();
      _persistedUrl = raw != null && raw.isNotEmpty ? normalizeBaseUrl(raw) : null;
    } catch (_) {
      _persistedUrl = null;
    }
  }

  static String normalizeBaseUrl(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return '';
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// `dart-define` wins over saved prefs (for baked release URLs).
  static bool get hasCompiledApiUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return fromEnv.trim().isNotEmpty;
  }

  static bool get hasSavedServerOverride =>
      _persistedUrl != null && _persistedUrl!.isNotEmpty;

  static String _platformFallback() {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  /// Active URL for all API calls.
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final compiled = fromEnv.trim();
    if (compiled.isNotEmpty) {
      return normalizeBaseUrl(compiled);
    }
    if (_persistedUrl != null && _persistedUrl!.isNotEmpty) {
      return _persistedUrl!;
    }
    return _platformFallback();
  }

  /// Text to show in the Login server field (saved or fallback).
  static String get displayApiUrlForEditing => apiBaseUrl;

  /// Save URL from login screen. Empty string clears override → platform default.
  static Future<void> persistBaseUrlFromInput(String raw) async {
    final t = raw.trim();
    if (t.isEmpty) {
      await clearPersistedBaseUrl();
      return;
    }
    final normalized = normalizeBaseUrl(t);
    _persistedUrl = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, normalized);
    } catch (_) {}
  }

  static Future<void> clearPersistedBaseUrl() async {
    _persistedUrl = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
