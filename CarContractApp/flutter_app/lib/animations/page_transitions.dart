import 'dart:ui';
import 'package:flutter/material.dart';
import 'animation_config.dart';

/// ============================================================
/// LIQUID GLASS PAGE TRANSITIONS
/// Fluid navigation with blur continuity
/// ============================================================

/// Liquid Glass page route with custom transition
class LiquidGlassPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String? heroTag;

  LiquidGlassPageRoute({
    required this.page,
    this.heroTag,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AnimationConfig.hero,
          reverseTransitionDuration: AnimationConfig.normal,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _LiquidGlassTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        );
}

class _LiquidGlassTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _LiquidGlassTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AnimationConfig.primaryCurve,
      reverseCurve: AnimationConfig.exitCurve,
    );

    // Fade animation
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    // Slide animation
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curvedAnimation);

    // Scale animation
    final scaleAnimation = Tween<double>(
      begin: 0.97,
      end: 1.0,
    ).animate(curvedAnimation);

    // Blur animation for entering page
    final blurAnimation = Tween<double>(
      begin: 10.0,
      end: 0.0,
    ).animate(curvedAnimation);

    // Secondary (exiting page) animations
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AnimationConfig.exitCurve,
    );

    final secondaryScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(secondaryCurved);

    final secondaryOpacity = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(secondaryCurved);

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, _) {
        return Stack(
          children: [
            // Exiting page (if secondary animation active)
            if (secondaryAnimation.value > 0)
              Transform.scale(
                scale: secondaryScale.value,
                child: Opacity(
                  opacity: secondaryOpacity.value,
                  child: child,
                ),
              ),
            
            // Entering page
            FadeTransition(
              opacity: fadeAnimation,
              child: Transform.translate(
                offset: Offset(0, slideAnimation.value.dy * 50),
                child: Transform.scale(
                  scale: scaleAnimation.value,
                  child: blurAnimation.value > 0.5
                    ? ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: blurAnimation.value,
                            sigmaY: blurAnimation.value,
                          ),
                          child: child,
                        ),
                      )
                    : child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ============================================================
/// HERO MORPH CONTAINER
/// Shared element that morphs between screens
/// ============================================================

class HeroMorphContainer extends StatelessWidget {
  final String tag;
  final Widget child;
  final double fromRadius;
  final double toRadius;
  final Color? backgroundColor;

  const HeroMorphContainer({
    super.key,
    required this.tag,
    required this.child,
    this.fromRadius = 20.0,
    this.toRadius = 0.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AnimationConfig.primaryCurve,
        );

        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, _) {
            final radius = Tween<double>(
              begin: flightDirection == HeroFlightDirection.push 
                  ? fromRadius 
                  : toRadius,
              end: flightDirection == HeroFlightDirection.push 
                  ? toRadius 
                  : fromRadius,
            ).evaluate(curvedAnimation);

            final blur = Tween<double>(
              begin: 0.0,
              end: 5.0,
            ).evaluate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ));

            return Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor ?? 
                          const Color(0xFF1C1C1E).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// ============================================================
/// MODAL SHEET TRANSITION
/// Bottom sheet with liquid glass appearance
/// ============================================================

Future<T?> showLiquidGlassBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  double? height,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    transitionAnimationController: AnimationController(
      duration: AnimationConfig.normal,
      vsync: Navigator.of(context),
    ),
    builder: (context) => _LiquidGlassSheet(
      height: height,
      child: builder(context),
    ),
  );
}

class _LiquidGlassSheet extends StatelessWidget {
  final Widget child;
  final double? height;

  const _LiquidGlassSheet({
    required this.child,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = height ?? screenHeight * 0.5;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// FADE SCALE TRANSITION
/// Simple fade + scale for dialogs
/// ============================================================

class FadeScaleTransitionPage extends Page {
  final Widget child;

  const FadeScaleTransitionPage({
    required this.child,
    super.key,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: AnimationConfig.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AnimationConfig.primaryCurve,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
