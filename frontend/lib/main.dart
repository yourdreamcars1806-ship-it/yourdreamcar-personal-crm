import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../services/car_catalog_service.dart';
import '../services/local_push.dart';
import '../services/notification_background.dart';
import 'app/yourdreamcar_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  if (!kIsWeb && Platform.isAndroid) {
    await LocalPush.init();
    unawaited(NotificationBackground.register());
  }
  unawaited(CarCatalogService.instance.bootstrap());
  runApp(const YourdreamcarApp());
}
