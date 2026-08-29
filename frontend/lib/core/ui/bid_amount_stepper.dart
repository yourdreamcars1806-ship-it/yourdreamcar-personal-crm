import 'package:flutter/material.dart';

import '../format/inr.dart';
import '../theme/market_colors.dart';

class BidAmountStepper extends StatelessWidget {
  const BidAmountStepper({
    super.key,
    required this.amount,
    required this.onChanged,
    this.step = 5000,
    this.min = 5000,
    this.enabled = true,
    this.askPrice,
  });

  final double amount;
  final ValueChanged<double> onChanged;
  final double step;
  final double min;
  final bool enabled;
  final double? askPrice;

  bool get _matchesAsk {
    if (askPrice == null || askPrice! <= 0) return false;
    return amount.round() == askPrice!.round();
  }

  void _bump(double delta) {
    final next = (amount + delta).clamp(min, double.infinity);
    onChanged((next / step).round() * step);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _RoundBtn(
              icon: Icons.remove_rounded,
              enabled: enabled && amount > min,
              onTap: () => _bump(-step),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    formatInr(amount),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: MarketColors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adjust in ${formatInr(step)} steps',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MarketColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            _RoundBtn(
              icon: Icons.add_rounded,
              enabled: enabled,
              onTap: () => _bump(step),
            ),
          ],
        ),
        if (_matchesAsk) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: Color(0xFF047857), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Price matched! This bid wins instantly.',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? MarketColors.primary : const Color(0xFFE2E8F0),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: enabled ? Colors.white : const Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
