import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/navigation/open_panel.dart';
import '../../../core/ui/app_logo.dart';
import '../../../services/auth_service.dart';
import '../../../services/car_catalog_service.dart';
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
    with TickerProviderStateMixin {
  late final AnimationController _drive;
  late final AnimationController _intro;
  late final Animation<double> _introFade;
  late final Animation<double> _introScale;
  Timer? _navTimer;

  /// Cars stay on the bottom road only.
  static const _traffic = [
    _TrafficCar(lane: 0.74, speed: 0.62, phase: 0.05, reverse: false, width: 158, imageIndex: 0),
    _TrafficCar(lane: 0.80, speed: 0.88, phase: 0.42, reverse: true, width: 148, imageIndex: 1),
    _TrafficCar(lane: 0.86, speed: 0.72, phase: 0.22, reverse: false, width: 162, imageIndex: 2),
    _TrafficCar(lane: 0.92, speed: 1.0, phase: 0.58, reverse: true, width: 142, imageIndex: 3),
    _TrafficCar(lane: 0.78, speed: 0.54, phase: 0.76, reverse: false, width: 152, imageIndex: 4),
  ];

  @override
  void initState() {
    super.initState();
    _drive = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _introFade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    _introScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
    );
    _intro.forward();
    unawaited(CarCatalogService.instance.bootstrap());
    _navTimer = Timer(const Duration(milliseconds: 2200), _leaveSplash);
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
    _intro.dispose();
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF001040),
                  Color(0xFF002D7A),
                  Color(0xFF0056D2),
                  Color(0xFF1A6FE8),
                ],
                stops: [0, 0.35, 0.72, 1],
              ),
            ),
          ),
          Positioned(
            right: -60,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -80,
            top: 120,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFC14A).withValues(alpha: 0.07),
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
                  _ParkedShowcase(screenWidth: size.width, screenHeight: size.height),
                ],
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.12),
                ],
                stops: const [0, 0.28, 0.62, 1],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _introFade,
              child: ScaleTransition(
                scale: _introScale,
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    const _TopBrand(),
                    const Spacer(),
                    _BottomLoader(progress: _drive),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
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

class _ParkedShowcase extends StatelessWidget {
  const _ParkedShowcase({
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: screenWidth * 0.08,
          top: screenHeight * 0.66,
          width: 120,
          child: Opacity(
            opacity: 0.92,
            child: Image.asset(
              AppAssets.splashCars[4],
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          right: screenWidth * 0.06,
          top: screenHeight * 0.68,
          width: 130,
          child: Opacity(
            opacity: 0.88,
            child: Image.asset(
              AppAssets.splashCars[2],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBrand extends StatelessWidget {
  const _TopBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.78),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFFFFC14A).withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFC14A).withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: const AppLogo(round: true, width: 116),
          ),
        ),
        const SizedBox(height: 22),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFE8F0FF)],
          ).createShader(bounds),
          child: const Text(
            'Your Dream Car',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'BUY  •  SELL  •  DRIVE',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomLoader extends StatelessWidget {
  const _BottomLoader({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Loading your marketplace…',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
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
    final roadTop = size.height * 0.62;

    final roadGrad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0A1628).withValues(alpha: 0.0),
          const Color(0xFF0A1628).withValues(alpha: 0.55),
          const Color(0xFF050D18).withValues(alpha: 0.85),
        ],
        stops: const [0, 0.35, 1],
      ).createShader(Rect.fromLTWH(0, roadTop, size.width, size.height - roadTop));
    canvas.drawRect(Rect.fromLTWH(0, roadTop, size.width, size.height - roadTop), roadGrad);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawLine(Offset(0, roadTop + 8), Offset(size.width, roadTop + 8), edge);
    canvas.drawLine(
      Offset(0, size.height - 14),
      Offset(size.width, size.height - 14),
      edge,
    );

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xE6FFD54F);

    for (final yFrac in [0.74, 0.84, 0.93]) {
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
    const dash = 26.0;
    const gap = 20.0;
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
