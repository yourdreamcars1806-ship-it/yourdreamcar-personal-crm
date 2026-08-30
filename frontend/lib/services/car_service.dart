import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';
import 'auth_service.dart';

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

Future<http.MultipartFile> _imageMultipart(File file, {String field = 'image'}) async {
  final name = _basename(file.path);
  final safeName = name.contains('.') ? name : '$name.jpg';
  return http.MultipartFile.fromPath(
    field,
    file.path,
    filename: safeName,
    contentType: MediaType.parse(_mimeForImagePath(safeName)),
  );
}

List<String> _parseUrlList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((item) {
        if (item is String) return item.trim();
        if (item is Map) return (item['url'] ?? '').toString().trim();
        return '';
      })
      .where((url) => url.isNotEmpty)
      .toList();
}

class CarService {
  CarService({http.Client? client}) : _client = client ?? AppHttpClient.instance;

  final http.Client _client;
  static const _timeout = Duration(seconds: 25);
  static const _listTimeout = Duration(seconds: 18);

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, String>> _authHeaders({bool required = false}) async {
    final token = await AuthService.getStoredToken();
    if (token == null || token.isEmpty) {
      if (required) {
        throw CarServiceException('Session expired. Please login again.');
      }
      return {};
    }
    return {'Authorization': 'Bearer $token'};
  }

  Future<CarListResponse> listCars({
    int? limit,
    bool omitDescription = false,
    bool omitSummary = false,
  }) async {
    final q = <String, String>{};
    if (limit != null && limit > 0) {
      q['limit'] = '$limit';
    }
    if (omitDescription) {
      q['omitDescription'] = '1';
    }
    if (omitSummary) {
      q['omitSummary'] = '1';
    }
    final uri = _uri('/api/cars').replace(queryParameters: q.isEmpty ? null : q);
    final response = await _client
        .get(uri, headers: await _authHeaders())
        .timeout(_listTimeout);
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

  Future<CarRecord> getCar(String id) async {
    final response = await _client
        .get(_uri('/api/cars/$id'), headers: await _authHeaders())
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return CarRecord.fromJson((map['car'] as Map<String, dynamic>? ?? {}));
  }

  Future<CarRecord> createCar({
    required Map<String, String> fields,
    required File imageFile,
    List<File> exteriorImages = const [],
    List<File> interiorImages = const [],
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/cars'));
    request.headers.addAll(await _authHeaders(required: true));
    request.fields.addAll(fields);
    request.files.add(await _imageMultipart(imageFile));
    for (final file in exteriorImages) {
      request.files.add(await _imageMultipart(file, field: 'exteriorImages'));
    }
    for (final file in interiorImages) {
      request.files.add(await _imageMultipart(file, field: 'interiorImages'));
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    ).timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return CarRecord.fromJson((map['car'] as Map<String, dynamic>? ?? {}));
  }

  Future<CarRecord> updateCar({
    required String id,
    required Map<String, String> fields,
    File? imageFile,
    List<File> exteriorImages = const [],
    List<File> interiorImages = const [],
    List<String> keepExteriorUrls = const [],
    List<String> keepInteriorUrls = const [],
  }) async {
    final request = http.MultipartRequest('PUT', _uri('/api/cars/$id'));
    request.headers.addAll(await _authHeaders(required: true));
    request.fields.addAll(fields);
    request.fields['exteriorImagesJson'] = jsonEncode(keepExteriorUrls);
    request.fields['interiorImagesJson'] = jsonEncode(keepInteriorUrls);
    if (imageFile != null) {
      request.files.add(await _imageMultipart(imageFile));
    }
    for (final file in exteriorImages) {
      request.files.add(await _imageMultipart(file, field: 'exteriorImages'));
    }
    for (final file in interiorImages) {
      request.files.add(await _imageMultipart(file, field: 'interiorImages'));
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    ).timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return CarRecord.fromJson((map['car'] as Map<String, dynamic>? ?? {}));
  }

  Future<void> deleteCar(String id) async {
    final response = await _client
        .delete(_uri('/api/cars/$id'), headers: await _authHeaders(required: true))
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
    required this.vehicleNumber,
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
    this.exteriorImages = const [],
    this.interiorImages = const [],
    this.liveBidEnabled = false,
    this.liveBidStartedAt,
  });

  factory CarRecord.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      final s = (v ?? '').toString().trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes' || s == 'on';
    }

    return CarRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      vehicleNumber: (json['vehicleNumber'] ?? '').toString(),
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
      exteriorImages: _parseUrlList(json['exteriorImages']),
      interiorImages: _parseUrlList(json['interiorImages']),
      liveBidEnabled: parseBool(json['liveBidEnabled']),
      liveBidStartedAt: DateTime.tryParse(
        (json['liveBidStartedAt'] ?? '').toString(),
      ),
    );
  }

  final String id;
  final String title;
  final String vehicleNumber;
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
  final List<String> exteriorImages;
  final List<String> interiorImages;
  final bool liveBidEnabled;
  final DateTime? liveBidStartedAt;

  bool get isSold => availability.toLowerCase() == 'outstock';

  bool get canBid => !isSold && liveBidEnabled;

  /// User-facing stock label: "In Stock" or "Sold".
  String get stockStatusLabel => isSold ? 'Sold' : 'In Stock';

  String get coverImageUrl {
    if (imageUrl.trim().isNotEmpty) return imageUrl;
    if (exteriorImages.isNotEmpty) return exteriorImages.first;
    if (interiorImages.isNotEmpty) return interiorImages.first;
    return '';
  }

  List<String> get allExteriorImages {
    final urls = <String>[];
    void add(String url) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty && !urls.contains(trimmed)) urls.add(trimmed);
    }

    add(imageUrl);
    for (final url in exteriorImages) {
      add(url);
    }
    return urls;
  }

  /// All exterior photos — cover image + extra exterior shots (deduped).
  List<String> get galleryExteriorImages => allExteriorImages;

  List<String> get allInteriorImages =>
      interiorImages.where((url) => url.trim().isNotEmpty).toList();

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'vehicleNumber': vehicleNumber,
        'brand': brand,
        'model': model,
        'fuelType': fuelType,
        'ownership': ownership,
        'availability': availability,
        'year': year,
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
        'buyDate': buyDate.toUtc().toIso8601String(),
        if (saleDate != null) 'saleDate': saleDate!.toUtc().toIso8601String(),
        'description': description,
        'imageUrl': imageUrl,
        'exteriorImages': exteriorImages,
        'interiorImages': interiorImages,
        'liveBidEnabled': liveBidEnabled,
        if (liveBidStartedAt != null)
          'liveBidStartedAt': liveBidStartedAt!.toUtc().toIso8601String(),
      };
}

class CarServiceException implements Exception {
  CarServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
