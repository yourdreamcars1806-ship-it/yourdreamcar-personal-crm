import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';
import 'auth_service.dart';

class ListingRequestService {
  ListingRequestService({http.Client? client})
      : _client = client ?? AppHttpClient.instance;

  final http.Client _client;
  static const _timeout = Duration(seconds: 30);

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getStoredToken();
    if (token == null || token.isEmpty) {
      throw AuthException('Session expired. Please login again.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<ListingRequestRecord>> listMine() async {
    final response = await _client
        .get(_uri('/api/listing-requests'), headers: await _authHeaders())
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    final raw = map['requests'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ListingRequestRecord.fromJson)
        .toList();
  }

  Future<List<ListingRequestRecord>> listAdmin() async {
    final response = await _client
        .get(_uri('/api/listing-requests/admin'), headers: await _authHeaders())
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    final raw = map['requests'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ListingRequestRecord.fromJson)
        .toList();
  }

  Future<ListingRequestRecord> review({
    required String id,
    required String action,
    Map<String, dynamic> fields = const {},
  }) async {
    final response = await _client
        .patch(
          _uri('/api/listing-requests/$id'),
          headers: {
            ...await _authHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'action': action, ...fields}),
        )
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return ListingRequestRecord.fromJson(
      map['request'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<ListingRequestRecord> create({
    required Map<String, String> fields,
    File? imageFile,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/listing-requests'),
    );
    request.headers.addAll(await _authHeaders());
    request.fields.addAll(fields);
    if (imageFile != null) {
      final name = imageFile.path.replaceAll('\\', '/').split('/').last;
      final safe = name.contains('.') ? name : '$name.jpg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: safe,
          contentType: MediaType.parse('image/jpeg'),
        ),
      );
    }
    final streamed = await _client.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return ListingRequestRecord.fromJson(
      map['request'] as Map<String, dynamic>? ?? {},
    );
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

class ListingRequestRecord {
  ListingRequestRecord({
    required this.id,
    required this.title,
    required this.vehicleNumber,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.ownership,
    required this.kmDriven,
    required this.expectedPrice,
    required this.city,
    required this.phone,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.publishedCarId,
    required this.userName,
    required this.userEmail,
    this.createdAt,
  });

  factory ListingRequestRecord.fromJson(Map<String, dynamic> json) {
    return ListingRequestRecord(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      vehicleNumber: (json['vehicleNumber'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      year: (json['year'] as num?)?.toInt() ?? 0,
      fuelType: (json['fuelType'] ?? '').toString(),
      ownership: (json['ownership'] ?? '1st owner').toString(),
      kmDriven: (json['kmDriven'] as num?)?.toInt() ?? 0,
      expectedPrice: (json['sellPrice'] as num?)?.toDouble() ??
          (json['expectedPrice'] as num?)?.toDouble() ??
          0,
      city: (json['city'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      publishedCarId: (json['publishedCarId'] ?? '').toString(),
      userName: (json['userName'] ?? '').toString(),
      userEmail: (json['userEmail'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  final String id;
  final String title;
  final String vehicleNumber;
  final String brand;
  final String model;
  final int year;
  final String fuelType;
  final String ownership;
  final int kmDriven;
  final double expectedPrice;
  final String city;
  final String phone;
  final String description;
  final String imageUrl;
  final String status;
  final String publishedCarId;
  final String userName;
  final String userEmail;
  final DateTime? createdAt;
}
