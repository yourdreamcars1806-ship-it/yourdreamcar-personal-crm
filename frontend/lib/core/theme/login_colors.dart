import 'package:flutter/material.dart';

import 'brand_colors.dart';

/// Login / form chrome (uses [BrandColors] for consistency with splash & logo).
abstract final class LoginColors {
  static const Color backgroundTop = BrandColors.navy;
  static const Color backgroundBottom = BrandColors.navyMid;
  static const Color darkBlue = BrandColors.neonDim;
  static const Color darkBlueDeep = BrandColors.navyElevated;
  static const Color blobAccent = BrandColors.neonCyan;
  static const Color label = BrandColors.navy;
  static const Color valueText = BrandColors.navyMid;
  static const Color hint = BrandColors.muted;
  static const Color subtitle = BrandColors.muted;
  static const Color iconBg = Color(0xFFE0F7FA);
  static const Color cardBorder = Color(0x3300E5FF);
  static const Color shadow = Color(0x1A0A1628);
}
