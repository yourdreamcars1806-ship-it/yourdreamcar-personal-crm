import 'package:flutter/material.dart';

import 'app/yourdreamcar_app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  runApp(const YourdreamcarApp());
}
