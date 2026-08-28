import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/navigation/app_navigator.dart';

abstract final class LocalPush {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _android => !kIsWeb && Platform.isAndroid;

  static Future<void> init() async {
    if (!_android || _ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: android),
        onDidReceiveNotificationResponse: (resp) {
          final carId = resp.payload;
          if (carId == null || carId.isEmpty) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.openCar(carId: carId);
          });
        },
      );
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('[notify] local push init failed: $e');
    }
  }

  static Future<void> showNewCar({
    required String title,
    required String body,
    required String carId,
  }) async {
    if (!_android || !_ready) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'dream_car_new',
          'New cars',
          channelDescription: 'When an admin adds a new car',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: carId,
      );
    } catch (e) {
      debugPrint('[notify] local push show failed: $e');
    }
  }
}
