import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';
import '../features/expenses/domain/expense_entry.dart';
import 'auth_service.dart';

class ExpenseService {
  ExpenseService({http.Client? client}) : _client = client ?? AppHttpClient.instance;

  final http.Client _client;
  static const _timeout = Duration(seconds: 25);

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getStoredToken();
    if (token == null || token.isEmpty) {
      throw ExpenseServiceException('Not logged in');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<ExpenseEntry>> fetchExpenses({int? limit, String? carId}) async {
    final headers = await _headers();
    final q = <String, String>{};
    if (limit != null && limit > 0) {
      q['limit'] = '$limit';
    }
    final trimmedCarId = (carId ?? '').trim();
    if (trimmedCarId.isNotEmpty) {
      q['carId'] = trimmedCarId;
    }
    final uri = _uri('/api/expenses').replace(queryParameters: q.isEmpty ? null : q);
    final response = await _client.get(uri, headers: headers).timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    final raw = map['expenses'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ExpenseEntry.fromApiJson)
        .toList();
  }

  Future<ExpenseEntry> createExpense({
    required String title,
    required double amount,
    String? carId,
    String? carLabel,
  }) async {
    final headers = await _headers();
    final payload = <String, dynamic>{'title': title, 'amount': amount};
    if (carId != null && carId.isNotEmpty) payload['carId'] = carId;
    if (carLabel != null && carLabel.isNotEmpty) payload['carLabel'] = carLabel;
    final response = await _client.post(
      _uri('/api/expenses'),
      headers: headers,
      body: jsonEncode(payload),
    ).timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    final exp = map['expense'] as Map<String, dynamic>?;
    if (exp == null) {
      throw ExpenseServiceException('Unexpected response');
    }
    return ExpenseEntry.fromApiJson(exp);
  }

  Future<ExpenseEntry> updateExpense({
    required String id,
    required String title,
    required double amount,
  }) async {
    final headers = await _headers();
    final response = await _client.patch(
      _uri('/api/expenses/$id'),
      headers: headers,
      body: jsonEncode({'title': title, 'amount': amount}),
    ).timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    final exp = map['expense'] as Map<String, dynamic>?;
    if (exp == null) {
      throw ExpenseServiceException('Unexpected response');
    }
    return ExpenseEntry.fromApiJson(exp);
  }

  Future<void> deleteExpense(String id) async {
    final headers = await _headers();
    final response = await _client
        .delete(_uri('/api/expenses/$id'), headers: headers)
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
  }

  Map<String, dynamic> _readJson(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  void _throwIfBad(http.Response response, Map<String, dynamic> body) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final error = body['error'] ?? body['message'] ?? response.body;
    throw ExpenseServiceException(
      'Request failed (${response.statusCode}): $error',
    );
  }
}

class ExpenseServiceException implements Exception {
  ExpenseServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
