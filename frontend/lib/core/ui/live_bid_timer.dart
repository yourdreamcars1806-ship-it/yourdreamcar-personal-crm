import 'dart:async';

import 'package:flutter/material.dart';

String formatLiveBidElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:$m:$s';
  }
  return '$m:$s';
}

/// Pulsing live bid clock — pass [elapsed] from parent so all instances stay in sync.
class LiveBidTimerDisplay extends StatelessWidget {
  const LiveBidTimerDisplay({
    super.key,
    required this.elapsed,
    required this.pulse,
    this.compact = false,
  });

  final Duration elapsed;
  final Animation<double> pulse;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = formatLiveBidElapsed(elapsed);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              return Container(
                width: compact ? 8 : 10,
                height: compact ? 8 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFFFF6B6B),
                    const Color(0xFFE11D48),
                    pulse.value,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48)
                          .withValues(alpha: 0.35 + pulse.value * 0.35),
                      blurRadius: compact ? 6 : 10,
                      spreadRadius: compact ? 1 : 2,
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(width: compact ? 7 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LIVE BID',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 8.5 : 10,
                  letterSpacing: 1.1,
                ),
              ),
              if (!compact) const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 14 : 22,
                  letterSpacing: 1.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-width live bid banner for the bid form header.
class LiveBidTimerBanner extends StatelessWidget {
  const LiveBidTimerBanner({
    super.key,
    required this.elapsed,
    required this.pulse,
  });

  final Duration elapsed;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003EA8),
            Color(0xFF0056D2),
            Color(0xFF3D8BFF),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live bidding session',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Timer started — submit before you leave',
                      style: TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              LiveBidTimerDisplay(elapsed: elapsed, pulse: pulse),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Our team reviews live offers. Match the sell price to win instantly.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns a single session timer — use in [BidFormPage].
mixin LiveBidSessionMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController livePulse;
  Timer? _liveTick;
  Duration liveElapsed = Duration.zero;
  late final DateTime _liveStartedAt;

  void initLiveBidSession({DateTime? startedAt}) {
    _liveStartedAt = startedAt ?? DateTime.now();
    livePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _liveTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => liveElapsed = DateTime.now().difference(_liveStartedAt));
    });
  }

  void disposeLiveBidSession() {
    _liveTick?.cancel();
    livePulse.dispose();
  }
}
