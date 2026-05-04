import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final i = normalized.lastIndexOf('/');
  return i >= 0 ? normalized.substring(i + 1) : path;
}

String _mimeForImagePath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return 'image/jpeg';
  switch (path.substring(dot + 1).toLowerCase()) {
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'bmp':
      return 'image/bmp';
    case 'heic':
    case 'heif':
      return 'image/heic';
    case 'avif':
      return 'image/avif';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}

Future<http.MultipartFile> _imageMultipart(File file) async {
  final name = _basename(file.path);
  final safeName = name.contains('.') ? name : '$name.jpg';
  return http.MultipartFile.fromPath(
    'image',
    file.path,
    filename: safeName,
    contentType: MediaType.parse(_mimeForImagePath(safeName)),
  );
}

class CarService {
  CarService({http.Client? client}) : _client = client ?? AppHttpClient.instance;

  final http.Client _client;
  static const _timeout = Duration(seconds: 25);
  static const _listTimeout = Duration(seconds: 18);

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<CarListResponse> listCars({
    int? limit,
    bool omitDescription = false,
  }) async {
    final q = <String, String>{};
    if (limit != null && limit > 0) {
      q['limit'] = '$limit';
    }
    if (omitDescription) {
      q['omitDescription'] = '1';
    }
    final uri = _uri('/api/cars').replace(queryParameters: q.isEmpty ? null : q);
    final response = await _client.get(uri).timeout(_listTimeout);
    final map = _readJson(response);
    _throwIfBad(response, map);

    final carsRaw = map['cars'] as List<dynamic>? ?? [];
    final cars = carsRaw
        .whereType<Map<String, dynamic>>()
        .map(CarRecord.fromJson)
        .toList();

    final summaryRaw = map['summary'] as Map<String, dynamic>? ?? {};
    return CarListResponse(
      cars: cars,
      total: (summaryRaw['total'] as num?)?.toInt() ?? cars.length,
      stock: (summaryRaw['stock'] as num?)?.toInt() ?? 0,
      outstock: (summaryRaw['outstock'] as num?)?.toInt() ?? 0,
    );
  }

  Future<CarRecord> createCar({
    required Map<String, String> fields,
    required File imageFile,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/cars'));
    request.fields.addAll(fields);
    request.files.add(await _imageMultipart(imageFile));
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    final map = _readJson(response);
    _throwIfBad(response, map);
    return CarRecord.fromJson((map['car'] as Map<String, dynamic>? ?? {}));
  }

  Future<CarRecord> updateCar({
    required String id,
    required Map<String, String> fields,
    File? imageFile,
  }) async {
    final request = http.MultipartRequest('PUT', _uri('/api/cars/$id'));
    request.fields.addAll(fields);
    if (imageFile != null) {
      request.files.add(await _imageMultipart(imageFile));
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    final map = _readJson(response);
    _throwIfBad(response, map);
    return CarRecord.fromJson((map['car'] as Map<String, dynamic>? ?? {}));
  }

  Future<void> deleteCar(String id) async {
    final response = await _client.delete(_uri('/api/cars/$id'));
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
    throw CarServiceException(
      'Request failed (${response.statusCode}): $error',
    );
  }
}

class CarListResponse {
  CarListResponse({
    required this.cars,
    required this.total,
    required this.stock,
    required this.outstock,
  });

  final List<CarRecord> cars;
  final int total;
  final int stock;
  final int outstock;
}

class CarRecord {
  CarRecord({
    required this.id,
    required this.title,
    required this.brand,
    required this.model,
    required this.fuelType,
    required this.ownership,
    required this.availability,
    required this.year,
    required this.buyPrice,
    required this.sellPrice,
    required this.buyDate,
    this.saleDate,
    required this.description,
    required this.imageUrl,
  });

  factory CarRecord.fromJson(Map<String, dynamic> json) {
    return CarRecord(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      fuelType: (json['fuelType'] ?? '').toString(),
      ownership: (json['ownership'] ?? '').toString(),
      availability: (json['availability'] ?? '').toString(),
      year: (json['year'] as num?)?.toInt() ?? 0,
      buyPrice: (json['buyPrice'] as num?)?.toDouble() ?? 0,
      sellPrice: (json['sellPrice'] as num?)?.toDouble() ?? 0,
      buyDate:
          DateTime.tryParse((json['buyDate'] ?? '').toString()) ??
          DateTime.now(),
      saleDate: DateTime.tryParse((json['saleDate'] ?? '').toString()),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
    );
  }

  final String id;
  final String title;
  final String brand;
  final String model;
  final String fuelType;
  final String ownership;
  final String availability;
  final int year;
  final double buyPrice;
  final double sellPrice;
  final DateTime buyDate;
  final DateTime? saleDate;
  final String description;
  final String imageUrl;
}

class CarServiceException implements Exception {
  CarServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
