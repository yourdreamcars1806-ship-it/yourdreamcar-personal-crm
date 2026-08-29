import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ui/app_logo.dart';

/// Professional admin navigation drawer.
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({
    super.key,
    required this.darkMode,
    required this.activeUsers,
    required this.totalUsers,
    required this.totalCars,
    required this.loggingOut,
    required this.onDarkModeChanged,
    required this.onCarManager,
    required this.onAddCar,
    required this.onUserBids,
    required this.onListingRequests,
    required this.onDeliveryNotes,
    required this.onAddOrder,
    required this.onAddExpense,
    required this.onChangePassword,
    required this.onLogout,
  });

  final bool darkMode;
  final int activeUsers;
  final int totalUsers;
  final int totalCars;
  final bool loggingOut;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onCarManager;
  final VoidCallback onAddCar;
  final VoidCallback onUserBids;
  final VoidCallback onListingRequests;
  final VoidCallback onDeliveryNotes;
  final VoidCallback onAddOrder;
  final VoidCallback onAddExpense;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  static const _primary = Color(0xFF0056D2);

  @override
  Widget build(BuildContext context) {
    final bg = darkMode ? const Color(0xFF0B1220) : const Color(0xFFF8FAFD);
    final text = darkMode ? const Color(0xFFE8EEF9) : const Color(0xFF0F172A);
    final muted = darkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              darkMode: darkMode,
              activeUsers: activeUsers,
              totalUsers: totalUsers,
              totalCars: totalCars,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                children: [
                  _SectionLabel('Overview', muted: muted),
                  _NavTile(
                    icon: Icons.dashboard_rounded,
                    label: 'Total cars',
                    subtitle: 'Manage inventory',
                    badge: '$totalCars',
                    darkMode: darkMode,
                    accent: _primary,
                    onTap: onCarManager,
                  ),
                  _SectionLabel('Marketplace', muted: muted),
                  _NavTile(
                    icon: Icons.gavel_rounded,
                    label: 'User bids',
                    subtitle: 'Review & adjust offers',
                    darkMode: darkMode,
                    accent: const Color(0xFF7C3AED),
                    onTap: onUserBids,
                  ),
                  _NavTile(
                    icon: Icons.assignment_ind_rounded,
                    label: 'Car requests',
                    subtitle: 'User listing submissions',
                    darkMode: darkMode,
                    accent: const Color(0xFF0891B2),
                    onTap: onListingRequests,
                  ),
                  _NavTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Delivery notes',
                    subtitle: 'PDF & handover docs',
                    darkMode: darkMode,
                    accent: const Color(0xFF059669),
                    onTap: onDeliveryNotes,
                  ),
                  _SectionLabel('Quick actions', muted: muted),
                  _NavTile(
                    icon: Icons.add_circle_rounded,
                    label: 'Add car',
                    darkMode: darkMode,
                    accent: _primary,
                    compact: true,
                    onTap: onAddCar,
                  ),
                  _NavTile(
                    icon: Icons.post_add_rounded,
                    label: 'Add order',
                    darkMode: darkMode,
                    accent: _primary,
                    compact: true,
                    onTap: onAddOrder,
                  ),
                  _NavTile(
                    icon: Icons.add_card_rounded,
                    label: 'Add expense',
                    darkMode: darkMode,
                    accent: _primary,
                    compact: true,
                    onTap: onAddExpense,
                  ),
                  _SectionLabel('Account', muted: muted),
                  SwitchListTile.adaptive(
                    value: darkMode,
                    onChanged: onDarkModeChanged,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      'Dark mode',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: text,
                        fontSize: 14,
                      ),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: _primary,
                        size: 20,
                      ),
                    ),
                  ),
                  _NavTile(
                    icon: Icons.lock_reset_rounded,
                    label: 'Change password',
                    darkMode: darkMode,
                    accent: const Color(0xFF6366F1),
                    compact: true,
                    onTap: onChangePassword,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Material(
                color: darkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: loggingOut ? null : onLogout,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: darkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loggingOut ? 'Logging out…' : 'Sign out',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: text,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: muted, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.darkMode,
    required this.activeUsers,
    required this.totalUsers,
    required this.totalCars,
  });

  final bool darkMode;
  final int activeUsers;
  final int totalUsers;
  final int totalCars;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0056D2), Color(0xFF003EA8), Color(0xFF002D7A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400056D2),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(round: true, width: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Dream Car',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Admin Console',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ADMIN',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(icon: Icons.sensors_rounded, label: '$activeUsers live'),
              const SizedBox(width: 8),
              _StatPill(icon: Icons.people_rounded, label: '$totalUsers users'),
              const SizedBox(width: 8),
              _StatPill(icon: Icons.garage_rounded, label: '$totalCars cars'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.muted});

  final String text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: muted,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.darkMode,
    required this.accent,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final bool darkMode;
  final Color accent;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = darkMode ? const Color(0xFFE8EEF9) : const Color(0xFF0F172A);
    final muted = darkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final tileBg = darkMode ? const Color(0xFF111827) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: tileBg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: darkMode ? const Color(0xFF1E293B) : const Color(0xFFE8EEF5),
              ),
              boxShadow: darkMode
                  ? const []
                  : const [
                      BoxShadow(
                        color: Color(0x060056D2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 36 : 42,
                  height: compact ? 36 : 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(compact ? 10 : 12),
                  ),
                  child: Icon(icon, color: accent, size: compact ? 18 : 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 13.5 : 14.5,
                          color: text,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: muted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
