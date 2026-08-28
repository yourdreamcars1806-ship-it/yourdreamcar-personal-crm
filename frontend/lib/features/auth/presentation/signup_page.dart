import 'package:flutter/material.dart';

import '../../../core/navigation/open_panel.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/auth_chrome.dart';
import '../../../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({
    super.key,
    required this.darkModeEnabled,
    required this.onThemeChanged,
    this.popOnSuccess = false,
  });

  final bool darkModeEnabled;
  final ValueChanged<bool> onThemeChanged;
  final bool popOnSuccess;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_tick);
    _emailFocus.addListener(_tick);
    _passwordFocus.addListener(_tick);
    _confirmFocus.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (name.length < 2) {
      AppToast.error(context, 'Enter your full name');
      return;
    }
    if (!email.contains('@') || email.length < 4) {
      AppToast.error(context, 'Enter a valid email');
      return;
    }
    if (password.length < 6) {
      AppToast.error(context, 'Password must be at least 6 characters');
      return;
    }
    if (password != _confirmCtrl.text) {
      AppToast.error(context, 'Passwords do not match');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final result = await _auth.register(
        email: email,
        password: password,
        name: name,
      );
      if (!mounted) return;
      finishAuthSession(
        context,
        result: result,
        popCount: widget.popOnSuccess ? 2 : 0,
        darkModeEnabled: widget.darkModeEnabled,
        onThemeChanged: widget.onThemeChanged,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      title: 'Create account',
      subtitle: 'Sign up to buy and sell cars',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              icon: Icons.person_outline_rounded,
              hint: 'Full name',
              controller: _nameCtrl,
              focusNode: _nameFocus,
              enabled: !_loading,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              onSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            AuthField(
              icon: Icons.mail_outline_rounded,
              hint: 'Email',
              controller: _emailCtrl,
              focusNode: _emailFocus,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            AuthField(
              icon: Icons.lock_outline_rounded,
              hint: 'Password',
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              enabled: !_loading,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _confirmFocus.requestFocus(),
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: MarketColors.muted,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AuthField(
              icon: Icons.lock_reset_rounded,
              hint: 'Confirm password',
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              enabled: !_loading,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _submit(),
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: MarketColors.muted,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'Sign Up',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: MarketColors.muted),
                ),
                GestureDetector(
                  onTap: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Login',
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
