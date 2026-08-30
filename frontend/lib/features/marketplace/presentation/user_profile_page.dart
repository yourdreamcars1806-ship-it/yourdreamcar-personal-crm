import 'package:flutter/material.dart';

import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/app_toast.dart';
import '../../../services/auth_service.dart';
import 'help_pages.dart';
import 'user_delivery_notes_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    required this.onLogout,
    required this.onLogin,
    required this.onDashboard,
    required this.onSellCar,
    required this.onCarRequests,
  });

  final VoidCallback onLogout;
  final VoidCallback onLogin;
  final VoidCallback onDashboard;
  final Future<void> Function() onSellCar;
  final VoidCallback onCarRequests;

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

  bool get _isLoggedIn => _email.isNotEmpty;

  String get _displayName {
    if (!_isLoggedIn) return 'Guest';
    if (_name.trim().isEmpty) return 'Dream Car member';
    return _name.trim();
  }

  String get _initials {
    final parts = _displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return 'G';
    if (list.length == 1) return list.first.characters.first.toUpperCase();
    return '${list.first.characters.first}${list.last.characters.first}'.toUpperCase();
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: MarketTheme.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: MarketColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: MarketColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Update password',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: MarketColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: current,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    filled: true,
                    fillColor: MarketColors.chipBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: next,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    filled: true,
                    fillColor: MarketColors.chipBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: MarketColors.primary,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, top + 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: MarketColors.text,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isLoggedIn
                      ? 'Account & activity'
                      : 'Sign in to bid, sell & track',
                  style: const TextStyle(
                    color: MarketColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileHeroCard(
                  initials: _initials,
                  name: _displayName,
                  email: _isLoggedIn ? _email : 'Browse without signing in',
                  isLoggedIn: _isLoggedIn,
                  onLogin: widget.onLogin,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickStatTile(
                        icon: Icons.space_dashboard_rounded,
                        label: 'Dashboard',
                        hint: 'Bids & ads',
                        color: MarketColors.primary,
                        onTap: _isLoggedIn ? widget.onDashboard : widget.onLogin,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickStatTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'Delivery',
                        hint: 'Your PDFs',
                        color: const Color(0xFF7C3AED),
                        onTap: _isLoggedIn
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const UserDeliveryNotesPage(),
                                  ),
                                )
                            : widget.onLogin,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _FeaturedActionCard(
                  title: _isLoggedIn ? 'Submit car request' : 'Sell your car',
                  subtitle: _isLoggedIn
                      ? 'Admin reviews · then published'
                      : 'Login to send photos & details',
                  gradient: const [Color(0xFF0F9D58), Color(0xFF059669)],
                  icon: Icons.directions_car_filled_rounded,
                  onTap: () async {
                    if (!_isLoggedIn) {
                      widget.onLogin();
                      return;
                    }
                    await widget.onSellCar();
                  },
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SectionHeader(
              title: 'Your activity',
              icon: Icons.bolt_rounded,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _MenuTile(
                icon: Icons.dashboard_customize_rounded,
                iconColor: MarketColors.primary,
                title: 'My dashboard',
                subtitle: 'Bids and listing requests',
                onTap: _isLoggedIn ? widget.onDashboard : widget.onLogin,
              ),
              if (_isLoggedIn)
                _MenuTile(
                  icon: Icons.fact_check_outlined,
                  iconColor: const Color(0xFF0F9D58),
                  title: 'My car requests',
                  subtitle: 'Pending, published, or rejected',
                  onTap: widget.onCarRequests,
                ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SectionHeader(
              title: 'Account',
              icon: Icons.shield_outlined,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (!_isLoggedIn)
                _MenuTile(
                  icon: Icons.login_rounded,
                  iconColor: MarketColors.primary,
                  title: 'Login / Sign up',
                  subtitle: 'Unlock bids, sell & dashboard',
                  onTap: widget.onLogin,
                  highlight: true,
                )
              else ...[
                _MenuTile(
                  icon: Icons.lock_reset_rounded,
                  iconColor: const Color(0xFF2563EB),
                  title: 'Update password',
                  subtitle: 'Keep your account secure',
                  onTap: _changePassword,
                ),
                _MenuTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFE11D48),
                  title: 'Logout',
                  subtitle: 'Sign out of this device',
                  onTap: widget.onLogout,
                  danger: true,
                ),
              ],
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SectionHeader(
              title: 'Help & legal',
              icon: Icons.help_outline_rounded,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _MenuTile(
                icon: Icons.support_agent_rounded,
                iconColor: MarketColors.primary,
                title: 'Support',
                subtitle: 'Email, FAQs, response times',
                onTap: () => _open(context, const SupportPage()),
              ),
              _MenuTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Terms & Conditions',
                subtitle: 'Marketplace rules',
                onTap: () => _open(context, const TermsPage()),
              ),
              _MenuTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF0F766E),
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () => _open(context, const PrivacyPolicyPage()),
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 96),
            child: Center(
              child: Text(
                'Your Dream Car · Verified marketplace',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MarketColors.muted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.isLoggedIn,
    required this.onLogin,
  });

  final String initials;
  final String name;
  final String email;
  final bool isLoggedIn;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003EA8), Color(0xFF0056D2), Color(0xFF3D8BFF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330056D2),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isLoggedIn)
            TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: MarketColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Sign in',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Member',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickStatTile extends StatelessWidget {
  const _QuickStatTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
          child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MarketColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: MarketColors.text,
                      ),
                    ),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 11,
                        color: MarketColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedActionCard extends StatelessWidget {
  const _FeaturedActionCard({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: gradient),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MarketColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: MarketColors.text,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
    this.danger = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? MarketColors.primary.withValues(alpha: 0.35)
              : danger
                  ? const Color(0xFFFECDD3)
                  : MarketColors.line,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: danger ? const Color(0xFFBE123C) : MarketColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MarketColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: danger ? const Color(0xFFBE123C) : MarketColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
