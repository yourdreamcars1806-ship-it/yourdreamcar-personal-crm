import 'package:flutter/material.dart';

import '../../../core/format/inr.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/car_network_image.dart';
import '../../../core/ui/sold_overlay.dart';
import '../../../core/ui/wish_button.dart';
import '../../../services/car_catalog_service.dart';
import '../../../services/car_service.dart';
import 'user_car_details_page.dart';

class SoldCarsPage extends StatefulWidget {
  const SoldCarsPage({super.key, this.onBrowseCars});

  final VoidCallback? onBrowseCars;

  @override
  State<SoldCarsPage> createState() => _SoldCarsPageState();
}

class _SoldCarsPageState extends State<SoldCarsPage> {
  List<CarRecord> _cars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    CarCatalogService.instance.addListener(_sync);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _sync();
    try {
      await CarCatalogService.instance.load();
    } catch (_) {
      if (mounted) _sync();
    }
  }

  @override
  void dispose() {
    CarCatalogService.instance.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    final all = CarCatalogService.instance.cars;
    final sold = all.where((c) => c.isSold).toList()
      ..sort((a, b) => b.buyDate.compareTo(a.buyDate));
    setState(() {
      _cars = sold;
      _loading = CarCatalogService.instance.isLoading && all.isEmpty;
    });
  }

  Future<void> _load() async {
    CarCatalogService.instance.invalidate();
    await CarCatalogService.instance.load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return RefreshIndicator(
      color: MarketColors.primary,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _SoldHeroBanner(
              topPad: top,
              soldCount: _cars.length,
              loading: _loading,
              onBrowse: widget.onBrowseCars,
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: MarketColors.primary),
              ),
            )
          else if (_cars.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 110),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4EC),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFBCFE0)),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        size: 42,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No sold cars yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: MarketColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Successful deals will appear here with a SOLD badge. Browse live listings on Home.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MarketColors.muted,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.onBrowseCars != null) ...[
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: widget.onBrowseCars,
                        icon: const Icon(Icons.search_rounded, size: 20),
                        label: const Text(
                          'Browse live cars',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: MarketColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: MarketColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Recently sold · ${_cars.length} vehicles',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MarketColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              sliver: SliverList.separated(
                itemCount: _cars.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) => _SoldCarCard(car: _cars[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoldHeroBanner extends StatelessWidget {
  const _SoldHeroBanner({
    required this.topPad,
    required this.soldCount,
    required this.loading,
    this.onBrowse,
  });

  final double topPad;
  final int soldCount;
  final bool loading;
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF450A0A),
            Color(0xFF991B1B),
            Color(0xFFE11D48),
            Color(0xFFFB7185),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55E11D48),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -30,
            child: Icon(
              Icons.emoji_events_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 16,
            child: Icon(
              Icons.directions_car_filled_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -24,
            child: _blob(110, const Color(0x18FFFFFF)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.28),
                            Colors.white.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x55FFFFFF)),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x33FFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x44FFFFFF)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'SUCCESS STORIES',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Sold Cars',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -0.8,
                              shadows: [
                                Shadow(
                                  color: Color(0x44000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            loading
                                ? 'Loading verified deals…'
                                : '$soldCount ${soldCount == 1 ? 'vehicle' : 'vehicles'} sold through Your Dream Car',
                            style: const TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.check_circle_rounded,
                      label: loading ? '—' : '$soldCount',
                      hint: 'Sold',
                    ),
                    const SizedBox(width: 10),
                    const _StatChip(
                      icon: Icons.verified_user_rounded,
                      label: '100%',
                      hint: 'Verified',
                    ),
                    const SizedBox(width: 10),
                    const _StatChip(
                      icon: Icons.location_on_rounded,
                      label: 'Pune',
                      hint: 'Deals',
                    ),
                  ],
                ),
                if (onBrowse != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onBrowse,
                      icon: const Icon(Icons.directions_car_filled_rounded, size: 18),
                      label: const Text(
                        'Browse live cars',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xAAFFFFFF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.hint,
  });

  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0x28FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    hint,
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoldCarCard extends StatelessWidget {
  const _SoldCarCard({required this.car});

  final CarRecord car;

  @override
  Widget build(BuildContext context) {
    final title =
        car.title.isNotEmpty ? car.title : '${car.brand} ${car.model}'.trim();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: const Color(0x140056D2),
      child: InkWell(
        onTap: () => UserCarDetailsPage.open(context, car: car),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7EEF8)),
            boxShadow: MarketTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 168,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CarNetworkImage(
                      url: car.coverImageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 320,
                    ),
                    const SoldOverlay(compact: true),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${car.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: WishButton(carId: car.id, size: 34, iconSize: 17),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: MarketColors.text,
                            ),
                          ),
                        ),
                        const SoldPill(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${car.fuelType}  ·  ${car.ownership}  ·  ${car.brand}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MarketColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deal closed at',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: MarketColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formatInr(car.sellPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: MarketColors.text,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Color(0x88E11D48),
                                  decorationThickness: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              UserCarDetailsPage.open(context, car: car),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text(
                            'View',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: MarketColors.primary,
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
    );
  }
}
