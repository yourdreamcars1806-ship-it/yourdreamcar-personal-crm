import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/format/inr.dart';
import '../../../core/theme/market_colors.dart';
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
    _sync();
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, top + 14, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sold cars',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: MarketColors.text,
                      ),
                    ),
                  ),
                  if (!_loading && _cars.isNotEmpty)
                    Text(
                      '${_cars.length} sold',
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
          else if (_cars.isEmpty)
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
                        Icons.sell_rounded,
                        size: 38,
                        color: Color(0xFFE11D48),
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
                    const SizedBox(height: 8),
                    const Text(
                      'When a car is sold, it will show only on this tab.',
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
                itemCount: _cars.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final car = _cars[i];
                  final title = car.title.isNotEmpty
                      ? car.title
                      : '${car.brand} ${car.model}';
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => UserCarDetailsPage.open(context, car: car),
                      child: SizedBox(
                        height: 118,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 118,
                              height: 118,
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
                                  const SoldOverlay(),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: MarketColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${car.year}  ·  ${car.fuelType}  ·  ${car.ownership}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: MarketColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
                                              fontSize: 16,
                                              color: MarketColors.muted,
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
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: WishButton(carId: car.id, size: 28, iconSize: 15),
                            ),
                          ],
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
