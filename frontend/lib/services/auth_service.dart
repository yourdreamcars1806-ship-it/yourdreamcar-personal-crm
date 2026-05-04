import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? AppHttpClient.instance;

  final http.Client _client;

  static const _keyToken = 'auth_token';
  static const _keyEmail = 'auth_email';
  static const _timeout = Duration(seconds: 25);

  /// Saves token/email; never throws — login should still succeed if prefs channel fails.
  static Future<void> _persistSession(String token, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyEmail, email);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[auth] SharedPreferences failed (session works until app restart): $e\n$st');
      }
    }
  }

  Future<LoginResult> login(String email, String password) async {
    final base = AppConfig.apiBaseUrl;
    final uri = Uri.parse('$base/api/auth/login');

    if (kDebugMode) {
      debugPrint('[auth] POST $uri');
    }

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(_timeout);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[auth] network error: $e\n$st');
      }
      throw AuthException(_friendlyNetworkError(base, e));
    }

    final body = response.body.isEmpty ? '{}' : response.body;
    Map<String, dynamic> map;
    try {
      map = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException(
        'Server error (${response.statusCode}). Is the API running on $base?',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = map['token'] as String?;
      final user = map['user'] as Map<String, dynamic>?;
      final em = user?['email'] as String?;
      if (token == null || em == null) {
        throw AuthException('Unexpected response from server');
      }
      await _persistSession(token, em);
      return LoginResult(token: token, email: em);
    }

    final err = map['error'] as String? ?? 'Login failed';
    throw AuthException(err);
  }

  static String _friendlyNetworkError(String base, Object e) {
    final raw = e.toString().toLowerCase();
    final buf = StringBuffer()
      ..writeln('Server tak connect nahi ho paya.')
      ..writeln('URL: $base')
      ..writeln()
      ..writeln('Check karein:')
      ..writeln('1) Backend chal raha ho: cd backend && npm run dev')
      ..writeln('2) Emulator: URL http://10.0.2.2:5000 honi chahiye (default)')
      ..writeln('3) Real phone: same Wi‑Fi + PC ka IP, phir run:')
      ..writeln('   flutter run --dart-define=API_BASE_URL=http://PC_IP:5000');

    if (raw.contains('timed out') || raw.contains('timeout')) {
      buf.writeln('(Timeout — server slow ya galat IP / firewall)');
    } else if (raw.contains('connection refused') ||
        raw.contains('failed to connect')) {
      buf.writeln('(Connection refused — port 5000 par kuch listen nahi kar raha)');
    } else if (raw.contains('failed host lookup') ||
        raw.contains('network is unreachable')) {
      buf.writeln('(DNS / network — phone ka data off karke Wi‑Fi try karein)');
    }
    return buf.toString().trim();
  }

  static Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[auth] getStoredToken: $e');
      }
      return null;
    }
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyEmail);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[auth] clearSession: $e');
      }
    }
  }
}

class LoginResult {
  LoginResult({required this.token, required this.email});

  final String token;
  final String email;
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
