import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';
import 'auth_service.dart';

class BidService {
  BidService({http.Client? client}) : _client = client ?? AppHttpClient.instance;

  final http.Client _client;
  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getStoredToken();
    if (token == null || token.isEmpty) {
      throw AuthException('Session expired. Please login again.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<BidRecord> create({
    required String carId,
    required double amount,
    required String name,
    required String phone,
    required String city,
    String message = '',
  }) async {
    final response = await _client
        .post(
          _uri('/api/bids'),
          headers: await _headers(),
          body: jsonEncode({
            'carId': carId,
            'amount': amount,
            'name': name,
            'phone': phone,
            'city': city,
            'message': message,
          }),
        )
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return BidRecord.fromJson(map['bid'] as Map<String, dynamic>? ?? {});
  }

  Future<List<BidRecord>> listMine() async {
    final response = await _client
        .get(_uri('/api/bids'), headers: await _headers())
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return _parseList(map);
  }

  Future<List<BidRecord>> listAdmin() async {
    final response = await _client
        .get(_uri('/api/bids/admin'), headers: await _headers())
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return _parseList(map);
  }

  Future<BidRecord> updateStatus({
    required String id,
    required String status,
  }) async {
    final response = await _client
        .patch(
          _uri('/api/bids/$id'),
          headers: await _headers(),
          body: jsonEncode({'status': status}),
        )
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return BidRecord.fromJson(map['bid'] as Map<String, dynamic>? ?? {});
  }

  List<BidRecord> _parseList(Map<String, dynamic> map) {
    final raw = map['bids'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BidRecord.fromJson)
        .toList();
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
    throw AuthException('$error');
  }
}

class BidRecord {
  BidRecord({
    required this.id,
    required this.carId,
    required this.amount,
    required this.name,
    required this.phone,
    required this.city,
    required this.message,
    required this.carTitle,
    required this.carImageUrl,
    required this.askPrice,
    required this.status,
    this.userEmail = '',
    this.userName = '',
    this.createdAt,
  });

  factory BidRecord.fromJson(Map<String, dynamic> json) {
    return BidRecord(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      carId: (json['carId'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      carTitle: (json['carTitle'] ?? '').toString(),
      carImageUrl: (json['carImageUrl'] ?? '').toString(),
      askPrice: (json['askPrice'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? 'pending').toString(),
      userEmail: (json['userEmail'] ?? '').toString(),
      userName: (json['userName'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  final String id;
  final String carId;
  final double amount;
  final String name;
  final String phone;
  final String city;
  final String message;
  final String carTitle;
  final String carImageUrl;
  final double askPrice;
  final String status;
  final String userEmail;
  final String userName;
  final DateTime? createdAt;
}
