import 'package:flutter/material.dart';

import '../core/navigation/app_navigator.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_store.dart';
import '../core/ui/app_scroll_behavior.dart';
import '../features/splash/presentation/splash_page.dart';

class YourdreamcarApp extends StatefulWidget {
  const YourdreamcarApp({super.key});

  @override
  State<YourdreamcarApp> createState() => _YourdreamcarAppState();
}

class _YourdreamcarAppState extends State<YourdreamcarApp> {
  final _themeStore = ThemeModeStore();
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final enabled = await _themeStore.loadDarkMode();
    if (!mounted) return;
    setState(() => _darkMode = enabled);
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() => _darkMode = enabled);
    await _themeStore.saveDarkMode(enabled);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your Dream Car',
      navigatorKey: AppNavigator.key,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: SplashPage(
        darkModeEnabled: _darkMode,
        onThemeChanged: _setDarkMode,
      ),
    );
  }
}
