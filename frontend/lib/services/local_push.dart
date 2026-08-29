import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/navigation/app_navigator.dart';

/// Real Android system notifications via [flutter_local_notifications].
/// Backend delivers events over SSE/polling — not FCM.
abstract final class LocalPush {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'your_dream_car_alerts';
  static const _channelName = 'Your Dream Car';
  static const _channelDescription =
      'New cars and marketplace alerts from Your Dream Car';

  static bool _ready = false;
  static bool _permissionGranted = false;

  static bool get _android => !kIsWeb && Platform.isAndroid;
  static bool get hasPermission => _permissionGranted;

  static Future<void> init() async {
    if (!_android || _ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: android),
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
      );

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        ),
      );

      _permissionGranted =
          await androidPlugin?.areNotificationsEnabled() ?? true;
      if (!_permissionGranted) {
        _permissionGranted =
            await androidPlugin?.requestNotificationsPermission() ?? false;
      }

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final payload = launch!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.openCar(carId: payload);
          });
        }
      }

      _ready = true;
    } catch (e) {
      debugPrint('[notify] local push init failed: $e');
    }
  }

  static void _onNotificationTap(NotificationResponse resp) {
    _handlePayload(resp.payload);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse resp) {
    _handlePayload(resp.payload);
  }

  static void _handlePayload(String? carId) {
    if (carId == null || carId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNavigator.openCar(carId: carId);
    });
  }

  static Future<void> showNewCar({
    required String title,
    required String body,
    required String carId,
  }) async {
    if (!_android) return;
    await init();
    if (!_ready || !_permissionGranted) return;
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.recommendation,
          autoCancel: true,
          ticker: title,
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
        ),
      );
      await _plugin.show(
        carId.hashCode.abs() % 100000,
        title,
        body,
        details,
        payload: carId.isEmpty ? null : carId,
      );
    } catch (e) {
      debugPrint('[notify] local push show failed: $e');
    }
  }
}
