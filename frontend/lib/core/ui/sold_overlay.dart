import 'package:flutter/material.dart';

/// Brand blue used for sold badges / ribbons.
const _soldBlue = Color(0xFF0056D2);
const _soldBlueDark = Color(0xFF003EA8);

class SoldOverlay extends StatelessWidget {
  const SoldOverlay({super.key, this.compact = false, this.forCard = false});

  final bool compact;
  final bool forCard;

  @override
  Widget build(BuildContext context) {
    if (compact) return const _CompactSoldRibbon();
    if (forCard) return const _CardSoldOverlay();

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x44000000),
                  const Color(0x66000000),
                  const Color(0x88001A4D),
                ],
              ),
            ),
          ),
          Center(
            child: Transform.rotate(
              angle: -0.32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_soldBlueDark, _soldBlue],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x440056D2),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Sold',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSoldRibbon extends StatelessWidget {
  const _CompactSoldRibbon();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0x22000000),
                  const Color(0x44000000),
                ],
              ),
            ),
          ),
          Positioned(
            left: -10,
            top: 6,
            child: Transform.rotate(
              angle: -0.48,
              child: Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_soldBlueDark, _soldBlue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x330056D2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Sold',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                    letterSpacing: 0.8,
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

class _CardSoldOverlay extends StatelessWidget {
  const _CardSoldOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0x18000000),
                  const Color(0x40000000),
                  const Color(0x66000000),
                ],
              ),
            ),
          ),
          Center(
            child: Transform.rotate(
              angle: -0.28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_soldBlueDark, _soldBlue],
                  ),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x440056D2),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 5),
                    Text(
                      'Sold',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SoldPill extends StatelessWidget {
  const SoldPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_soldBlueDark, _soldBlue],
        ),
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x280056D2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 10),
          SizedBox(width: 3),
          Text(
            'Sold',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 9.5,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
