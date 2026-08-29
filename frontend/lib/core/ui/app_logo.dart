import 'package:flutter/material.dart';

import '../constants/assets.dart';

/// Brand logo — full wings version or round badge for icons/small slots.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.round = false,
    this.width = 168,
    this.height,
  });

  final bool round;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final asset = round ? AppAssets.logoRound : AppAssets.logo;
    final h = height ?? (round ? width : width * 0.652);

    final image = Image.asset(
      asset,
      width: width,
      height: h,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (round) {
      return ClipOval(
        child: SizedBox(width: width, height: width, child: image),
      );
    }

    return image;
  }
}
