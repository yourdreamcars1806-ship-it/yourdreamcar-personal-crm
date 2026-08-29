import 'package:flutter/material.dart';

/// Continuous horizontal marquee text (no layout overflow).
class MarqueeStrip extends StatefulWidget {
  const MarqueeStrip({
    super.key,
    required this.text,
    this.style,
    this.speed = 34,
    this.gap = 48,
  });

  final String text;
  final TextStyle? style;
  final double speed;
  final double gap;

  @override
  State<MarqueeStrip> createState() => _MarqueeStripState();
}

class _MarqueeStripState extends State<MarqueeStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  double _segmentWidth = 1;
  String _activeText = '';

  TextStyle get _style =>
      widget.style ??
      const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A2744),
        height: 1.15,
      );

  double get _lineHeight => (_style.fontSize ?? 12.5) * (_style.height ?? 1.15) + 2;

  @override
  void didUpdateWidget(covariant MarqueeStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _activeText = '';
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _measure(String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  void _ensureLoop() {
    if (widget.text.isEmpty) return;
    final w = _measure(widget.text) + widget.gap;
    if (w <= 0) return;
    _segmentWidth = w;
    final ms = ((w / widget.speed) * 1000).round().clamp(9000, 70000);
    if (_activeText != widget.text) {
      _activeText = widget.text;
      _controller
        ..duration = Duration(milliseconds: ms)
        ..repeat();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  Widget _line() {
    return Text(
      widget.text,
      style: _style,
      maxLines: 1,
      softWrap: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();
    _ensureLoop();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return SizedBox(
            height: _lineHeight,
            child: Align(alignment: Alignment.centerLeft, child: _line()),
          );
        }

        return SizedBox(
          height: _lineHeight,
          width: width,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: width,
              maxWidth: double.infinity,
              maxHeight: _lineHeight,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Transform.translate(
                    offset: Offset(-_controller.value * _segmentWidth, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          _line(),
                          SizedBox(width: widget.gap),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
