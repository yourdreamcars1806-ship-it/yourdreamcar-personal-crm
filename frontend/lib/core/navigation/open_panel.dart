import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/marketplace/presentation/user_shell.dart';
import '../../features/shell/main_shell.dart';
import '../../services/auth_service.dart';

/// Opens admin CRM or user marketplace from the login role.
void openPanelForRole(
  BuildContext context, {
  required String role,
  required bool darkModeEnabled,
  required ValueChanged<bool> onThemeChanged,
}) {
  final isUser = role.trim().toLowerCase() != 'admin';
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => isUser
          ? UserShell(
              darkModeEnabled: darkModeEnabled,
              onThemeChanged: onThemeChanged,
            )
          : MainShell(
              darkModeEnabled: darkModeEnabled,
              onThemeChanged: onThemeChanged,
            ),
    ),
    (route) => false,
  );
}

void finishAuthSession(
  BuildContext context, {
  required LoginResult result,
  required bool darkModeEnabled,
  required ValueChanged<bool> onThemeChanged,
  int popCount = 0,
}) {
  if (result.role == 'admin') {
    openPanelForRole(
      context,
      role: 'admin',
      darkModeEnabled: darkModeEnabled,
      onThemeChanged: onThemeChanged,
    );
    return;
  }
  if (popCount > 0) {
    for (var i = 0; i < popCount; i++) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
      }
    }
    return;
  }
  openPanelForRole(
    context,
    role: 'user',
    darkModeEnabled: darkModeEnabled,
    onThemeChanged: onThemeChanged,
  );
}

Future<bool> ensureLoggedIn(
  BuildContext context, {
  required bool darkModeEnabled,
  required ValueChanged<bool> onThemeChanged,
}) async {
  final token = await AuthService.getStoredToken();
  if (token != null && token.isNotEmpty) {
    final role = await AuthService.getStoredRole();
    if (role == 'admin') {
      if (!context.mounted) return false;
      openPanelForRole(
        context,
        role: 'admin',
        darkModeEnabled: darkModeEnabled,
        onThemeChanged: onThemeChanged,
      );
      return false;
    }
    return true;
  }
  if (!context.mounted) return false;
  final result = await Navigator.of(context).push<LoginResult>(
    MaterialPageRoute(
      builder: (_) => LoginPage(
        darkModeEnabled: darkModeEnabled,
        onThemeChanged: onThemeChanged,
        popOnSuccess: true,
      ),
    ),
  );
  return result != null && result.role != 'admin';
}
