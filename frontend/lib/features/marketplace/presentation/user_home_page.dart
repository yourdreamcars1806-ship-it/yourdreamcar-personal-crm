import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/format/inr.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/car_network_image.dart';
import '../../../core/ui/frost_card.dart';
import '../../../core/ui/live_bid_timer.dart';
import '../../../core/ui/stock_status_badge.dart';
import '../../../core/ui/sold_overlay.dart';
import '../../../core/ui/wish_button.dart';
import '../../../services/car_alert_service.dart';
import '../../../services/car_catalog_service.dart';
import '../../../services/car_service.dart';
import '../../../services/wishlist_service.dart';
import 'new_car_arrival_ticker.dart';
import 'notifications_page.dart';
import 'user_car_details_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({
    super.key,
    required this.onExplore,
    required this.onSell,
    required this.onOpenMenu,
    required this.onWishlist,
  });

  final VoidCallback onExplore;
  final VoidCallback onSell;
  final VoidCallback onOpenMenu;
  final VoidCallback onWishlist;

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _searchCtrl = TextEditingController();
  List<CarRecord> _cars = [];
  String _category = 'All Cars';
  int _budget = 0;
  bool _loading = true;

  static const _categories = [
    ('All Cars', Icons.grid_view_rounded),
    ('Hatchback', Icons.directions_car_filled_rounded),
    ('Sedan', Icons.airport_shuttle_outlined),
    ('SUV', Icons.directions_car_rounded),
    ('Luxury', Icons.workspace_premium_rounded),
    ('Electric', Icons.bolt_rounded),
    ('MPV', Icons.airport_shuttle_rounded),
  ];

  static const _budgets = [
    'Any price',
    'Under ₹5L',
    '₹5–10L',
    '₹10–20L',
    '₹20L+',
  ];

  @override
  void initState() {
    super.initState();
    _cars = CarCatalogService.instance.cars;
    _loading = !CarCatalogService.instance.hasCars;
    CarAlertService.instance.addListener(_onAlerts);
    WishlistService.instance.addListener(_onAlerts);
    CarCatalogService.instance.addListener(_onCatalog);
    _pullCatalog();
  }

  void _onCatalog() {
    if (!mounted) return;
    setState(() {
      _cars = CarCatalogService.instance.cars;
      _loading = CarCatalogService.instance.isLoading && _cars.isEmpty;
    });
  }

  void _onAlerts() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CarAlertService.instance.removeListener(_onAlerts);
    WishlistService.instance.removeListener(_onAlerts);
    CarCatalogService.instance.removeListener(_onCatalog);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pullCatalog() async {
    final catalog = CarCatalogService.instance;
    if (!catalog.hasCars) {
      setState(() => _loading = true);
    } else {
      _cars = catalog.cars;
      _loading = false;
    }
    try {
      await catalog.load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    CarCatalogService.instance.invalidate();
    await _pullCatalog();
  }

  Future<void> _openNotifications() async {
    await CarAlertService.instance.markAllRead();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
    );
  }

  bool _inBudget(CarRecord c) {
    final p = c.sellPrice;
    switch (_budget) {
      case 1:
        return p < 500000;
      case 2:
        return p >= 500000 && p < 1000000;
      case 3:
        return p >= 1000000 && p < 2000000;
      case 4:
        return p >= 2000000;
      default:
        return true;
    }
  }

  List<CarRecord> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _cars.where((c) {
      final blob =
          '${c.title} ${c.brand} ${c.model} ${c.description}'.toLowerCase();
      if (q.isNotEmpty && !blob.contains(q)) return false;
      if (!_inBudget(c)) return false;
      switch (_category) {
        case 'Hatchback':
          return blob.contains('hatch') ||
              blob.contains('swift') ||
              blob.contains('i20') ||
              blob.contains('polo') ||
              blob.contains('alto') ||
              blob.contains('wagon');
        case 'Sedan':
          return blob.contains('sedan') ||
              blob.contains('city') ||
              blob.contains('ciaz') ||
              blob.contains('verna') ||
              blob.contains('dzire');
        case 'SUV':
          return blob.contains('suv') ||
              blob.contains('creta') ||
              blob.contains('nexon') ||
              blob.contains('brezza') ||
              blob.contains('xuv') ||
              blob.contains('scorpio') ||
              blob.contains('thar');
        case 'Luxury':
          return blob.contains('bmw') ||
              blob.contains('audi') ||
              blob.contains('mercedes') ||
              blob.contains('jaguar') ||
              blob.contains('luxury');
        case 'Electric':
          return blob.contains('electric') ||
              blob.contains(' ev') ||
              blob.contains('nexon.ev') ||
              blob.contains('tiago.ev');
        case 'MPV':
          return blob.contains('mpv') ||
              blob.contains('ertiga') ||
              blob.contains('innova') ||
              blob.contains('xl6') ||
              blob.contains('carens');
        default:
          return true;
      }
    }).toList();
    list.sort((a, b) {
      final soldCmp = (a.isSold ? 1 : 0).compareTo(b.isSold ? 1 : 0);
      if (soldCmp != 0) return soldCmp;
      return b.buyDate.compareTo(a.buyDate);
    });
    return list;
  }

  List<CarRecord> get _latest {
    final list = [..._cars];
    list.sort((a, b) => b.buyDate.compareTo(a.buyDate));
    return list.take(8).toList();
  }

  String get _hello {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final featured = _filtered;
    final freshIds = {for (final c in _latest) c.id};
    final topPad = MediaQuery.paddingOf(context).top;

    return RefreshIndicator(
      color: MarketColors.primary,
      displacement: 48,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _TopBlock(
              topPad: topPad,
              hello: _hello,
              carCount: _cars.length,
              spotlight: _latest.where((c) => !c.isSold).take(5).toList(),
              onMenu: widget.onOpenMenu,
              onExplore: widget.onExplore,
              onNotifications: _openNotifications,
              onOpenCar: (car) => UserCarDetailsPage.open(context, car: car),
              unread: CarAlertService.instance.unread,
              searchCtrl: _searchCtrl,
              onSearch: (_) => setState(() {}),
              onOpenSearch: widget.onExplore,
            ),
          ),
          SliverToBoxAdapter(
            child: _QuickActions(
              onBuy: widget.onExplore,
              onSell: widget.onSell,
              onSaved: widget.onWishlist,
              onAlerts: _openNotifications,
              saved: WishlistService.instance.count,
              alerts: CarAlertService.instance.unread,
            ),
          ),
          const SliverToBoxAdapter(child: NewCarArrivalTicker()),
          SliverToBoxAdapter(
            child: _HomeHorizontalStrip(
              height: 54,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              spacing: 8,
              scrollSpeed: 0.55,
              children: [
                for (var i = 0; i < _budgets.length; i++)
                  Builder(
                    builder: (context) {
                      final on = _budget == i;
                      return GestureDetector(
                        onTap: () => setState(() => _budget = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: on ? MarketColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: on
                                  ? MarketColors.primary
                                  : const Color(0xFFE7EEF8),
                            ),
                          ),
                          child: Text(
                            _budgets[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: on ? Colors.white : MarketColors.text,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _HomeHorizontalStrip(
              height: 108,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              spacing: 12,
              scrollSpeed: 0.45,
              children: [
                for (final (label, icon) in _categories)
                  _CategoryChip(
                    label: label,
                    icon: icon,
                    selected: _category == label,
                    onTap: () => setState(() => _category = label),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: MarketSectionHeader(
              title: 'All cars',
              action: _loading ? null : '${featured.length} listed',
            ),
          ),
          if (_loading)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: _CarListSkeleton(),
            )
          else if (featured.isEmpty)
            const SliverToBoxAdapter(child: _EmptyFilter())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final car = featured[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CarListCard(
                        car: car,
                        isNew: freshIds.contains(car.id),
                        onTap: () => UserCarDetailsPage.open(
                          context,
                          car: car,
                        ),
                      ),
                    );
                  },
                  childCount: featured.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: _TrustStrip()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 108),
              child: _SellBanner(onSell: widget.onSell),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBlock extends StatelessWidget {
  const _TopBlock({
    required this.topPad,
    required this.hello,
    required this.carCount,
    required this.spotlight,
    required this.onMenu,
    required this.onExplore,
    required this.onNotifications,
    required this.onOpenCar,
    required this.unread,
    required this.searchCtrl,
    required this.onSearch,
    required this.onOpenSearch,
  });

  final double topPad;
  final String hello;
  final int carCount;
  final List<CarRecord> spotlight;
  final VoidCallback onMenu;
  final VoidCallback onExplore;
  final VoidCallback onNotifications;
  final ValueChanged<CarRecord> onOpenCar;
  final int unread;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF002E86),
                Color(0xFF0056D2),
                Color(0xFF4A9BFF),
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -28,
                child: _blob(168, const Color(0x28FFFFFF)),
              ),
              Positioned(
                left: -48,
                bottom: 28,
                child: _blob(130, const Color(0x18FFFFFF)),
              ),
              Positioned(
                right: 40,
                bottom: 70,
                child: _blob(70, const Color(0x14FFFFFF)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, topPad + 10, 12, 92),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Dream Car',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hello,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              height: 1.1,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Pune, Maharashtra',
                                style: TextStyle(
                                  color: Color(0xE6FFFFFF),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (carCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x28FFFFFF),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: const Color(0x40FFFFFF)),
                          ),
                          child: Text(
                            '$carCount live',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    _roundIcon(
                      Icons.notifications_none_rounded,
                      onTap: onNotifications,
                      badge: unread,
                    ),
                    const SizedBox(width: 8),
                    _roundIcon(Icons.person_outline_rounded, onTap: onMenu),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              SizedBox(height: topPad + 86),
              _HeroBanner(
                cars: spotlight,
                onExplore: onExplore,
                onOpenCar: onOpenCar,
              ),
              const SizedBox(height: 12),
              _SearchBar(
                controller: searchCtrl,
                onChanged: onSearch,
                onFilter: onOpenSearch,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  static Widget _roundIcon(
    IconData icon, {
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Material(
      color: const Color(0x28FFFFFF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Badge(
            isLabelVisible: badge > 0,
            label: Text('${badge > 9 ? '9+' : badge}'),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatefulWidget {
  const _HeroBanner({
    required this.cars,
    required this.onExplore,
    required this.onOpenCar,
  });

  final List<CarRecord> cars;
  final VoidCallback onExplore;
  final ValueChanged<CarRecord> onOpenCar;

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  final _page = PageController();
  int _i = 0;
  Timer? _autoSlide;

  @override
  void initState() {
    super.initState();
    _autoSlide = Timer.periodic(const Duration(seconds: 4), (_) => _nextSlide());
  }

  @override
  void didUpdateWidget(covariant _HeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cars.length != widget.cars.length) {
      _i = 0;
      if (_page.hasClients) {
        _page.jumpToPage(0);
      }
    }
  }

  void _nextSlide() {
    if (!mounted || widget.cars.length < 2 || !_page.hasClients) return;
    final next = (_i + 1) % widget.cars.length;
    _page.animateToPage(
      next,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _autoSlide?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cars = widget.cars;
    return FrostCard(
      borderRadius: 24,
      opacity: 0.92,
      blur: 16,
      child: SizedBox(
        height: 188,
        child: cars.isEmpty ? _staticHero() : _carousel(cars),
      ),
    );
  }

  Widget _staticHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
      child: Row(
        children: [
          Expanded(child: _copy(onTap: widget.onExplore)),
          Image.asset(
            AppAssets.splashCars[1],
            width: 132,
            height: 132,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _carousel(List<CarRecord> cars) {
    return Stack(
      children: [
        PageView.builder(
          controller: _page,
          itemCount: cars.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (context, i) {
            final car = cars[i];
            final title =
                car.title.isNotEmpty ? car.title : '${car.brand} ${car.model}';
            return InkWell(
              onTap: () => widget.onOpenCar(car),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _copy(
                        title: title,
                        price: formatInrCompact(car.sellPrice),
                        onTap: () => widget.onOpenCar(car),
                        cta: 'View car',
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 136,
                        height: 136,
                        child: car.coverImageUrl.isNotEmpty
                            ? CarNetworkImage(
                                url: car.coverImageUrl,
                                fit: BoxFit.cover,
                                cacheWidth: 280,
                              )
                            : Image.asset(
                                AppAssets.splashCars[1],
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 12,
          child: Row(
            children: [
              for (var i = 0; i < cars.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 5),
                  width: _i == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _i == i
                        ? MarketColors.primary
                        : const Color(0xFFD5DEEA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _copy({
    String title = 'Find Your',
    String price = 'Dream Car',
    String cta = 'Explore Cars',
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MarketColors.text,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MarketColors.primary,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Verified cars. Honest prices.',
          maxLines: 1,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.3,
            color: MarketColors.muted,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: MarketColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              cta,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return FrostCard(
      borderRadius: 18,
      opacity: 0.9,
      blur: 12,
      padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: MarketColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search brand, model or city...',
                  hintStyle: TextStyle(color: Color(0xFF9AA8BA), fontSize: 13),
                  isDense: true,
                ),
              ),
            ),
            Material(
              color: MarketColors.primary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onFilter,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onBuy,
    required this.onSell,
    required this.onSaved,
    required this.onAlerts,
    required this.saved,
    required this.alerts,
  });

  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onSaved;
  final VoidCallback onAlerts;
  final int saved;
  final int alerts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Row(
        children: [
          _QuickTile(
            icon: Icons.search_rounded,
            label: 'Buy',
            color: MarketColors.primary,
            onTap: onBuy,
          ),
          const SizedBox(width: 10),
          _QuickTile(
            icon: Icons.sell_rounded,
            label: 'Sell car',
            color: const Color(0xFF0F9D58),
            onTap: onSell,
          ),
          const SizedBox(width: 10),
          _QuickTile(
            icon: Icons.favorite_rounded,
            label: 'Saved',
            color: const Color(0xFFE11D48),
            badge: saved,
            onTap: onSaved,
          ),
          const SizedBox(width: 10),
          _QuickTile(
            icon: Icons.notifications_rounded,
            label: 'Alerts',
            color: const Color(0xFFE6A100),
            badge: alerts,
            onTap: onAlerts,
          ),
        ],
      ),
    );
  }
}

/// Horizontal row with optional automatic scroll (loops when content overflows).
class _HomeHorizontalStrip extends StatefulWidget {
  const _HomeHorizontalStrip({
    required this.height,
    required this.padding,
    required this.spacing,
    required this.children,
    this.scrollSpeed = 0.5,
  });

  final double height;
  final EdgeInsets padding;
  final double spacing;
  final List<Widget> children;
  final double scrollSpeed;

  @override
  State<_HomeHorizontalStrip> createState() => _HomeHorizontalStripState();
}

class _HomeHorizontalStripState extends State<_HomeHorizontalStrip> {
  final _scroll = ScrollController();
  Timer? _timer;
  bool _userDragging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _armAutoScroll());
  }

  @override
  void didUpdateWidget(covariant _HomeHorizontalStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _armAutoScroll());
    }
  }

  void _armAutoScroll() {
    _timer?.cancel();
    if (!mounted) return;
    if (!_scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _armAutoScroll());
      return;
    }
    if (_scroll.position.maxScrollExtent <= 6) return;

    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted || _userDragging || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) return;
      final next = _scroll.offset + widget.scrollSpeed;
      if (next >= max) {
        _scroll.jumpTo(0);
      } else {
        _scroll.jumpTo(next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _userDragging = true;
          } else if (notification is ScrollEndNotification) {
            _userDragging = false;
          }
          return false;
        },
        child: ListView.separated(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          primary: false,
          physics: const BouncingScrollPhysics(),
          padding: widget.padding,
          clipBehavior: Clip.none,
          itemCount: widget.children.length,
          separatorBuilder: (_, _) => SizedBox(width: widget.spacing),
          itemBuilder: (context, index) => widget.children[index],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7EEF8)),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    if (badge > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE11D48),
                            shape: BoxShape.circle,
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
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: MarketColors.text,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? MarketColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? MarketColors.primary
                      : const Color(0xFFE7EEF8),
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x400056D2),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : MarketTheme.cardShadow,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : MarketColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? MarketColors.primary : MarketColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarListCard extends StatelessWidget {
  const _CarListCard({
    required this.car,
    required this.onTap,
    this.isNew = false,
  });

  final CarRecord car;
  final VoidCallback onTap;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final title = car.title.isNotEmpty ? car.title : '${car.brand} ${car.model}';
    final owner = car.ownership.trim().isEmpty ? 'Used' : car.ownership;
    final subtitle = [
      if (car.brand.trim().isNotEmpty) car.brand,
      if (car.model.trim().isNotEmpty &&
          !title.toLowerCase().contains(car.model.toLowerCase()))
        car.model,
    ].join(' ');

    final live = !car.isSold && car.liveBidEnabled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: live ? const Color(0x33DC2626) : const Color(0x220056D2),
            blurRadius: live ? 20 : 18,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: live ? const Color(0x66E11D48) : const Color(0xFFE7EEF8),
          width: live ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 152,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 138,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: live
                                    ? const [Color(0xFFFFF1F2), Color(0xFFEEF3FB)]
                                    : const [Color(0xFFEEF3FB), Color(0xFFF8FAFF)],
                              ),
                            ),
                            child: CarNetworkImage(
                              url: car.coverImageUrl,
                              fit: BoxFit.contain,
                              cacheWidth: 280,
                            ),
                          ),
                          if (car.isSold)
                            const SoldOverlay(compact: true)
                          else
                            Positioned(
                              left: 8,
                              top: 8,
                              child: isNew
                                  ? const _TagChip(label: 'New', filled: true)
                                  : live
                                      ? LiveBidTicker(
                                          startedAt: car.liveBidStartedAt,
                                          compact: true,
                                        )
                                      : const _TagChip(
                                          label: 'Verified',
                                          icon: Icons.verified,
                                        ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15.5,
                                      height: 1.2,
                                      letterSpacing: -0.3,
                                      color: MarketColors.text,
                                    ),
                                  ),
                                ),
                                WishButton(carId: car.id, size: 28, iconSize: 15),
                              ],
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: MarketColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (car.year > 0) _MetaChip(text: '${car.year}'),
                                if (car.fuelType.trim().isNotEmpty)
                                  _MetaChip(text: car.fuelType),
                                _MetaChip(text: owner),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Sell price',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: MarketColors.muted,
                                        ),
                                      ),
                                      Text(
                                        formatInr(car.sellPrice),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          letterSpacing: -0.5,
                                          color: car.isSold
                                              ? MarketColors.muted
                                              : MarketColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StockStatusBadge(isSold: car.isSold, compact: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (live)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Live bidding open — tap to place your bid',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      LiveBidTicker(
                        startedAt: car.liveBidStartedAt,
                        dark: true,
                        compact: true,
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MarketColors.chipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: MarketColors.text,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.icon, this.filled = false});

  final String label;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? MarketColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: MarketColors.primary),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : MarketColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarListSkeleton extends StatelessWidget {
  const _CarListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: const Row(
            children: [
              SizedBox(width: 118, child: ColoredBox(color: Color(0xFFEEF3FB))),
              Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
        childCount: 3,
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.directions_car_outlined, size: 42, color: Color(0xFFB7C4D6)),
          SizedBox(height: 10),
          Text(
            'No cars in this filter yet',
            style: TextStyle(
              color: MarketColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try another budget or brand',
            style: TextStyle(color: Color(0xFF9AA8BA), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EEF8)),
        ),
        child: const Row(
          children: [
            _TrustCell(icon: Icons.verified_rounded, label: 'Verified\nlistings'),
            _TrustCell(icon: Icons.gavel_rounded, label: 'Easy\nbids'),
            _TrustCell(icon: Icons.lock_rounded, label: 'Secure\ndeals'),
            _TrustCell(icon: Icons.pin_drop_rounded, label: 'Pune\nbased'),
          ],
        ),
      ),
    );
  }
}

class _TrustCell extends StatelessWidget {
  const _TrustCell({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: MarketColors.primary),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: MarketColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SellBanner extends StatelessWidget {
  const _SellBanner({required this.onSell});

  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF003EA8), Color(0xFF0056D2), Color(0xFF3D8BFF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400056D2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.sell_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sell Your Car in 3 Easy Steps',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Photo, details, done.',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onSell,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: MarketColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sell Now',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
