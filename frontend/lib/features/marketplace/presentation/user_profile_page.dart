import 'package:flutter/material.dart';

import '../../../core/theme/market_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/auth_service.dart';
import 'delivery_note_form_page.dart';
import 'help_pages.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    required this.onLogout,
    required this.onLogin,
    required this.onDashboard,
  });

  final VoidCallback onLogout;
  final VoidCallback onLogin;
  final VoidCallback onDashboard;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String _email = '';
  String _name = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = await AuthService.getStoredEmail();
    final name = await AuthService.getStoredName();
    if (!mounted) return;
    setState(() {
      _email = email;
      _name = name;
    });
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      await AuthService().changePassword(
        currentPassword: current.text,
        newPassword: next.text,
      );
      if (!mounted) return;
      AppToast.success(context, 'Password updated');
    } on AuthException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } finally {
      current.dispose();
      next.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 96),
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: MarketColors.text,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF003EA8), Color(0xFF0056D2), Color(0xFF3D8BFF)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x400056D2),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _email.isEmpty
                          ? 'Guest'
                          : (_name.isEmpty ? 'Dream Car user' : _name),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email.isEmpty
                          ? 'Browse cars without login'
                          : _email,
                      style: const TextStyle(color: Color(0xCCFFFFFF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: const Icon(
            Icons.space_dashboard_rounded,
            color: MarketColors.primary,
          ),
          title: const Text('Dashboard'),
          subtitle: const Text('My bids and car requests'),
          trailing: const Icon(Icons.chevron_right),
          onTap: widget.onDashboard,
        ),
        const SizedBox(height: 8),
        if (_email.isEmpty)
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.login, color: MarketColors.primary),
            title: const Text('Login / Sign up'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onLogin,
          )
        else ...[
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeliveryNoteFormPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      MarketColors.primary.withValues(alpha: 0.06),
                      const Color(0xFF3D8BFF).withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFD4E4FF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF031273), Color(0xFF0056D2)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehicle delivery note',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: MarketColors.text,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Professional delivery form • PDF for records',
                            style: TextStyle(fontSize: 12.5, color: MarketColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: MarketColors.primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.lock_outline, color: MarketColors.primary),
            title: const Text('Update password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.logout, color: Color(0xFFC0392B)),
            title: const Text('Logout'),
            onTap: widget.onLogout,
          ),
        ],
        const SizedBox(height: 22),
        const Text(
          'Help & legal',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: MarketColors.text,
          ),
        ),
        const SizedBox(height: 10),
        _profileLink(
          icon: Icons.support_agent_rounded,
          title: 'Support',
          onTap: () => _open(context, const SupportPage()),
        ),
        const SizedBox(height: 8),
        _profileLink(
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          onTap: () => _open(context, const TermsPage()),
        ),
        const SizedBox(height: 8),
        _profileLink(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => _open(context, const PrivacyPolicyPage()),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _profileLink({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: MarketColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
