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

/// Self-updating live bid clock for home cards & car details (uses server start time).
class LiveBidTicker extends StatefulWidget {
  const LiveBidTicker({
    super.key,
    this.startedAt,
    this.compact = false,
    this.dark = false,
  });

  final DateTime? startedAt;
  final bool compact;
  final bool dark;

  @override
  State<LiveBidTicker> createState() => _LiveBidTickerState();
}

class _LiveBidTickerState extends State<LiveBidTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _tick;
  late DateTime _started;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _started = widget.startedAt ?? DateTime.now();
    _elapsed = DateTime.now().difference(_started);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(_started));
    });
  }

  @override
  void didUpdateWidget(covariant LiveBidTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt && widget.startedAt != null) {
      _started = widget.startedAt!;
      _elapsed = DateTime.now().difference(_started);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dark) {
      return LiveBidTimerDisplay(
        elapsed: _elapsed,
        pulse: _pulse,
        compact: widget.compact,
      );
    }
    return _LiveBidInlineChip(elapsed: _elapsed, pulse: _pulse, compact: widget.compact);
  }
}

class _LiveBidInlineChip extends StatelessWidget {
  const _LiveBidInlineChip({
    required this.elapsed,
    required this.pulse,
    required this.compact,
  });

  final Duration elapsed;
  final Animation<double> pulse;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = formatLiveBidElapsed(elapsed);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFE11D48)],
        ),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) => Container(
              width: compact ? 6 : 8,
              height: compact ? 6 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.85 + pulse.value * 0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4 + pulse.value * 0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: compact ? 5 : 7),
          Text(
            compact ? 'LIVE $label' : 'LIVE BID · $label',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 10 : 11.5,
              letterSpacing: 0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Prominent live-bid strip for car details & listings.
class LiveBidPromoBanner extends StatelessWidget {
  const LiveBidPromoBanner({
    super.key,
    required this.startedAt,
    this.subtitle,
  });

  final DateTime? startedAt;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF991B1B),
            Color(0xFFDC2626),
            Color(0xFFE11D48),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40DC2626),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live bidding is ON',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle ?? 'Timer running — place your bid now',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          LiveBidTicker(startedAt: startedAt, dark: true),
        ],
      ),
    );
  }
}
