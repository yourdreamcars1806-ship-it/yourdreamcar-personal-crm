import 'package:flutter/material.dart';

import '../../../core/theme/brand_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/frost_card.dart';
import '../../../services/auth_service.dart';
import '../../../services/car_service.dart';
import '../../../services/expense_service.dart';
import '../../inventory/presentation/inventory_page.dart';

/// Home tab: live inventory stats + featured listings from API.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.onAddCarRequested});

  final VoidCallback? onAddCarRequested;

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  final _carsApi = CarService();
  final _authApi = AuthService();
  final _expenseApi = ExpenseService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  int _totalCars = 0;
  int _inStock = 0;
  int _outStock = 0;
  int _activeUsers = 0;
  int _totalUsers = 0;
  int _activeWindowMinutes = 15;
  List<CarRecord> _allCars = [];
  List<CarRecord> _featuredCars = [];
  bool _loading = true;
  String? _error;

  String _stockFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChanged);
    refreshStats();
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Call when returning to Home or after inventory changes.
  Future<void> refreshStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _carsApi.listCars(limit: 160, omitDescription: true),
        _authApi.fetchAdminStats(),
      ]);
      final res = results[0] as CarListResponse;
      final userStats = results[1] as AdminStatsRecord;
      if (!mounted) return;
      setState(() {
        _totalCars = res.total;
        _inStock = res.stock;
        _outStock = res.outstock;
        _allCars = res.cars;
        _featuredCars = res.cars.take(4).toList();
        _activeUsers = userStats.activeUsers;
        _totalUsers = userStats.totalUsers;
        _activeWindowMinutes = userStats.activeWindowMinutes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<_StatItem> _filteredStats() {
    final all = [
      _StatItem(
        label: 'Total',
        value: _totalCars,
        icon: Icons.directions_car_filled_rounded,
        accent: BrandColors.neonCyan,
      ),
      _StatItem(
        label: 'In Stock',
        value: _inStock,
        icon: Icons.inventory_2_rounded,
        accent: const Color(0xFF34D399),
      ),
      _StatItem(
        label: 'Sold',
        value: _outStock,
        icon: Icons.hourglass_empty_rounded,
        accent: const Color(0xFFFB923C),
      ),
    ];

    if (_stockFilter == 'In Stock') {
      return [all[0], all[1]];
    }
    if (_stockFilter == 'Sold') {
      return [all[0], all[2]];
    }
    return all;
  }

  List<CarRecord> _visibleCars() {
    final q = _searchController.text.trim().toLowerCase();
    final source = q.isEmpty ? _featuredCars : _allCars;
    return source
        .where((car) {
          if (_stockFilter == 'In Stock' && car.availability != 'stock') {
            return false;
          }
          if (_stockFilter == 'Sold' && car.availability == 'stock') {
            return false;
          }
          if (q.isEmpty) return true;
          final title = car.title.toLowerCase();
          final brandModel = '${car.brand} ${car.model}'.toLowerCase();
          final year = car.year.toString();
          return title.contains(q) ||
              brandModel.contains(q) ||
              year.contains(q);
        })
        .take(10)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _filteredStats();
    final visibleCars = _visibleCars();
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width < 380 ? 14.0 : 20.0;
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final isSearchFocused = _searchFocus.hasFocus;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0E1320), Color(0xFF131C2E), Color(0xFF172339)]
              : const [Color(0xFFF7FAFF), Color(0xFFF2F7FF), Color(0xFFEAF2FF)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: BrandColors.neonCyan,
          onRefresh: refreshStats,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    8,
                    horizontalPad,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardHeroHeader(
                        badge: 'ADMIN',
                        title: 'Dashboard',
                        subtitle: 'Live inventory, users & showroom overview',
                        margin: EdgeInsets.zero,
                        stats: [
                          ('Cars', _loading ? '—' : '$_totalCars'),
                          ('In Stock', _loading ? '—' : '$_inStock'),
                          ('Active', _loading ? '—' : '$_activeUsers'),
                        ],
                        trailing: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Material(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: refreshStats,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(Icons.refresh_rounded, color: Colors.white),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF162138) : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSearchFocused
                                ? const Color(0xFF4E9BFF)
                                : (isDark
                                      ? const Color(0xFF3D5D90)
                                      : const Color(0xFF6EA9FF)),
                            width: isSearchFocused ? 2 : 1.7,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSearchFocused
                                  ? const Color(0x224E9BFF)
                                  : const Color(0x176EA9FF),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 14, right: 8),
                              child: Icon(
                                Icons.search_rounded,
                                color: isDark
                                    ? const Color(0xFFB8C6DF)
                                    : const Color(0xFF2D2D2D),
                                size: 29,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                onChanged: (_) => setState(() {}),
                                onTapOutside: (_) =>
                                    FocusScope.of(context).unfocus(),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? const Color(0xFFE6EEFF)
                                      : const Color(0xFF213A5E),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'search products...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 17,
                                  ),
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF8EA3C4)
                                        : const Color(0xFFB2B2B2),
                                    fontSize: 34 / 2,
                                  ),
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: hasQuery
                                  ? IconButton(
                                      key: const ValueKey('clear'),
                                      tooltip: 'Clear',
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                        color: isDark
                                            ? const Color(0xFF9DB0CC)
                                            : const Color(0xFF7E95B6),
                                      ),
                                    )
                                  : const SizedBox(
                                      key: ValueKey('spacer'),
                                      width: 14,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _StockFilterChip(
                              label: 'All',
                              selected: _stockFilter == 'All',
                              onTap: () => setState(() => _stockFilter = 'All'),
                            ),
                            const SizedBox(width: 8),
                            _StockFilterChip(
                              label: 'In Stock',
                              selected: _stockFilter == 'In Stock',
                              onTap: () =>
                                  setState(() => _stockFilter = 'In Stock'),
                            ),
                            const SizedBox(width: 8),
                            _StockFilterChip(
                              label: 'Sold',
                              selected: _stockFilter == 'Sold',
                              onTap: () =>
                                  setState(() => _stockFilter = 'Sold'),
                            ),
                            if (hasQuery) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0x1F6F8FFF)
                                      : const Color(0x141D63ED),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0x667FA2DB)
                                        : const Color(0x331D63ED),
                                  ),
                                ),
                                child: Text(
                                  '${visibleCars.length} result${visibleCars.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF8DB2FF)
                                        : const Color(0xFF1D63ED),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0x33FF8A80),
                            border: Border.all(color: const Color(0x55FF8A80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                color: Color(0xFFFFCCBC),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Could not load stats. Pull to retry.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: const Color(0xFF7A1D1D),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: refreshStats,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad - 4,
                    12,
                    horizontalPad - 4,
                    8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Inventory summary',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFE6EEFF)
                                    : const Color(0xFF16345E),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _stockFilter,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF8DB2FF)
                                    : const Color(0xFF1D63ED),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final cardWidth = ((maxWidth - 10) / 2).clamp(
                              140.0,
                              360.0,
                            );
                            final statTiles = stats
                                .map(
                                  (s) => SizedBox(
                                    width: cardWidth,
                                    child: _MobileStatChip(
                                      label: s.label,
                                      value: _loading ? '—' : '${s.value}',
                                      icon: s.icon,
                                      accent: s.accent,
                                      dimmed: _loading,
                                    ),
                                  ),
                                )
                                .toList();
                            statTiles.add(
                              SizedBox(
                                width: cardWidth,
                                child: _AddCarActionCard(
                                  onTap: _openAddCarForm,
                                  dimmed: _loading,
                                ),
                              ),
                            );

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: statTiles,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    4,
                    horizontalPad,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App users',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFE6EEFF)
                              : const Color(0xFF16345E),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live count — active in last $_activeWindowMinutes min',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: BrandColors.muted.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = ((constraints.maxWidth - 10) / 2)
                              .clamp(140.0, 360.0);
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _MobileStatChip(
                                  label: 'Active now',
                                  value: _loading ? '—' : '$_activeUsers',
                                  icon: Icons.sensors_rounded,
                                  accent: const Color(0xFF22C55E),
                                  dimmed: _loading,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _MobileStatChip(
                                  label: 'Total users',
                                  value: _loading ? '—' : '$_totalUsers',
                                  icon: Icons.people_alt_rounded,
                                  accent: const Color(0xFF8B5CF6),
                                  dimmed: _loading,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    8,
                    horizontalPad,
                    10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: BrandColors.neonCyan,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Featured cars',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F2442),
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              visibleCars.isEmpty && !_loading
                                  ? 'Add vehicles from Inventory to show here'
                                  : _searchController.text.trim().isEmpty
                                  ? 'From your showroom inventory'
                                  : 'Showing search results',
                              style: TextStyle(
                                fontSize: 12,
                                color: BrandColors.muted.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (visibleCars.isEmpty && !_loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad - 6,
                      0,
                      horizontalPad - 6,
                      12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCE9FF)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 40,
                            color: BrandColors.muted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'No cars yet. Open Inventory → Add Car to list your first vehicle.',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                color: BrandColors.muted.withValues(
                                  alpha: 0.95,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad - 6,
                    0,
                    horizontalPad - 6,
                    12,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final car = visibleCars[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeaturedCarCard(
                          car: car,
                          onViewDetails: () => _openCarDetails(car),
                          onAddExpense: () => _openAddExpenseSheet(car),
                        ),
                      );
                    }, childCount: visibleCars.length),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    0,
                    horizontalPad,
                    32,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDCE9FF)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sync_rounded,
                          color: BrandColors.muted.withValues(alpha: 0.9),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pull down on this screen anytime to refresh live counts.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: BrandColors.muted.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                      ],
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

  void _openCarDetails(CarRecord car) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => InventoryCarDetailsPage(car: car)),
    );
  }

  void _openAddCarForm() {
    final callback = widget.onAddCarRequested;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const InventoryPage()),
    );
  }

  Future<void> _openAddExpenseSheet(CarRecord car) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add car expense',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2442),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                car.title.isNotEmpty ? car.title : '${car.brand} ${car.model}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5B769E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: _expenseFieldDecoration(
                  'Title (fuel, service, challan...)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _expenseFieldDecoration('Price / amount'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (title.isEmpty || amount == null || amount <= 0) {
                    AppToast.error(ctx, 'Enter valid title and price');
                    return;
                  }
                  try {
                    await _expenseApi.createExpense(
                      title: title,
                      amount: amount,
                      carId: car.id,
                      carLabel: car.title.isNotEmpty
                          ? car.title
                          : '${car.brand} ${car.model}',
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    AppToast.success(context, 'Expense added to history');
                  } catch (e) {
                    if (!ctx.mounted) return;
                    AppToast.error(ctx, e.toString());
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D63ED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Add expense',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _expenseFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7A93B7)),
      filled: true,
      fillColor: const Color(0xFFF7FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7E5FF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7E5FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1D63ED)),
      ),
    );
  }

}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
}

class _StockFilterChip extends StatelessWidget {
  const _StockFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: selected
                  ? const Color(0xFF1D63ED)
                  : (isDark ? const Color(0xFF162138) : Colors.white),
              border: Border.all(
                color: selected
                    ? const Color(0xFF1D63ED)
                    : (isDark ? const Color(0xFF2F426A) : const Color(0xFFD4E4FF)),
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x261D63ED),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark ? const Color(0xFF9DB0CC) : const Color(0xFF47648F)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCarCard extends StatelessWidget {
  const _FeaturedCarCard({
    required this.car,
    required this.onViewDetails,
    required this.onAddExpense,
  });

  final CarRecord car;
  final VoidCallback onViewDetails;
  final VoidCallback onAddExpense;

  String _fmtPrice(double v) {
    if (v >= 100000) {
      return '₹ ${(v / 100000).toStringAsFixed(2)} L';
    }
    return '₹ ${v.toStringAsFixed(0)}';
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final inStock = car.availability == 'stock';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final imageWidth = screenWidth < 380 ? 112.0 : 126.0;
    final imageHeight = screenWidth < 380 ? 98.0 : 112.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF162138), Color(0xFF1A2942)]
                  : [Colors.white, const Color(0xFFF6FAFF)],
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF2F426A) : const Color(0xFFDCE9FF),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A0A3A7A),
                blurRadius: 11,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: imageWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: imageWidth,
                          height: imageHeight,
                          child: Image.network(
                            car.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFFF1F6FF),
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: BrandColors.neonCyan,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: const Color(0xFFF1F6FF),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.directions_car_filled_rounded,
                                    size: 34,
                                    color: BrandColors.muted.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D63ED),
                          side: const BorderSide(color: Color(0x661D63ED)),
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          textStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FilledButton.icon(
                        onPressed: onAddExpense,
                        icon: const Icon(Icons.add_card_rounded, size: 16),
                        label: const Text('Add expense'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0x1F1D63ED),
                          foregroundColor: const Color(0xFF1D63ED),
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          textStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                car.title.isNotEmpty
                                    ? car.title
                                    : '${car.brand} ${car.model}',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFE6EEFF)
                                      : const Color(0xFF0F2442),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: inStock
                                    ? const Color(0xFF34D399).withValues(alpha: 0.2)
                                    : const Color(0xFFFB923C).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: inStock
                                      ? const Color(
                                          0xFF34D399,
                                        ).withValues(alpha: 0.55)
                                      : const Color(
                                          0xFFFB923C,
                                        ).withValues(alpha: 0.55),
                                ),
                              ),
                              child: Text(
                                inStock ? 'In Stock' : 'Sold',
                                style: TextStyle(
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.w800,
                                  color: inStock
                                      ? const Color(0xFF0B7A3E)
                                      : const Color(0xFFAD5B00),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${car.brand} ${car.model} · ${car.year} · ${car.fuelType}',
                          style: TextStyle(
                            fontSize: 11.3,
                            color: isDark
                                ? const Color(0xFF9DB0CC)
                                : BrandColors.muted.withValues(alpha: 0.95),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF101B30) : const Color(0xFFF9FBFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2F426A)
                                  : const Color(0xFFDCE9FF),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _PriceLabel(
                                  label: 'Buy (admin)',
                                  value: _fmtPrice(car.buyPrice),
                                  strong: false,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: const Color(0xFFDCE9FF),
                              ),
                              Expanded(
                                child: _PriceLabel(
                                  label: 'Sell (public)',
                                  value: _fmtPrice(car.sellPrice),
                                  strong: true,
                                  alignEnd: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _DatePill(
                                  label: 'Buy',
                                  value: _fmtDate(car.buyDate),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: car.saleDate != null
                                    ? _DatePill(
                                        label: 'Sell',
                                        value: _fmtDate(car.saleDate!),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: isDark
                                              ? const Color(0xFF101B30)
                                              : const Color(0xFFF6F9FF),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF2F426A)
                                                : const Color(0xFFD5E5FF),
                                          ),
                                        ),
                                        child: Text(
                                          'Sell: —',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: BrandColors.muted.withValues(
                                              alpha: 0.95,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark ? const Color(0xFF101B30) : const Color(0xFFF6F9FF),
        border: Border.all(
          color: isDark ? const Color(0xFF2F426A) : const Color(0xFFD5E5FF),
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10.5,
          color: isDark
              ? const Color(0xFF9DB0CC)
              : BrandColors.muted.withValues(alpha: 0.95),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({
    required this.label,
    required this.value,
    required this.strong,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool strong;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.8,
            color: isDark
                ? const Color(0xFF9DB0CC)
                : BrandColors.muted.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: strong ? 17 : 14.5,
              fontWeight: FontWeight.w800,
              color: strong
                  ? const Color(0xFF1D63ED)
                  : (isDark ? const Color(0xFFB8C6DF) : const Color(0xFF5B769E)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact stat chip for dashboard.
class _MobileStatChip extends StatelessWidget {
  const _MobileStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.dimmed = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxHeight < 96 || c.maxWidth < 120;
        final ultraCompact = c.maxHeight < 72 || c.maxWidth < 105;
        final padH = ultraCompact ? 8.0 : (compact ? 10.0 : 11.0);
        final padV = ultraCompact ? 5.0 : (compact ? 8.0 : 9.0);
        final iconSize = ultraCompact ? 14.0 : (compact ? 17.0 : 18.0);
        final iconPad = ultraCompact ? 4.0 : 6.0;
        final valueSize = ultraCompact ? 16.0 : (compact ? 20.0 : 22.0);
        final labelSize = ultraCompact ? 9.0 : (compact ? 10.0 : 11.0);

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: dimmed ? 0.55 : 1,
          child: Container(
            height: 88,
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white,
              border: Border.all(color: accent.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPad),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: iconSize),
                ),
                SizedBox(height: ultraCompact ? 3 : (compact ? 6 : 8)),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F2442),
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ultraCompact ? 0 : 1),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w600,
                      color: BrandColors.muted.withValues(alpha: 0.95),
                      letterSpacing: ultraCompact ? 0 : 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddCarActionCard extends StatelessWidget {
  const _AddCarActionCard({required this.onTap, this.dimmed = false});

  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: dimmed ? 0.65 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0x111D63ED),
              border: Border.all(color: const Color(0x801D63ED)),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final compact = c.maxHeight < 76 || c.maxWidth < 125;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_rounded,
                      color: const Color(0xFF1D63ED),
                      size: compact ? 20 : 24,
                    ),
                    SizedBox(height: compact ? 4 : 7),
                    Text(
                      'Add car',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F2442),
                      ),
                    ),
                    if (!compact) const SizedBox(height: 1),
                    if (!compact)
                      const Text(
                        'Open form',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5B769E),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
