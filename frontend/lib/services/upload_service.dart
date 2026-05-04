import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';

class UploadService {
  UploadService({http.Client? client}) : _client = client ?? AppHttpClient.instance;

  final http.Client _client;

  /// POST multipart field name must be `image` (matches Express `upload.single('image')`).
  Future<UploadResult> uploadCarImage(File imageFile) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/upload/image');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final image = map['image'] as Map<String, dynamic>?;
      final url = image?['url'] as String?;
      if (url == null) {
        throw UploadException('Unexpected response: ${response.body}');
      }
      return UploadResult(imageUrl: url);
    }

    throw UploadException(
      'Upload failed (${response.statusCode}): ${response.body}',
    );
  }
}

class UploadResult {
  UploadResult({required this.imageUrl});

  final String imageUrl;
}

class UploadException implements Exception {
  UploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
