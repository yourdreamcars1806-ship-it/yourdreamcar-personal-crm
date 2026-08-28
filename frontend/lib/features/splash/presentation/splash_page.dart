import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/navigation/open_panel.dart';
import '../../../services/auth_service.dart';
import '../../marketplace/presentation/user_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    required this.darkModeEnabled,
    required this.onThemeChanged,
  });

  final bool darkModeEnabled;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drive;
  Timer? _navTimer;

  static const _traffic = [
    _TrafficCar(lane: 0.10, speed: 0.55, phase: 0.02, reverse: false, width: 168, imageIndex: 0),
    _TrafficCar(lane: 0.21, speed: 0.82, phase: 0.45, reverse: true, width: 156, imageIndex: 1),
    _TrafficCar(lane: 0.67, speed: 0.7, phase: 0.18, reverse: false, width: 172, imageIndex: 2),
    _TrafficCar(lane: 0.77, speed: 1.05, phase: 0.62, reverse: true, width: 150, imageIndex: 3),
    _TrafficCar(lane: 0.87, speed: 0.6, phase: 0.30, reverse: false, width: 180, imageIndex: 4),
    _TrafficCar(lane: 0.12, speed: 0.95, phase: 0.78, reverse: true, width: 140, imageIndex: 2),
    _TrafficCar(lane: 0.72, speed: 0.48, phase: 0.88, reverse: false, width: 164, imageIndex: 1),
  ];

  @override
  void initState() {
    super.initState();
    _drive = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _navTimer = Timer(const Duration(milliseconds: 3400), _leaveSplash);
  }

  Future<void> _leaveSplash() async {
    if (!mounted) return;
    String? token;
    try {
      token = await AuthService.getStoredToken()
          .timeout(const Duration(milliseconds: 600));
    } catch (_) {
      token = null;
    }
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      final role = await AuthService.getStoredRole();
      if (!mounted) return;
      if (role == 'admin') {
        openPanelForRole(
          context,
          role: role,
          darkModeEnabled: widget.darkModeEnabled,
          onThemeChanged: widget.onThemeChanged,
        );
        return;
      }
    }
    _goMarketplace();
  }

  void _goMarketplace() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => UserShell(
          darkModeEnabled: widget.darkModeEnabled,
          onThemeChanged: widget.onThemeChanged,
        ),
        transitionDuration: const Duration(milliseconds: 650),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _drive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF001A4A),
                  Color(0xFF003EA8),
                  Color(0xFF0056D2),
                  Color(0xFF1A7CFF),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _drive,
            builder: (context, _) {
              return CustomPaint(
                painter: _RoadPainter(progress: _drive.value),
                size: size,
              );
            },
          ),
          AnimatedBuilder(
            animation: _drive,
            builder: (context, _) {
              return Stack(
                children: [
                  for (final car in _traffic)
                    _placedCar(size, car, _drive.value),
                ],
              );
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.72,
                colors: [
                  Color(0x99002A74),
                  Color(0x00000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                const _CenterLogo(),
                const Spacer(),
                const Text(
                  'Your Dream Car',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'BUY  •  SELL  •  DRIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placedCar(Size screen, _TrafficCar car, double t) {
    final w = car.width;
    final h = w * 0.56;
    final travel = screen.width + w + 64;
    final p = (t * car.speed + car.phase) % 1.0;
    final x = car.reverse ? screen.width - p * travel : p * travel - w;
    final y = screen.height * car.lane - h / 2;

    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Transform.flip(
          flipX: car.reverse,
          child: Image.asset(
            AppAssets.splashCars[car.imageIndex],
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

class _TrafficCar {
  const _TrafficCar({
    required this.lane,
    required this.speed,
    required this.phase,
    required this.reverse,
    required this.width,
    required this.imageIndex,
  });

  final double lane;
  final double speed;
  final double phase;
  final bool reverse;
  final double width;
  final int imageIndex;
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final roadTop = size.height * 0.58;
    final road = Paint()..color = const Color(0x33000000);
    canvas.drawRect(Rect.fromLTWH(0, roadTop, size.width, size.height), road);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0x66FFFFFF);
    canvas.drawLine(Offset(0, roadTop + 10), Offset(size.width, roadTop + 10), edge);
    canvas.drawLine(
      Offset(0, size.height - 18),
      Offset(size.width, size.height - 18),
      edge,
    );

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xCCFFD54F);

    for (final yFrac in [0.70, 0.82]) {
      _dashed(
        canvas,
        Offset(0, size.height * yFrac),
        Offset(size.width, size.height * yFrac),
        dashPaint,
        progress,
      );
    }
  }

  void _dashed(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint,
    double t,
  ) {
    const dash = 28.0;
    const gap = 22.0;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
    final metric = path.computeMetrics().first;
    final shift = (t * (dash + gap) * 8) % (dash + gap);
    var d = -shift;
    while (d < metric.length) {
      final start = d.clamp(0.0, metric.length);
      final end = (d + dash).clamp(0.0, metric.length);
      if (end > start) {
        canvas.drawPath(metric.extractPath(start, end), paint);
      }
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CenterLogo extends StatelessWidget {
  const _CenterLogo();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(8),
        child: Image.asset(AppAssets.logo, fit: BoxFit.contain),
      ),
    );
  }
}
