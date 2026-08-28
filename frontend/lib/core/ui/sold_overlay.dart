import 'package:flutter/material.dart';

class SoldOverlay extends StatelessWidget {
  const SoldOverlay({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: const Color(0x73000000),
        child: Center(
          child: Transform.rotate(
            angle: -0.42,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 12,
                vertical: compact ? 3 : 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: Text(
                'SOLD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 11 : 15,
                  letterSpacing: 1.6,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
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
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'SOLD',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
