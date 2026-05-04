import 'package:http/http.dart' as http;

/// Single [http.Client] so TCP connections reuse across API calls (faster).
/// Do not call [http.Client.close] except at full app shutdown (usually omit).
class AppHttpClient {
  AppHttpClient._();

  static final http.Client instance = http.Client();
}
