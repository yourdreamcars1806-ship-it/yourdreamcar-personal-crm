import 'package:flutter/material.dart';

import '../../../../core/constants/assets.dart';
import '../../../../core/theme/brand_colors.dart';

/// Mobile-first car listing: hero image, badges, details, primary CTA.
class CarListingCard extends StatelessWidget {
  const CarListingCard({
    super.key,
    this.imageAsset = AppAssets.sampleCarListing,
    this.fuelLabel = 'PETROL',
    this.availabilityLabel = 'AVAILABLE',
    this.tagline = 'READY TO DRIVE',
    this.priceText = 'Rs 3,00,000',
    this.year = '2011',
    this.title = '2011 VOLKSWAGEN POLO',
    this.description =
        'Verified profile with transparent pricing and quick support.',
    this.statusLabel = 'Available',
    this.onViewDetails,
  });

  final String imageAsset;
  final String fuelLabel;
  final String availabilityLabel;
  final String tagline;
  final String priceText;
  final String year;
  final String title;
  final String description;
  final String statusLabel;
  final VoidCallback? onViewDetails;

  static const _titleNavy = Color(0xFF0D1B2A);
  static const _surface = Color(0xFFFFFFFF);
  static const _surface2 = Color(0xFFF1F5F9);
  static const _orangeTag = Color(0xFFFF6D00);
  static const _tealStatus = Color(0xFF00897B);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: BrandColors.neonCyan.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImageSection(
                imageAsset: imageAsset,
                fuelLabel: fuelLabel,
                availabilityLabel: availabilityLabel,
                tagline: tagline,
                priceText: priceText,
                year: year,
              ),
              _DetailsSection(
                title: title,
                year: year,
                description: description,
                statusLabel: statusLabel,
                onViewDetails: onViewDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.imageAsset,
    required this.fuelLabel,
    required this.availabilityLabel,
    required this.tagline,
    required this.priceText,
    required this.year,
  });

  final String imageAsset;
  final String fuelLabel;
  final String availabilityLabel;
  final String tagline;
  final String priceText;
  final String year;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            cacheWidth: 900,
            filterQuality: FilterQuality.low,
            errorBuilder: (context, error, _) => Container(
              color: BrandColors.navyMid,
              alignment: Alignment.center,
              child: Icon(
                Icons.directions_car_filled_rounded,
                size: 56,
                color: BrandColors.muted.withValues(alpha: 0.45),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Center(
            child: Transform.rotate(
              angle: -0.1,
              child: Text(
                'Dream Car',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.12),
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _Badge(
              background: Colors.white,
              foreground: const Color(0xFF1E293B),
              text: fuelLabel,
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _Badge(
              background: const Color(0xFF22C55E),
              foreground: Colors.white,
              text: availabilityLabel,
              glow: true,
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            right: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tagline,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: CarListingCard._orangeTag,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  priceText,
                  style: TextStyle(
                    fontSize: MediaQuery.sizeOf(context).width < 360 ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.05,
                    letterSpacing: -0.5,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 16,
            child: _Badge(
              background: Colors.black.withValues(alpha: 0.55),
              foreground: Colors.white,
              text: year,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.background,
    required this.foreground,
    required this.text,
    this.fontSize = 10.5,
    this.glow = false,
  });

  final Color background;
  final Color foreground;
  final String text;
  final double fontSize;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: glow
                ? const Color(0xFF22C55E).withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.22),
            blurRadius: glow ? 10 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: foreground,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.year,
    required this.description,
    required this.statusLabel,
    this.onViewDetails,
  });

  final String title;
  final String year;
  final String description;
  final String statusLabel;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CarListingCard._surface,
            CarListingCard._surface2,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CarListingCard._titleNavy,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  year,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: CarListingCard._titleNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: CarListingCard._muted.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CarListingCard._tealStatus.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CarListingCard._tealStatus.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: CarListingCard._tealStatus.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: CarListingCard._muted.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: CarListingCard._tealStatus,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onViewDetails,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E3A5F),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: Colors.white.withValues(alpha: 0.98),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
