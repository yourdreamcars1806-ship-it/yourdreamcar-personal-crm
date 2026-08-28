import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/open_panel.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/ui/auth_chrome.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/auth_service.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.darkModeEnabled,
    required this.onThemeChanged,
    this.popOnSuccess = false,
  });

  final bool darkModeEnabled;
  final ValueChanged<bool> onThemeChanged;
  final bool popOnSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChanged);
    _passwordFocus.addListener(_onFocusChanged);
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final saved = await AuthService.getRememberedEmail();
    if (!mounted || saved == null || saved.isEmpty) return;
    setState(() => _emailCtrl.text = saved);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  bool _isEmailFieldValid(String s) {
    final t = s.trim();
    return t.contains('@') && t.length >= 4;
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (_loading) return;
    if (!_isEmailFieldValid(email)) {
      AppToast.error(context, 'Enter a valid email');
      return;
    }
    if (password.isEmpty) {
      AppToast.error(context, 'Enter your password');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthService.setRememberedEmail(_rememberMe ? email : null);
      final result = await _auth.login(email, password);
      if (!mounted) return;
      finishAuthSession(
        context,
        result: result,
        popCount: widget.popOnSuccess ? 1 : 0,
        darkModeEnabled: widget.darkModeEnabled,
        onThemeChanged: widget.onThemeChanged,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showAuthError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showAuthError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAuthError(String message) {
    final detailed =
        message.length > 100 ||
        message.contains('\n') ||
        message.contains('Check karein');
    if (detailed) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Connection problem'),
          content: SingleChildScrollView(
            child: Text(message, style: const TextStyle(height: 1.35)),
          ),
          actions: [
            if (!AppConfig.hasCompiledApiUrl)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openServerSettingsDialog();
                },
                child: const Text('Server settings'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    AppToast.error(context, message);
  }

  Future<void> _openServerSettingsDialog() async {
    if (!mounted) return;
    if (AppConfig.hasCompiledApiUrl) {
      AppToast.info(context, 'Server URL is fixed in this build.');
      return;
    }
    final ctrl = TextEditingController(text: AppConfig.displayApiUrlForEditing);
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Backend URL'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'https://your-service.up.railway.app',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await AppConfig.clearPersistedBaseUrl();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Reset'),
            ),
            FilledButton(
              onPressed: () async {
                await AppConfig.persistBaseUrlFromInput(ctrl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      title: 'Welcome Back!',
      subtitle: 'Login to buy, sell and manage ads',
      trailing: IconButton(
        tooltip: 'Server settings',
        icon: const Icon(Icons.settings_outlined, color: Colors.white),
        onPressed: _loading ? null : _openServerSettingsDialog,
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          AuthField(
            icon: Icons.mail_outline_rounded,
            hint: 'Email',
            controller: _emailCtrl,
            focusNode: _emailFocus,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          AuthField(
            icon: Icons.lock_outline_rounded,
            hint: 'Password',
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            enabled: !_loading,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            trailing: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: _loading
                  ? null
                  : () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: MarketColors.muted,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: MarketColors.primary,
                  side: const BorderSide(color: Color(0xFFC5D0E0)),
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _rememberMe = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Remember me',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MarketColors.text,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          AuthPrimaryButton(
            label: 'Login',
            loading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: MarketColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: _loading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SignupPage(
                              darkModeEnabled: widget.darkModeEnabled,
                              onThemeChanged: widget.onThemeChanged,
                              popOnSuccess: widget.popOnSuccess,
                            ),
                          ),
                        );
                      },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: MarketColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

