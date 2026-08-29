import 'package:flutter/material.dart';

/// Shared labels: **In Stock** / **Sold** (never "Sold out" or "Out stock").
abstract final class StockLabels {
  static const inStock = 'In Stock';
  static const sold = 'Sold';
}

/// Small badge for car cards and lists.
class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({
    super.key,
    required this.isSold,
    this.compact = false,
  });

  final bool isSold;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (isSold) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF991B1B), Color(0xFFE11D48)],
          ),
          borderRadius: BorderRadius.circular(compact ? 7 : 8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33E11D48),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: compact ? 10 : 11,
            ),
            SizedBox(width: compact ? 3 : 4),
            Text(
              StockLabels.sold,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 9.5 : 10.5,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(compact ? 7 : 8),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_rounded,
            color: const Color(0xFF16A34A),
            size: compact ? 10 : 11,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            StockLabels.inStock,
            style: TextStyle(
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w900,
              fontSize: compact ? 9.5 : 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
