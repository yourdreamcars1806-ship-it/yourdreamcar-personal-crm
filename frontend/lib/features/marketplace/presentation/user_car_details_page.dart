import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/format/inr.dart';
import '../../../core/navigation/open_panel.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/sold_overlay.dart';
import '../../../core/ui/wish_button.dart';
import '../../../services/car_service.dart';
import 'bid_form_page.dart';

class UserCarDetailsPage extends StatefulWidget {
  const UserCarDetailsPage({super.key, this.car, this.carId});

  final CarRecord? car;
  final String? carId;

  static void open(BuildContext context, {CarRecord? car, String? carId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserCarDetailsPage(car: car, carId: carId),
      ),
    );
  }

  @override
  State<UserCarDetailsPage> createState() => _UserCarDetailsPageState();
}

class _UserCarDetailsPageState extends State<UserCarDetailsPage> {
  CarRecord? _car;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _car = widget.car;
    if (_car == null && (widget.carId ?? '').isNotEmpty) {
      _load(widget.carId!);
    }
  }

  Future<void> _load(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final car = await CarService().getCar(id);
      if (!mounted) return;
      setState(() {
        _car = car;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this car';
      });
    }
  }

  Future<void> _bidNow() async {
    final car = _car;
    if (car == null) return;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ok = await ensureLoggedIn(
      context,
      darkModeEnabled: dark,
      onThemeChanged: (_) {},
    );
    if (!mounted || !ok) return;
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BidFormPage(car: car)),
    );
    if (done == true && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = _car;
    final title = car == null
        ? 'Car details'
        : (car.title.isNotEmpty ? car.title : '${car.brand} ${car.model}');

    return Theme(
      data: MarketTheme.data(),
      child: Scaffold(
        backgroundColor: MarketColors.bg,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: MarketColors.primary),
              )
            : _error != null
            ? Center(child: Text(_error!))
            : car == null
            ? const Center(child: Text('Car not found'))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 280,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.white,
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(child: WishButton(carId: car.id, size: 36, iconSize: 18)),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
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
                                  errorBuilder: (_, _, _) => Image.asset(
                                    AppAssets.sampleCarListing,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x66000000),
                                  Color(0x00000000),
                                  Color(0xCC000000),
                                ],
                              ),
                            ),
                          ),
                          if (car.isSold) const SoldOverlay(),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 18,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: MarketTheme.cardShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sell price',
                                  style: TextStyle(
                                    color: MarketColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatInr(car.sellPrice),
                                        style: TextStyle(
                                          fontSize: 28,
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
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _spec(Icons.calendar_month_rounded, '${car.year}'),
                              _spec(Icons.local_gas_station_rounded, car.fuelType),
                              _spec(Icons.badge_outlined, car.ownership),
                              _spec(Icons.directions_car_rounded, car.brand),
                              _spec(
                                Icons.check_circle_outline,
                                car.availability == 'stock'
                                    ? 'In stock'
                                    : 'Sold',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Overview',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            car.description.trim().isEmpty
                                ? 'Verified listing. Place a bid and our team will contact you.'
                                : car.description.trim(),
                            style: const TextStyle(
                              height: 1.45,
                              color: MarketColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: car == null || _loading
            ? null
            : DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x140056D2),
                      blurRadius: 18,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sell price',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: MarketColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatInr(car.sellPrice),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: MarketColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: car.availability == 'outstock'
                                  ? const []
                                  : const [
                                      BoxShadow(
                                        color: Color(0x400056D2),
                                        blurRadius: 14,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton(
                              onPressed: car.availability == 'outstock'
                                  ? null
                                  : _bidNow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MarketColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFFB7C4D6),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    car.availability == 'outstock'
                                        ? Icons.lock_outline_rounded
                                        : Icons.gavel_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    car.availability == 'outstock'
                                        ? 'Sold out'
                                        : 'Place a bid',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
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
              ),
      ),
    );
  }

  Widget _spec(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: MarketColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
