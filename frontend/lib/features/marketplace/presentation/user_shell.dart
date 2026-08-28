import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/open_panel.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/car_alert_service.dart';
import '../../../services/car_catalog_service.dart';
import '../../../services/wishlist_service.dart';
import 'my_ads_page.dart';
import 'new_car_banner.dart';
import 'sell_request_page.dart';
import 'sold_cars_page.dart';
import 'user_home_page.dart';
import 'user_profile_page.dart';
import 'user_search_page.dart';
import 'wishlist_page.dart';

class UserShell extends StatefulWidget {
  const UserShell({
    super.key,
    required this.darkModeEnabled,
    required this.onThemeChanged,
  });

  final bool darkModeEnabled;
  final ValueChanged<bool> onThemeChanged;

  static VoidCallback? openDashboard;

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;
  int _adsTick = 0;
  int _sessionTick = 0;

  @override
  void initState() {
    super.initState();
    CarAlertService.instance.start();
    WishlistService.instance.start();
    CarCatalogService.instance.load();
    UserShell.openDashboard = _openDashboard;
  }

  @override
  void dispose() {
    if (UserShell.openDashboard == _openDashboard) {
      UserShell.openDashboard = null;
    }
    super.dispose();
  }

  Future<void> _openDashboard() async {
    final ok = await ensureLoggedIn(
      context,
      darkModeEnabled: widget.darkModeEnabled,
      onThemeChanged: widget.onThemeChanged,
    );
    if (!mounted || !ok) return;
    setState(() => _sessionTick++);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MyAdsPage(
          key: ValueKey('ads-$_adsTick-$_sessionTick'),
          onAddCar: _openAddCar,
          onBrowseCars: () {
            Navigator.of(context).pop();
            _go(1);
          },
        ),
      ),
    );
  }

  Future<void> _go(int i) async {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  Future<void> _openAddCar() async {
    final ok = await ensureLoggedIn(
      context,
      darkModeEnabled: widget.darkModeEnabled,
      onThemeChanged: widget.onThemeChanged,
    );
    if (!mounted || !ok) return;
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SellRequestPage()),
    );
    if (!mounted) return;
    if (submitted == true) {
      setState(() {
        _adsTick++;
        _sessionTick++;
      });
      if (!Navigator.of(context).canPop()) {
        await _openDashboard();
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.clearSession();
    if (!mounted) return;
    setState(() {
      _index = 0;
      _sessionTick++;
    });
  }

  Future<void> _openLogin() async {
    final ok = await ensureLoggedIn(
      context,
      darkModeEnabled: widget.darkModeEnabled,
      onThemeChanged: widget.onThemeChanged,
    );
    if (!mounted || !ok) return;
    setState(() => _sessionTick++);
  }

  Widget _buildPage() {
    switch (_index) {
      case 1:
        return const UserSearchPage(key: ValueKey('search'));
      case 2:
        return SoldCarsPage(
          key: const ValueKey('sold'),
          onBrowseCars: () => _go(0),
        );
      case 3:
        return WishlistPage(
          key: const ValueKey('wishlist'),
          onBrowseCars: () => _go(1),
        );
      case 4:
        return UserProfilePage(
          key: ValueKey('profile-$_sessionTick'),
          onLogout: _logout,
          onLogin: _openLogin,
          onDashboard: _openDashboard,
        );
      case 0:
      default:
        return UserHomePage(
          key: const ValueKey('home'),
          onExplore: () => _go(1),
          onSell: _openAddCar,
          onOpenMenu: () => _go(4),
          onWishlist: () => _go(3),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MarketTheme.data(),
      child: Scaffold(
        backgroundColor: MarketColors.bg,
        extendBody: true,
        body: Stack(
          children: [
            _buildPage(),
            const NewCarBannerLayer(),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: WishlistService.instance,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SafeArea(
                top: false,
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003EA8), Color(0xFF0056D2)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x400056D2),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                    child: Row(
                      children: [
                        _NavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: 'Home',
                          selected: _index == 0,
                          onTap: () => _go(0),
                        ),
                        _NavItem(
                          icon: Icons.search_rounded,
                          activeIcon: Icons.search_rounded,
                          label: 'Search',
                          selected: _index == 1,
                          onTap: () => _go(1),
                        ),
                        _NavItem(
                          icon: Icons.sell_outlined,
                          activeIcon: Icons.sell_rounded,
                          label: 'Sold',
                          selected: _index == 2,
                          onTap: () => _go(2),
                        ),
                        _NavItem(
                          icon: Icons.favorite_border_rounded,
                          activeIcon: Icons.favorite_rounded,
                          label: 'Saved',
                          selected: _index == 3,
                          badge: WishlistService.instance.count,
                          onTap: () => _go(3),
                        ),
                        _NavItem(
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: 'You',
                          selected: _index == 4,
                          onTap: () => _go(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xB3FFFFFF);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  color: color,
                  size: selected ? 24 : 22,
                ),
                if (badge > 0)
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 15),
                      height: 15,
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 1.4),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
