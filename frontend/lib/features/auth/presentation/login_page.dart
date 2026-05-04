import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/login_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/auth_service.dart';
import '../../shell/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.darkModeEnabled,
    required this.onThemeChanged,
  });

  final bool darkModeEnabled;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController(text: 'gafru@yourdreamcar.app');
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFocusChanged);
    _passwordFocus.addListener(_onFocusChanged);
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
      await _auth.login(email, password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainShell(
            darkModeEnabled: widget.darkModeEnabled,
            onThemeChanged: widget.onThemeChanged,
          ),
        ),
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
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'http://192.168.1.5:5000',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Phone + PC same Wi‑Fi: PC का IP और port 5000.\n'
                  'Emulator: http://10.0.2.2:5000',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await AppConfig.clearPersistedBaseUrl();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                AppToast.info(context, 'Using default URL');
              },
              child: const Text('Reset'),
            ),
            FilledButton(
              onPressed: () async {
                await AppConfig.persistBaseUrlFromInput(ctrl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                AppToast.success(context, 'Saved');
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Server settings',
            icon: Icon(
              Icons.settings_outlined,
              color: Color(0xFF5F7BA5),
            ),
            onPressed: _loading ? null : () => _openServerSettingsDialog(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: _loading
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x221D63ED),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 4),
              const Text(
                'Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2442),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome back!\nPlease login to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5F7BA5),
                ),
              ),
              const SizedBox(height: 8),
              _LabeledFieldCard(
                icon: Icons.email_rounded,
                label: 'Email Address',
                isFocused: _emailFocus.hasFocus,
                child: TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  style: const TextStyle(
                    fontSize: 16,
                    color: LoginColors.valueText,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    hintText: 'Your email address',
                    hintStyle: TextStyle(
                      color: LoginColors.hint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
              ),
              const SizedBox(height: 12),
              _LabeledFieldCard(
                icon: Icons.lock_rounded,
                label: 'Password',
                isFocused: _passwordFocus.hasFocus,
                trailing: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                  splashRadius: 18,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF6A84AD),
                    size: 22,
                  ),
                ),
                child: TextField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  enabled: !_loading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  style: const TextStyle(
                    fontSize: 16,
                    color: LoginColors.valueText,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      color: LoginColors.hint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D63ED),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF8CAAF3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledFieldCard extends StatelessWidget {
  const _LabeledFieldCard({
    required this.icon,
    required this.label,
    required this.child,
    this.isFocused = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final bool isFocused;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isFocused ? const Color(0x1F1D63ED) : const Color(0x126A86AF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 14,
                color: isFocused ? const Color(0xFF1D63ED) : const Color(0xFF6A86AF),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isFocused ? const Color(0xFF174FAF) : const Color(0xFF223A5A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused ? const Color(0xFF1D63ED) : const Color(0xFFD0DDF2),
              width: isFocused ? 1.4 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isFocused ? const Color(0x1F1D63ED) : const Color(0x0D1D63ED),
                blurRadius: isFocused ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: child),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
