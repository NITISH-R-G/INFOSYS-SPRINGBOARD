import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../animations/animations.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

/// ============================================================
/// LANDING SCREEN
/// iOS 26 Liquid Glass with Premium Animations
/// ============================================================

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _pillsController;
  late AnimationController _buttonsController;
  late AnimationController _glowPulseController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startEntranceSequence();
  }

  void _initAnimations() {
    // Logo entrance with spring bounce
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Title slide up
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 30), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _titleController,
            curve: AnimationConfig.primaryCurve,
          ),
        );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: AnimationConfig.primaryCurve,
      ),
    );

    // Pills stagger controller
    _pillsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Buttons entrance
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Continuous glow pulse
    _glowPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowPulse = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );
    _glowPulseController.repeat(reverse: true);
  }

  void _startEntranceSequence() async {
    // Staggered entrance sequence
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _pillsController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _buttonsController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _pillsController.dispose();
    _buttonsController.dispose();
    _glowPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              AppTheme.background,
              Color(0xFF0F1A12), // Subtle green tint at bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background glow
            _buildBackgroundGlow(),

            // Main content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),

                            // Animated Logo
                            _buildAnimatedLogo(),
                            const SizedBox(height: 32),

                            // Animated Title
                            _buildAnimatedTitle(),
                            const SizedBox(height: 48),

                            // Animated Feature Pills
                            _buildAnimatedPills(),

                            const SizedBox(height: 80),

                            // Animated CTA Buttons
                            _buildAnimatedButtons(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return AnimatedBuilder(
      animation: _glowPulse,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          left: 0,
          right: 0,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.glowGreen.withOpacity(_glowPulse.value * 0.3),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _glowPulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoOpacity.value.clamp(0.0, 1.0),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  // Dynamic glow
                  BoxShadow(
                    color: AppTheme.accentGreen.withOpacity(_glowPulse.value),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                  // Standard shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        return Transform.translate(
          offset: _titleSlide.value,
          child: Opacity(
            opacity: _titleOpacity.value.clamp(0.0, 1.0),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFB0B0B0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: const Text(
                    'ContractAI',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your AI-powered car contract assistant',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPills() {
    final features = [
      ('SLA Extraction', Icons.analytics_outlined),
      ('Fairness Score', Icons.balance),
      ('VIN Lookup', Icons.directions_car),
      ('AI Negotiation', Icons.chat_bubble_outline),
    ];

    return AnimatedBuilder(
      animation: _pillsController,
      builder: (context, child) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(features.length, (index) {
            final startTime = (index * 0.15).clamp(0.0, 0.5);
            final endTime = (startTime + 0.5).clamp(0.0, 1.0);

            final animation = CurvedAnimation(
              parent: _pillsController,
              curve: Interval(startTime, endTime, curve: Curves.easeOutBack),
            );

            return Transform.translate(
              offset: Offset(0, 20 * (1 - animation.value)),
              child: Opacity(
                opacity: animation.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.8 + (0.2 * animation.value),
                  child: _buildFeaturePill(
                    features[index].$1,
                    features[index].$2,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFeaturePill(String text, IconData icon) {
    return PhysicsTapButton(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.glassBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppTheme.accentGreen),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButtons() {
    return AnimatedBuilder(
      animation: _buttonsController,
      builder: (context, child) {
        final buttonAnimation = CurvedAnimation(
          parent: _buttonsController,
          curve: AnimationConfig.primaryCurve,
        );

        return Transform.translate(
          offset: Offset(0, 30 * (1 - buttonAnimation.value)),
          child: Opacity(
            opacity: buttonAnimation.value.clamp(0.0, 1.0),
            child: Column(
              children: [
                // Primary CTA (Client Auth)
                GlowRippleButton(
                  onTap: () async {
                    final auth = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    if (!auth.isLoggedIn ||
                        auth.currentUser?.role.name != 'client') {
                      await auth.loginAsClient('Demo User');
                    }
                    if (context.mounted) {
                      Navigator.pushNamed(context, '/dashboard');
                    }
                  },
                  glowColor: AppTheme.accentGreen,
                  borderRadius: 14,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGreen.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 22, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Get Started as Client',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Secondary CTA (Dealer Auth)
                PhysicsTapButton(
                  onTap: () async {
                    final auth = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    if (!auth.isLoggedIn ||
                        auth.currentUser?.role.name != 'dealer') {
                      await auth.loginAsDealer('Demo Dealer');
                    }
                    if (context.mounted) {
                      Navigator.pushNamed(context, '/dealer/dashboard');
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'Dealer Portal Access',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
