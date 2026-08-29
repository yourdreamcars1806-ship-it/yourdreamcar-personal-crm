import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/app_http_client.dart';
import 'car_alert_service.dart';
import 'local_push.dart';

/// Shared poll logic for foreground service and background Workmanager tasks.
abstract final class NotificationPoller {
  static const _sinceKey = 'car_alert_since';
  static const _seenKey = 'car_alert_push_seen';

  /// Fetch new car alerts since last checkpoint and show Android tray notifications.
  static Future<int> pollAndNotify({http.Client? client}) async {
    if (kIsWeb) return 0;
    try {
      await LocalPush.init();
      if (!LocalPush.hasPermission) return 0;

      final prefs = await SharedPreferences.getInstance();
      final sinceRaw = prefs.getString(_sinceKey);
      final since = DateTime.tryParse(sinceRaw ?? '');

      final q = <String, String>{'limit': '20'};
      if (since != null) {
        q['since'] = since.toUtc().toIso8601String();
      }

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/notifications')
          .replace(queryParameters: q);
      final httpClient = client ?? AppHttpClient.instance;
      final res = await httpClient.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) return 0;

      final map = jsonDecode(res.body);
      if (map is! Map<String, dynamic>) return 0;
      final raw = map['notifications'] as List<dynamic>? ?? [];
      final incoming = raw
          .whereType<Map<String, dynamic>>()
          .map(CarAlert.fromJson)
          .where((n) => n.id.isNotEmpty)
          .toList();
      if (incoming.isEmpty) return 0;

      incoming.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final seen = prefs.getStringList(_seenKey)?.toSet() ?? <String>{};
      var shown = 0;

      for (final alert in incoming.reversed) {
        if (seen.contains(alert.id)) continue;
        await LocalPush.showNewCar(
          title: alert.title,
          body: alert.body,
          carId: alert.carId,
        );
        seen.add(alert.id);
        shown++;
      }

      final newest = incoming.first.createdAt;
      if (since == null || newest.isAfter(since)) {
        await prefs.setString(_sinceKey, newest.toUtc().toIso8601String());
      }
      await prefs.setStringList(_seenKey, seen.take(120).toList());
      return shown;
    } catch (e) {
      debugPrint('[notify] poll failed: $e');
      return 0;
    }
  }
}
