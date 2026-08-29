import 'package:flutter/material.dart';

import '../theme/market_colors.dart';

/// Neutral car photo placeholder — never shows app logo or sample listing art.
class CarImagePlaceholder extends StatelessWidget {
  const CarImagePlaceholder({
    super.key,
    this.icon = Icons.directions_car_filled_rounded,
    this.label,
    this.fit = BoxFit.cover,
    this.loading = false,
  });

  final IconData icon;
  final String? label;
  final BoxFit fit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8EEF8),
            Color(0xFFD4E0F5),
            Color(0xFFC5D6F0),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (loading)
            const Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: MarketColors.primary,
                backgroundColor: Color(0x33FFFFFF),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 44,
                  color: MarketColors.primary.withValues(alpha: 0.55),
                ),
                if (label != null && label!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      label!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: MarketColors.muted.withValues(alpha: 0.9),
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
}
