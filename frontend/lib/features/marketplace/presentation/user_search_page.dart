import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/format/inr.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/sold_overlay.dart';
import '../../../core/ui/wish_button.dart';
import '../../../services/car_catalog_service.dart';
import '../../../services/car_service.dart';
import 'user_car_details_page.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _ctrl = TextEditingController();
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
    _ctrl.dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    setState(() {
      _cars = CarCatalogService.instance.cars;
      _loading = CarCatalogService.instance.isLoading && _cars.isEmpty;
    });
  }

  List<CarRecord> get _filtered {
    final q = _ctrl.text.trim().toLowerCase();
    final list = q.isEmpty
        ? [..._cars]
        : _cars.where((c) {
            return '${c.title} ${c.brand} ${c.model} ${c.year}'
                .toLowerCase()
                .contains(q);
          }).toList();
    list.sort((a, b) => (a.isSold ? 1 : 0).compareTo(b.isSold ? 1 : 0));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final items = _filtered;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 12, 16, 10),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: MarketTheme.cardShadow,
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: MarketColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search by brand, model or keyword...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: MarketColors.primary),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final car = items[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => UserCarDetailsPage.open(context, car: car),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: MarketTheme.cardShadow,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 92,
                                  height: 72,
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
                                              cacheWidth: 184,
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
                                      car.title.isNotEmpty
                                          ? car.title
                                          : '${car.brand} ${car.model}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: MarketColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${car.year} • ${car.fuelType}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: MarketColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
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
                    );
                  },
                ),
        ),
      ],
    );
  }
}
