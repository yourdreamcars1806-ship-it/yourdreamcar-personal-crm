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
  static const _keyRole = 'auth_role';
  static const _keyName = 'auth_name';
  static const _keyRememberEmail = 'remember_email';
  static const _timeout = Duration(seconds: 25);

  static Future<void> _persistSession({
    required String token,
    required String email,
    required String role,
    String name = '',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyRole, role);
      await prefs.setString(_keyName, name);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[auth] SharedPreferences failed: $e\n$st');
      }
    }
  }

  Future<LoginResult> _postAuth(String path, Map<String, dynamic> body) async {
    final base = AppConfig.apiBaseUrl;
    final uri = Uri.parse('$base$path');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[auth] network error: $e\n$st');
      }
      throw AuthException(_friendlyNetworkError(base, e));
    }

    final raw = response.body.isEmpty ? '{}' : response.body;
    Map<String, dynamic> map;
    try {
      map = jsonDecode(raw) as Map<String, dynamic>;
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
      final role = (user?['role'] as String? ?? 'admin').toLowerCase();
      final name = (user?['name'] as String? ?? '').toString();
      await _persistSession(token: token, email: em, role: role, name: name);
      return LoginResult(token: token, email: em, role: role, name: name);
    }

    final err = map['error'] as String? ?? 'Login failed';
    throw AuthException(err);
  }

  Future<LoginResult> login(String email, String password) {
    return _postAuth('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });
  }

  Future<LoginResult> register({
    required String email,
    required String password,
    String name = '',
  }) {
    return _postAuth('/api/auth/register', {
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getStoredToken();
    if (token == null || token.isEmpty) {
      throw AuthException('Session expired. Please login again.');
    }

    final base = AppConfig.apiBaseUrl;
    final uri = Uri.parse('$base/api/auth/change-password');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(_timeout);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[auth] changePassword network error: $e\n$st');
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
      return;
    }

    final err = map['error'] as String? ?? 'Could not update password';
    throw AuthException(err);
  }

  Future<AdminStatsRecord> fetchAdminStats() async {
    final token = await getStoredToken();
    if (token == null || token.isEmpty) {
      throw AuthException('Session expired. Please login again.');
    }
    final base = AppConfig.apiBaseUrl;
    final uri = Uri.parse('$base/api/auth/admin/stats');
    final response = await _client
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(_timeout);
    final map = jsonDecode(response.body.isEmpty ? '{}' : response.body)
        as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw AuthException(map['error']?.toString() ?? 'Failed to load stats');
    }
    return AdminStatsRecord.fromJson(map);
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

  static Future<String> getStoredRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString(_keyRole) ?? 'admin').toLowerCase();
    } catch (_) {
      return 'admin';
    }
  }

  static Future<String> getStoredEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyEmail) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<String> getStoredName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyName) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<String?> getRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRememberEmail);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setRememberedEmail(String? email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (email == null || email.isEmpty) {
        await prefs.remove(_keyRememberEmail);
      } else {
        await prefs.setString(_keyRememberEmail, email);
      }
    } catch (_) {}
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyRole);
      await prefs.remove(_keyName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[auth] clearSession: $e');
      }
    }
  }
}

class LoginResult {
  LoginResult({
    required this.token,
    required this.email,
    required this.role,
    this.name = '',
  });

  final String token;
  final String email;
  final String role;
  final String name;
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AdminStatsRecord {
  const AdminStatsRecord({
    required this.totalUsers,
    required this.activeUsers,
    required this.activeWindowMinutes,
  });

  final int totalUsers;
  final int activeUsers;
  final int activeWindowMinutes;

  factory AdminStatsRecord.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return AdminStatsRecord(
      totalUsers: parseInt(json['totalUsers']),
      activeUsers: parseInt(json['activeUsers']),
      activeWindowMinutes: parseInt(json['activeWindowMinutes']),
    );
  }
}
