import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'market_colors.dart';

abstract final class MarketTheme {
  static ThemeData data() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MarketColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: MarketColors.bg,
    );
    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: MarketColors.text,
        displayColor: MarketColors.text,
      ),
    );
  }

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x140056D2),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
        BoxShadow(
          color: Color(0x0A122033),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];
}

class MarketSectionHeader extends StatelessWidget {
  const MarketSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: MarketColors.text,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  color: MarketColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
