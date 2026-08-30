import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/cache/car_image_cache.dart';
import '../../../core/format/inr.dart';
import '../../../core/navigation/open_panel.dart';
import '../../../core/theme/market_colors.dart';
import '../../../core/theme/market_theme.dart';
import '../../../core/ui/car_network_image.dart';
import '../../../core/ui/car_gallery_section.dart';
import '../../../core/ui/stock_status_badge.dart';
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
  String _heroUrl = '';

  @override
  void initState() {
    super.initState();
    _car = widget.car;
    _heroUrl = widget.car?.coverImageUrl ?? '';
    final id = widget.car?.id ?? widget.carId ?? '';
    if (id.isNotEmpty) _load(id);
  }

  Future<void> _load(String id) async {
    setState(() {
      _loading = _car == null;
      _error = null;
    });
    try {
      final car = await CarService().getCar(id);
      if (!mounted) return;
      setState(() {
        _car = car;
        _loading = false;
        _heroUrl = car.coverImageUrl;
      });
      unawaited(CarImageCache.prefetchCarGallery(car));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _car == null ? 'Could not load this car' : null;
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
    if (done == true && mounted) {
      final id = car.id;
      if (id.isNotEmpty) await _load(id);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  String _displayTitle(CarRecord car) {
    if (car.title.trim().isNotEmpty) return car.title.trim();
    return '${car.brand} ${car.model}'.trim();
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final car = _car;
    final title = car == null ? 'Car details' : _displayTitle(car);
    final subtitle = car == null
        ? ''
        : '${car.brand} ${car.model} · ${car.year}';
    final exterior = car?.galleryExteriorImages ?? const [];
    final interior = car?.allInteriorImages ?? const [];
    final heroUrl = _heroUrl.isNotEmpty ? _heroUrl : (car?.coverImageUrl ?? '');
    final showGallery = exterior.isNotEmpty || interior.isNotEmpty;

    return Theme(
      data: MarketTheme.data(),
      child: Scaffold(
        backgroundColor: MarketColors.bg,
        body: _loading && car == null
            ? const Center(
                child: CircularProgressIndicator(color: MarketColors.primary),
              )
            : _error != null && car == null
            ? Center(child: Text(_error!))
            : car == null
            ? const Center(child: Text('Car not found'))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 300,
                    backgroundColor: MarketColors.primary,
                    foregroundColor: Colors.white,
                    iconTheme: const IconThemeData(color: Colors.white),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          child: WishButton(carId: car.id, size: 36, iconSize: 18),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: const Color(0xFF0F172A),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              child: CarNetworkImage(
                                key: ValueKey(heroUrl),
                                url: heroUrl,
                                fit: BoxFit.contain,
                                cacheWidth: 900,
                                thumbnail: false,
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                                stops: const [0, 0.45, 1],
                              ),
                            ),
                          ),
                          if (car.isSold) const SoldOverlay(forCard: true),
                          Positioned(
                            left: 16,
                            top: 56,
                            child: StockStatusBadge(
                              isSold: car.isSold,
                              compact: true,
                            ),
                          ),
                          if (exterior.length + interior.length > 0)
                            Positioned(
                              right: 16,
                              top: 56,
                              child: _HeroChip(
                                icon: Icons.photo_library_rounded,
                                label: '${exterior.length + interior.length} photos',
                              ),
                            ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    height: 1.15,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                if (subtitle.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
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
                          _PriceStatusCard(car: car),
                          const SizedBox(height: 14),
                          _QuickStats(
                            year: car.year,
                            fuel: car.fuelType,
                            ownership: car.ownership,
                            photos: exterior.length + interior.length,
                          ),
                          if (showGallery) ...[
                            const SizedBox(height: 18),
                            CarGallerySection(
                              exteriorImages: exterior,
                              interiorImages: interior,
                              heroHeight: 320,
                              onImageChanged: (url) {
                                if (url.isNotEmpty && url != _heroUrl) {
                                  setState(() => _heroUrl = url);
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 18),
                          _SectionCard(
                            title: 'Vehicle specifications',
                            icon: Icons.tune_rounded,
                            subtitle: 'Complete listing details',
                            child: _SpecsGrid(
                              items: [
                                _SpecItem(
                                  icon: Icons.directions_car_filled_rounded,
                                  label: 'Brand',
                                  value: car.brand.isEmpty ? '—' : car.brand,
                                ),
                                _SpecItem(
                                  icon: Icons.label_rounded,
                                  label: 'Model',
                                  value: car.model.isEmpty ? '—' : car.model,
                                ),
                                _SpecItem(
                                  icon: Icons.calendar_month_rounded,
                                  label: 'Year',
                                  value: car.year > 0 ? '${car.year}' : '—',
                                ),
                                _SpecItem(
                                  icon: Icons.local_gas_station_rounded,
                                  label: 'Fuel',
                                  value: car.fuelType.isEmpty ? '—' : car.fuelType,
                                ),
                                _SpecItem(
                                  icon: Icons.badge_outlined,
                                  label: 'Ownership',
                                  value: car.ownership.isEmpty ? '—' : car.ownership,
                                ),
                                if (car.vehicleNumber.trim().isNotEmpty)
                                  _SpecItem(
                                    icon: Icons.pin_rounded,
                                    label: 'Vehicle no.',
                                    value: car.vehicleNumber.trim(),
                                  ),
                                _SpecItem(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Availability',
                                  value: car.stockStatusLabel,
                                  valueColor: car.isSold
                                      ? MarketColors.muted
                                      : const Color(0xFF16A34A),
                                ),
                                _SpecItem(
                                  icon: Icons.photo_camera_rounded,
                                  label: 'Gallery',
                                  value:
                                      '${exterior.length} ext · ${interior.length} int',
                                ),
                                if (car.isSold && car.saleDate != null)
                                  _SpecItem(
                                    icon: Icons.event_rounded,
                                    label: 'Sold on',
                                    value: _fmtDate(car.saleDate),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Overview',
                            icon: Icons.description_outlined,
                            subtitle: 'About this listing',
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: MarketColors.chipBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: MarketColors.line),
                              ),
                              child: Text(
                                car.description.trim().isEmpty
                                    ? 'Verified listing from Your Dream Car. Inspect photos, review specs, and place a bid — our team will contact you after your offer is reviewed.'
                                    : car.description.trim(),
                                style: const TextStyle(
                                  height: 1.6,
                                  color: MarketColors.text,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _TrustBanner(isSold: car.isSold),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: car == null || (_loading && _car == null)
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
                              boxShadow: car.canBid
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x400056D2),
                                        blurRadius: 14,
                                        offset: Offset(0, 6),
                                      ),
                                    ]
                                  : const [],
                            ),
                            child: ElevatedButton(
                              onPressed: car.canBid ? _bidNow : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MarketColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFFB7C4D6),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    car.isSold
                                        ? Icons.lock_outline_rounded
                                        : car.liveBidEnabled
                                            ? Icons.gavel_rounded
                                            : Icons.hourglass_empty_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    car.isSold
                                        ? StockLabels.sold
                                        : car.liveBidEnabled
                                            ? 'Place a bid'
                                            : 'Bidding closed',
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
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceStatusCard extends StatelessWidget {
  const _PriceStatusCard({required this.car});

  final CarRecord car;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: car.isSold
              ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]
              : [const Color(0xFF0056D2), const Color(0xFF003EA8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: car.isSold
            ? MarketTheme.cardShadow
            : const [
                BoxShadow(
                  color: Color(0x400056D2),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sell price',
                  style: TextStyle(
                    color: car.isSold ? MarketColors.muted : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatInr(car.sellPrice),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: car.isSold ? MarketColors.text : Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (car.isSold)
            const StockStatusBadge(isSold: true)
          else
            const StockStatusBadge(isSold: false),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.year,
    required this.fuel,
    required this.ownership,
    required this.photos,
  });

  final int year;
  final String fuel;
  final String ownership;
  final int photos;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.calendar_month_rounded,
            label: year > 0 ? '$year' : '—',
            hint: 'Year',
            color: MarketColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.local_gas_station_rounded,
            label: fuel.isEmpty ? '—' : fuel,
            hint: 'Fuel',
            color: const Color(0xFF0F9D58),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.badge_outlined,
            label: ownership.isEmpty ? '—' : ownership,
            hint: 'Owner',
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.photo_library_rounded,
            label: '$photos',
            hint: 'Photos',
            color: const Color(0xFFEA580C),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MarketColors.line),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: MarketColors.text,
            ),
          ),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 10,
              color: MarketColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecItem {
  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}

class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.items});

  final List<_SpecItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossCount = width >= 360 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: crossCount == 2 ? 2.35 : 3.2,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return Container(
              padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
              decoration: BoxDecoration(
                color: MarketColors.chipBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MarketColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: MarketTheme.cardShadow,
                    ),
                    child: Icon(
                      item.icon,
                      size: 18,
                      color: MarketColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: MarketColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: item.valueColor ?? MarketColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MarketColors.line),
        boxShadow: MarketTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MarketColors.primary, MarketColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330056D2),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: MarketColors.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MarketColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner({required this.isSold});

  final bool isSold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSold
              ? [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)]
              : [const Color(0xFFEEF4FF), const Color(0xFFE0EAFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSold ? MarketColors.line : MarketColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSold
                  ? MarketColors.line
                  : MarketColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSold ? Icons.info_outline_rounded : Icons.verified_user_rounded,
              color: isSold ? MarketColors.muted : MarketColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSold
                  ? 'This vehicle has been sold. Browse other listings for similar cars.'
                  : 'Inspected listing · Secure bidding · Team support after offer review',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSold ? MarketColors.muted : MarketColors.text,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
