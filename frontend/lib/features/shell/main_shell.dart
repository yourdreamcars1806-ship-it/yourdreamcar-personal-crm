import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ui/app_toast.dart';
import '../../services/auth_service.dart';
import '../expenses/presentation/expenses_page.dart';
import '../home/presentation/dashboard_page.dart';
import '../inventory/presentation/inventory_page.dart';
import '../marketplace/presentation/user_shell.dart';
import '../marketplace/presentation/admin_bids_page.dart';
import '../marketplace/presentation/admin_delivery_notes_page.dart';
import '../marketplace/presentation/admin_listing_requests_page.dart';
import '../orders/presentation/orders_page.dart';

/// Main app after login: bottom navigation + tab bodies.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.darkModeEnabled,
    required this.onThemeChanged,
  });

  final bool darkModeEnabled;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  int _totalCars = 0;
  int _activeUsers = 0;
  int _totalUsers = 0;
  bool _loggingOut = false;
  late bool _darkMode;
  final _expensesKey = GlobalKey<ExpensesPageState>();
  final _inventoryKey = GlobalKey<InventoryPageState>();
  final _dashboardKey = GlobalKey<DashboardPageState>();
  final _ordersKey = GlobalKey<OrdersPageState>();

  static const _labels = ['Home', 'Inventory', 'Orders', 'My expenses'];

  @override
  void initState() {
    super.initState();
    _darkMode = widget.darkModeEnabled;
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await AuthService().fetchAdminStats();
      if (!mounted) return;
      setState(() {
        _activeUsers = stats.activeUsers;
        _totalUsers = stats.totalUsers;
      });
    } catch (_) {}
  }

  void _onTab(int i) {
    if (i == _index) return;
    HapticFeedback.lightImpact();
    setState(() => _index = i);
    if (i == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dashboardKey.currentState?.refreshStats();
      });
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => UserShell(
          darkModeEnabled: _darkMode,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
      (route) => false,
    );
  }

  void _closeDrawerIfOpen() {
    final state = _scaffoldKey.currentState;
    if (state != null && state.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  void _goToAddCar() {
    _closeDrawerIfOpen();
    _onTab(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inventoryKey.currentState?.openAddCarForm();
    });
  }

  void _goToCarManager() {
    _closeDrawerIfOpen();
    _onTab(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inventoryKey.currentState?.openCarManager();
    });
  }

  void _goToAddOrder() {
    _closeDrawerIfOpen();
    if (_index != 2) {
      _onTab(2);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ordersKey.currentState?.openAddOrderDialog();
    });
  }

  void _goToAddExpense() {
    _closeDrawerIfOpen();
    if (_index != 3) {
      _onTab(3);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _expensesKey.currentState?.openAddExpenseDialog();
    });
  }

  void _openDrawer() {
    final state = _scaffoldKey.currentState;
    if (state != null && !state.isDrawerOpen) {
      _loadUserStats();
      state.openDrawer();
    }
  }

  void _toggleDarkMode(bool enabled) {
    setState(() => _darkMode = enabled);
    widget.onThemeChanged(enabled);
  }

  Future<void> _showChangePasswordDialog() async {
    _closeDrawerIfOpen();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          bool obscureCur = true;
          bool obscureNew = true;
          bool obscureConfirm = true;
          bool submitting = false;

          Future<void> submit(void Function(void Function()) setLocal) async {
            final cur = currentCtrl.text;
            final neu = newCtrl.text;
            final conf = confirmCtrl.text;
            if (cur.isEmpty) {
              AppToast.error(ctx, 'Enter current password');
              return;
            }
            if (neu.length < 6) {
              AppToast.error(ctx, 'New password must be at least 6 characters');
              return;
            }
            if (neu != conf) {
              AppToast.error(ctx, 'New password and confirmation do not match');
              return;
            }

            setLocal(() => submitting = true);
            try {
              await AuthService().changePassword(
                currentPassword: cur,
                newPassword: neu,
              );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (!mounted) return;
              AppToast.success(context, 'Password updated');
            } on AuthException catch (e) {
              if (ctx.mounted) {
                AppToast.error(ctx, e.message);
              }
            } catch (e) {
              if (ctx.mounted) {
                AppToast.error(ctx, 'Error: $e');
              }
            } finally {
              if (ctx.mounted) {
                setLocal(() => submitting = false);
              }
            }
          }

          return StatefulBuilder(
            builder: (ctx, setLocal) {
              final primary = const Color(0xFF031273);
              return AlertDialog(
                title: const Text('Change password'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: currentCtrl,
                        obscureText: obscureCur,
                        enabled: !submitting,
                        decoration: InputDecoration(
                          labelText: 'Current password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCur
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: submitting
                                ? null
                                : () => setLocal(() => obscureCur = !obscureCur),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newCtrl,
                        obscureText: obscureNew,
                        enabled: !submitting,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: submitting
                                ? null
                                : () => setLocal(() => obscureNew = !obscureNew),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmCtrl,
                        obscureText: obscureConfirm,
                        enabled: !submitting,
                        decoration: InputDecoration(
                          labelText: 'Confirm new password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: submitting
                                ? null
                                : () =>
                                    setLocal(() => obscureConfirm = !obscureConfirm),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: submitting ? null : () => submit(setLocal),
                    style: FilledButton.styleFrom(backgroundColor: primary),
                    child: submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Update'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: _labels[0],
      ),
      (
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2_rounded,
        label: _labels[1],
      ),
      (
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: _labels[2],
      ),
      (
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet_rounded,
        label: _labels[3],
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _darkMode ? const Color(0xFF0E1320) : const Color(0xFFF7FAFF),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: _darkMode ? const Color(0xFF11192A) : const Color(0xFFFDFEFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: const Color(0x121D63ED),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _darkMode ? const Color(0xFF23314D) : const Color(0xFFDCE9FF),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
          tooltip: 'Menu',
          onPressed: _openDrawer,
        ),
        title: Text(
          _labels[_index],
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
          ),
        ),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: () => _dashboardKey.currentState?.refreshStats(),
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF1D63ED),
              ),
            ),
          if (_index == 1)
            IconButton(
              tooltip: 'Add car',
              onPressed: () => _inventoryKey.currentState?.openAddCarForm(),
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFF1D63ED),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: Drawer(
        backgroundColor: _darkMode ? const Color(0xFF11192A) : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0x331D63ED), const Color(0x1A1D63ED)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x121D63ED),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Dream Car',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Menu',
                      style: TextStyle(
                        color: _darkMode ? const Color(0xFF9DB0CC) : const Color(0xFF5B769E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _darkMode ? const Color(0xFF162138) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _darkMode ? const Color(0xFF2F426A) : const Color(0xFFD4E4FF),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.sensors_rounded,
                              color: Color(0xFF16A34A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_activeUsers active users',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: _darkMode
                                        ? const Color(0xFFE6EEFF)
                                        : const Color(0xFF0F2442),
                                  ),
                                ),
                                Text(
                                  '$_totalUsers registered • last 15 min',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: _darkMode
                                        ? const Color(0xFF9DB0CC)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                value: _darkMode,
                onChanged: _toggleDarkMode,
                secondary: Icon(
                  _darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: const Color(0xFF1D63ED),
                ),
                title: Text(
                  'Dark mode',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: _darkMode
                    ? const Color(0x1A6F8FFF)
                    : const Color(0x0D1D63ED),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.directions_car_rounded,
                  color: Color(0xFF1D63ED),
                ),
                title: Text(
                  'Total cars',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1F1D63ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x661D63ED)),
                  ),
                  child: Text(
                    '$_totalCars',
                    style: TextStyle(
                      color: const Color(0xFF1D63ED),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                onTap: _goToCarManager,
              ),
              const SizedBox(height: 4),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF1D63ED),
                ),
                title: Text(
                  'Add Car',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                  ),
                ),
                onTap: _goToAddCar,
              ),
              const SizedBox(height: 4),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.gavel_rounded,
                  color: Color(0xFF1D63ED),
                ),
                title: Text(
                  'User bids',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                  ),
                ),
                onTap: () {
                  _closeDrawerIfOpen();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminBidsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.assignment_ind_rounded,
                  color: Color(0xFF1D63ED),
                ),
                title: Text(
                  'User car requests',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                  ),
                ),
                onTap: () {
                  _closeDrawerIfOpen();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminListingRequestsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF1D63ED),
                ),
                title: Text(
                  'Delivery notes',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                  ),
                ),
                onTap: () {
                  _closeDrawerIfOpen();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminDeliveryNotesPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.post_add_rounded,
                  color: Color(0xFF1D63ED),
                ),
                title: Text(
                  'Add Order',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                  ),
                ),
                onTap: _goToAddOrder,
              ),
              const SizedBox(height: 4),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.add_card_rounded,
                  color: Color(0xFF1D63ED),
                ),
                title: Text(
                  'Add Expense',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                  ),
                ),
                onTap: _goToAddExpense,
              ),
              const SizedBox(height: 4),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.lock_reset_rounded,
                  color: Color(0xFF031273),
                ),
                title: Text(
                  'Change password',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                  ),
                ),
                onTap: _showChangePasswordDialog,
              ),
              Divider(
                height: 1,
                color: _darkMode
                    ? const Color(0xFF2F426A)
                    : const Color(0x226CB6FF),
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF8A80),
                ),
                title: Text(
                  _loggingOut ? 'Logging out...' : 'Logout',
                  style: TextStyle(
                    color: _darkMode ? const Color(0xFFE6EEFF) : const Color(0xFF0F2442),
                  ),
                ),
                onTap: _loggingOut ? null : _logout,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          DashboardPage(key: _dashboardKey, onAddCarRequested: _goToAddCar),
          InventoryPage(
            key: _inventoryKey,
            onCarCountChanged: (value) {
              if (_totalCars != value) {
                setState(() => _totalCars = value);
              }
              _dashboardKey.currentState?.refreshStats();
            },
          ),
          OrdersPage(key: _ordersKey),
          ExpensesPage(key: _expensesKey),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF171B24),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0x333D4A63)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x3A000000),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(navItems.length, (i) {
              final selected = _index == i;
              final isCenterStyle = i == 2;
              final item = navItems[i];
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _onTab(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          offset: selected && isCenterStyle
                              ? const Offset(0, -0.18)
                              : Offset.zero,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            width: selected
                                ? (isCenterStyle ? 52 : 38)
                                : (isCenterStyle ? 34 : 30),
                            height: selected
                                ? (isCenterStyle ? 52 : 38)
                                : (isCenterStyle ? 34 : 30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? (isCenterStyle
                                        ? const Color(0xFF6F4BFF)
                                        : const Color(0xFF2F64F1))
                                  : Colors.transparent,
                              border: selected && isCenterStyle
                                  ? Border.all(
                                      color: const Color(0xAAA9B6FF),
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              selected ? item.selectedIcon : item.icon,
                              size: selected
                                  ? (isCenterStyle ? 24 : 22)
                                  : (isCenterStyle ? 20 : 19),
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF9DB0CC),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: selected ? 11.5 : 10.5,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? const Color(0xFF5D8CFF)
                                : const Color(0xFF93A6C3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
