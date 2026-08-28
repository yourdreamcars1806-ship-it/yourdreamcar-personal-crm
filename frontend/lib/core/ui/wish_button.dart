import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/market_colors.dart';
import '../../services/wishlist_service.dart';

class WishButton extends StatelessWidget {
  const WishButton({
    super.key,
    required this.carId,
    this.size = 30,
    this.iconSize = 16,
  });

  final String carId;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WishlistService.instance,
      builder: (context, _) {
        final on = WishlistService.instance.has(carId);
        return Material(
          color: Colors.white.withValues(alpha: 0.96),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              HapticFeedback.selectionClick();
              await WishlistService.instance.toggle(carId);
            },
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: iconSize,
                color: on ? const Color(0xFFE11D48) : MarketColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
