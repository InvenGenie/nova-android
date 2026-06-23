import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _cardController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _cardController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
        _usernameController.text.trim(), _passwordController.text);
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('❌ ', style: TextStyle(fontSize: 18)),
              Expanded(child: Text(auth.error ?? 'Login failed',
                  style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600))),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          final t = _bgController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 0.6, -1),
                end: Alignment(1 - t * 0.4, 1),
                colors: const [
                  Color(0xFF2D0B7A),
                  Color(0xFF6C3CE1),
                  Color(0xFF4ECDC4),
                ],
                stops: [0.0, 0.5 + t * 0.2, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Decorative elements
            ..._buildDecorations(size),

            SafeArea(
              child: Column(
                children: [
                  // Top header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                    child: AnimatedBuilder(
                      animation: _cardFade,
                      builder: (_, child) =>
                          Opacity(opacity: _cardFade.value, child: child),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo + wave
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset('assets/images/logo.png',
                                      fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nova',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        fontFamily: 'Nunito',
                                        letterSpacing: -0.5,
                                      )),
                                  Text('Learning made fun! 🎉',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            "Let's start\nlearning! 🚀",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue your adventure',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Form card
                  AnimatedBuilder(
                    animation: _cardSlide,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _cardSlide.value),
                      child: Opacity(opacity: _cardFade.value, child: child),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle pill
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 28),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),

                            Text('Your username',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Nunito',
                                  letterSpacing: 0.5,
                                )),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                hintText: 'Enter your username',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(10),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.person_rounded,
                                      color: AppTheme.primary, size: 18),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Please enter your username'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            Text('Your password',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Nunito',
                                  letterSpacing: 0.5,
                                )),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(10),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.lock_rounded,
                                      color: AppTheme.accent, size: 18),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.grey.shade400,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter your password'
                                  : null,
                            ),

                            const SizedBox(height: 32),

                            // Sign in button
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return GestureDetector(
                                  onTap: auth.loading ? null : _login,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: auth.loading
                                          ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300])
                                          : const LinearGradient(
                                              colors: [Color(0xFF6C3CE1), Color(0xFF4ECDC4)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: auth.loading
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: AppTheme.primary.withValues(alpha: 0.4),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                    ),
                                    child: Center(
                                      child: auth.loading
                                          ? const SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 3,
                                                  color: Colors.white))
                                          : const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "Let's Go! 🚀",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                    fontFamily: 'Nunito',
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot password? Ask your teacher 😊',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDecorations(Size size) {
    final rng = math.Random(77);
    final items = ['⭐', '🌟', '💫', '✨', '🎯', '📚', '🎮', '🏆'];
    return [
      ...List.generate(8, (i) {
        final left = rng.nextDouble() * size.width;
        final top = rng.nextDouble() * size.height * 0.7;
        final s = rng.nextDouble() * 16 + 14;
        return Positioned(
          left: left,
          top: top,
          child: AnimatedBuilder(
            animation: _bgController,
            builder: (_, child) => Transform.rotate(
              angle: _bgController.value * math.pi * 2 * (i.isEven ? 0.3 : -0.3),
              child: Opacity(
                opacity: 0.5,
                child: Text(items[i % items.length],
                    style: TextStyle(fontSize: s)),
              ),
            ),
          ),
        );
      }),
      // Bottom decoration circles
      Positioned(
        right: -40,
        top: size.height * 0.15,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      Positioned(
        left: -60,
        top: size.height * 0.35,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentYellow.withValues(alpha: 0.08),
          ),
        ),
      ),
    ];
  }
}
