import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';
import 'auth_service.dart';

class DeliveryNoteService {
  DeliveryNoteService({http.Client? client})
      : _client = client ?? AppHttpClient.instance;

  final http.Client _client;
  static const _timeout = Duration(seconds: 30);

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await AuthService.getStoredToken();
    if (token == null || token.isEmpty) {
      throw AuthException('Session expired. Please login again.');
    }
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<DeliveryNoteRecord> create(Map<String, dynamic> body) async {
    final response = await _client
        .post(
          _uri('/api/delivery-notes'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return DeliveryNoteRecord.fromJson(
      map['deliveryNote'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<List<DeliveryNoteRecord>> listMine() async {
    final response = await _client
        .get(_uri('/api/delivery-notes/mine'), headers: await _headers())
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return _parseList(map);
  }

  Future<List<DeliveryNoteRecord>> listAdmin() async {
    final response = await _client
        .get(_uri('/api/delivery-notes/admin'), headers: await _headers())
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return _parseList(map);
  }

  Future<DeliveryNoteRecord> getOne(String id) async {
    final response = await _client
        .get(_uri('/api/delivery-notes/$id'), headers: await _headers())
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return DeliveryNoteRecord.fromJson(
      map['deliveryNote'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<DeliveryNoteRecord> update(String id, Map<String, dynamic> body) async {
    final response = await _client
        .put(
          _uri('/api/delivery-notes/$id'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
    return DeliveryNoteRecord.fromJson(
      map['deliveryNote'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<void> delete(String id) async {
    final response = await _client
        .delete(_uri('/api/delivery-notes/$id'), headers: await _headers())
        .timeout(_timeout);
    final map = _readJson(response);
    _throwIfBad(response, map);
  }

  Future<Uint8List> downloadPdf(String id) async {
    final response = await _client
        .get(
          _uri('/api/delivery-notes/$id/pdf'),
          headers: await _headers(json: false),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode >= 400) {
      try {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(map['error']?.toString() ?? 'PDF download failed');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('PDF download failed (${response.statusCode})');
      }
    }
    final bytes = response.bodyBytes;
    if (bytes.length < 4 || String.fromCharCodes(bytes.take(4)) != '%PDF') {
      throw Exception('Invalid PDF received from server');
    }
    return bytes;
  }

  List<DeliveryNoteRecord> _parseList(Map<String, dynamic> map) {
    final raw = map['deliveryNotes'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DeliveryNoteRecord.fromJson)
        .toList();
  }

  Map<String, dynamic> _readJson(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': response.body.isNotEmpty ? response.body : 'Request failed'};
    }
  }

  void _throwIfBad(http.Response response, Map<String, dynamic> map) {
    if (response.statusCode >= 400) {
      throw Exception(map['error']?.toString() ?? 'Request failed');
    }
  }
}

class DeliveryNoteRecord {
  const DeliveryNoteRecord({
    required this.id,
    required this.deliveryNoteNo,
    this.deliveryDate,
    required this.deliveryTime,
    required this.customerName,
    required this.customerAddress,
    required this.customerMobile,
    required this.idProofType,
    required this.idProofNo,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.registrationNo,
    this.yearOfManufacture,
    required this.colour,
    required this.fuelType,
    required this.chassisNo,
    required this.engineNo,
    this.odometerKm,
    this.totalPrice,
    this.amountReceived,
    this.balanceAmount,
    required this.paymentMode,
    required this.documentsHandedOver,
    required this.declarationCustomerName,
    required this.customerSignatureName,
    this.signedAt,
    required this.authorizedSignatoryName,
    required this.vehicleHandedOverBy,
    required this.userEmail,
    required this.userName,
    this.createdAt,
  });

  final String id;
  final String deliveryNoteNo;
  final DateTime? deliveryDate;
  final String deliveryTime;
  final String customerName;
  final String customerAddress;
  final String customerMobile;
  final String idProofType;
  final String idProofNo;
  final String vehicleBrand;
  final String vehicleModel;
  final String registrationNo;
  final int? yearOfManufacture;
  final String colour;
  final String fuelType;
  final String chassisNo;
  final String engineNo;
  final int? odometerKm;
  final double? totalPrice;
  final double? amountReceived;
  final double? balanceAmount;
  final String paymentMode;
  final String documentsHandedOver;
  final String declarationCustomerName;
  final String customerSignatureName;
  final DateTime? signedAt;
  final String authorizedSignatoryName;
  final String vehicleHandedOverBy;
  final String userEmail;
  final String userName;
  final DateTime? createdAt;

  String get vehicleLabel {
    final parts = [vehicleBrand, vehicleModel].where((s) => s.isNotEmpty);
    return parts.isEmpty ? 'Vehicle' : parts.join(' ');
  }

  factory DeliveryNoteRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return DeliveryNoteRecord(
      id: json['id']?.toString() ?? '',
      deliveryNoteNo: json['deliveryNoteNo']?.toString() ?? '',
      deliveryDate: parseDate(json['deliveryDate']),
      deliveryTime: json['deliveryTime']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerAddress: json['customerAddress']?.toString() ?? '',
      customerMobile: json['customerMobile']?.toString() ?? '',
      idProofType: json['idProofType']?.toString() ?? '',
      idProofNo: json['idProofNo']?.toString() ?? '',
      vehicleBrand: json['vehicleBrand']?.toString() ?? '',
      vehicleModel: json['vehicleModel']?.toString() ?? '',
      registrationNo: json['registrationNo']?.toString() ?? '',
      yearOfManufacture: parseInt(json['yearOfManufacture']),
      colour: json['colour']?.toString() ?? '',
      fuelType: json['fuelType']?.toString() ?? '',
      chassisNo: json['chassisNo']?.toString() ?? '',
      engineNo: json['engineNo']?.toString() ?? '',
      odometerKm: parseInt(json['odometerKm']),
      totalPrice: parseDouble(json['totalPrice']),
      amountReceived: parseDouble(json['amountReceived']),
      balanceAmount: parseDouble(json['balanceAmount']),
      paymentMode: json['paymentMode']?.toString() ?? '',
      documentsHandedOver: json['documentsHandedOver']?.toString() ?? '',
      declarationCustomerName: json['declarationCustomerName']?.toString() ?? '',
      customerSignatureName: json['customerSignatureName']?.toString() ?? '',
      signedAt: parseDate(json['signedAt']),
      authorizedSignatoryName: json['authorizedSignatoryName']?.toString() ?? '',
      vehicleHandedOverBy: json['vehicleHandedOverBy']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    String? iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'deliveryNoteNo': deliveryNoteNo,
      'deliveryDate': iso(deliveryDate),
      'deliveryTime': deliveryTime,
      'customerName': customerName,
      'customerAddress': customerAddress,
      'customerMobile': customerMobile,
      'idProofType': idProofType,
      'idProofNo': idProofNo,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'registrationNo': registrationNo,
      'yearOfManufacture': yearOfManufacture,
      'colour': colour,
      'fuelType': fuelType,
      'chassisNo': chassisNo,
      'engineNo': engineNo,
      'odometerKm': odometerKm,
      'totalPrice': totalPrice,
      'amountReceived': amountReceived,
      'balanceAmount': balanceAmount,
      'paymentMode': paymentMode,
      'documentsHandedOver': documentsHandedOver,
      'declarationCustomerName': declarationCustomerName,
      'customerSignatureName': customerSignatureName,
      'signedAt': iso(signedAt),
      'authorizedSignatoryName': authorizedSignatoryName,
      'vehicleHandedOverBy': vehicleHandedOverBy,
    };
  }
}
