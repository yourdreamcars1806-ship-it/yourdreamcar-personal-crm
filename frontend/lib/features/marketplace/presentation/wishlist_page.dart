import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/format/inr.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/sold_overlay.dart';
import '../../../core/ui/wish_button.dart';
import '../../../services/car_catalog_service.dart';
import '../../../services/car_service.dart';
import '../../../services/wishlist_service.dart';
import 'user_car_details_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key, this.onBrowseCars});

  final VoidCallback? onBrowseCars;

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<CarRecord> _cars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WishlistService.instance.addListener(_onWish);
    CarCatalogService.instance.addListener(_onWish);
    WishlistService.instance.start();
    _sync();
  }

  @override
  void dispose() {
    WishlistService.instance.removeListener(_onWish);
    CarCatalogService.instance.removeListener(_onWish);
    super.dispose();
  }

  void _onWish() {
    if (mounted) _sync();
  }

  void _sync() {
    if (!mounted) return;
    setState(() {
      _cars = CarCatalogService.instance.cars;
      _loading = CarCatalogService.instance.isLoading && _cars.isEmpty;
    });
  }

  Future<void> _load() async {
    await WishlistService.instance.start();
    CarCatalogService.instance.invalidate();
    await CarCatalogService.instance.load(force: true);
  }

  List<CarRecord> get _saved {
    final order = WishlistService.instance.ids;
    final map = {for (final c in _cars) c.id: c};
    return [
      for (final id in order)
        if (map[id] != null) map[id]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final items = _saved;

    return RefreshIndicator(
      color: MarketColors.primary,
      onRefresh: _load,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, top + 14, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Wishlist',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: MarketColors.text,
                      ),
                    ),
                  ),
                  if (items.isNotEmpty)
                    Text(
                      '${items.length} saved',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MarketColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: MarketColors.primary),
              ),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 110),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE4EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 38,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No saved cars yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: MarketColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the heart on a car to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MarketColors.muted, height: 1.4),
                    ),
                    if (widget.onBrowseCars != null) ...[
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: widget.onBrowseCars,
                        style: FilledButton.styleFrom(
                          backgroundColor: MarketColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Browse cars',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final car = items[i];
                  final title = car.title.isNotEmpty
                      ? car.title
                      : '${car.brand} ${car.model}';
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => UserCarDetailsPage.open(context, car: car),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: MarketTheme.cardShadow,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 96,
                                  height: 78,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      car.imageUrl.isEmpty
                                          ? Image.asset(
                                              AppAssets.sampleCarListing,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              car.imageUrl,
                                              fit: BoxFit.cover,
                                            ),
                                      if (car.isSold)
                                        const SoldOverlay(compact: true),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: MarketColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${car.year}  •  ${car.fuelType}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: MarketColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            formatInr(car.sellPrice),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: car.isSold
                                                  ? MarketColors.muted
                                                  : MarketColors.primary,
                                            ),
                                          ),
                                        ),
                                        if (car.isSold) const SoldPill(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              WishButton(carId: car.id),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
