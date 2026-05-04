import 'package:flutter/material.dart';

class AppToast {
  static const _defaultDuration = Duration(seconds: 2);

  static void success(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
  }) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFF1E7A48),
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
  }) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFFC0392B),
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
  }) {
    _show(
      context,
      message,
      backgroundColor: const Color(0xFF16345E),
      duration: duration,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: duration,
        ),
      );
  }
}
