import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)));
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    _shimmerAnim = Tween<double>(begin: -2, end: 2).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.linear));

    _mainController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final restored = await auth.restoreSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, restored ? '/dashboard' : '/login');
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: Stack(
          children: [
            // Floating decorative circles
            ..._buildFloatingOrbs(),
            // Star particles
            ..._buildStarParticles(),
            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floating logo
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      ),
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentYellow.withValues(alpha: 0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: Image.asset('assets/images/logo.png',
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title with shimmer
                    AnimatedBuilder(
                      animation: _shimmerAnim,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment(_shimmerAnim.value - 1, 0),
                            end: Alignment(_shimmerAnim.value + 1, 0),
                            colors: const [
                              Colors.white,
                              AppTheme.accentYellow,
                              Colors.white,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                          child: child,
                        );
                      },
                      child: const Text(
                        'Nova',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),

                    // Subtitle
                    AnimatedBuilder(
                      animation: _slideAnim,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: child,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          '🚀 Learn · Grow · Shine ✨',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading dots
                    _buildLoadingDots(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.33;
            final t = (_shimmerController.value - delay).clamp(0.0, 1.0);
            final opacity = (math.sin(t * math.pi * 2) * 0.5 + 0.5).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  List<Widget> _buildFloatingOrbs() {
    final rng = math.Random(42);
    return List.generate(6, (i) {
      final size = rng.nextDouble() * 100 + 60;
      final left = rng.nextDouble() * 400 - 50;
      final top = rng.nextDouble() * 900 - 50;
      final colors = [
        AppTheme.accentYellow.withValues(alpha: 0.15),
        AppTheme.accentMint.withValues(alpha: 0.1),
        AppTheme.accentCyan.withValues(alpha: 0.12),
        AppTheme.accentPink.withValues(alpha: 0.1),
        Colors.white.withValues(alpha: 0.07),
        AppTheme.primaryLight.withValues(alpha: 0.15),
      ];
      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _floatAnim.value * (i % 2 == 0 ? 1 : -1)),
            child: child,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[i % colors.length],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildStarParticles() {
    final rng = math.Random(99);
    final starEmojis = ['⭐', '✨', '🌟', '💫', '⚡'];
    return List.generate(8, (i) {
      final left = rng.nextDouble() * 360;
      final top = rng.nextDouble() * 800;
      final size = rng.nextDouble() * 14 + 12;
      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) => Transform.rotate(
            angle: _floatController.value * math.pi * 2 * (i.isEven ? 1 : -1),
            child: child,
          ),
          child: Text(
            starEmojis[i % starEmojis.length],
            style: TextStyle(fontSize: size),
          ),
        ),
      );
    });
  }
}
