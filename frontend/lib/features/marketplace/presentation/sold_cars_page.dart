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
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD6E4FF)),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        size: 34,
                        color: MarketColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No sold cars yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: MarketColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Successful deals will appear here. Browse live listings on Home.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: MarketColors.muted,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.onBrowseCars != null) ...[
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: widget.onBrowseCars,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text(
                          'Browse live cars',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: MarketColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Text(
                  'Recently sold · ${_cars.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MarketColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              sliver: SliverList.separated(
                itemCount: _cars.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
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
      margin: EdgeInsets.fromLTRB(16, topPad > 0 ? 4 : 8, 16, 8),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sold Cars',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loading
                      ? 'Loading deals…'
                      : '$soldCount verified ${soldCount == 1 ? 'deal' : 'deals'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onBrowse != null)
            TextButton(
              onPressed: onBrowse,
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
                'Browse',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
        ],
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
    final meta = [
      if (car.year > 0) '${car.year}',
      if (car.fuelType.trim().isNotEmpty) car.fuelType,
      if (car.ownership.trim().isNotEmpty) car.ownership,
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => UserCarDetailsPage.open(context, car: car),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EEF8)),
            boxShadow: MarketTheme.cardShadow,
          ),
          child: SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 118,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: const Color(0xFFEEF3FB),
                        child: CarNetworkImage(
                          url: car.coverImageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                        ),
                      ),
                      const SoldOverlay(compact: true),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
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
                                  fontSize: 14.5,
                                  color: MarketColors.text,
                                ),
                              ),
                            ),
                            WishButton(carId: car.id, size: 28, iconSize: 14),
                          ],
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: MarketColors.muted,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatInr(car.sellPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: MarketColors.primary,
                                ),
                              ),
                            ),
                            const SoldPill(),
                          ],
                        ),
                      ],
                    ),
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
