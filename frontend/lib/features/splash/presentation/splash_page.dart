import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/brand_colors.dart';
import '../../auth/presentation/login_page.dart';

/// Full-screen branded splash shown before [LoginPage].
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
  late final AnimationController _pulse;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _navTimer = Timer(const Duration(milliseconds: 2800), _goLogin);
  }

  void _goLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LoginPage(
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 1.15,
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFEEF4FF),
                  Color(0xFFE5EEFF),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -h * 0.15,
            right: -80,
            child: _glowOrb(180, const Color(0x331D63ED)),
          ),
          Positioned(
            bottom: -h * 0.1,
            left: -60,
            child: _glowOrb(220, const Color(0x261D63ED)),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = 0.92 + _pulse.value * 0.08;
                      return Transform.scale(scale: t, child: child);
                    },
                    child: _LogoHero(),
                  ),
                  SizedBox(height: h * 0.045),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFF0F2442),
                          Color(0xFF1D63ED),
                          Color(0xFF0F2442),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds);
                    },
                    child: const Text(
                      'Your Dream Car',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Drive the future',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3A5D92),
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: h * 0.08),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: const Color(0xFF1D63ED),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _LogoHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'app_logo',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0x331D63ED),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0x1F1D63ED),
                blurRadius: 44,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: BrandColors.gold.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              AppAssets.logo,
              width: 148,
              height: 148,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
