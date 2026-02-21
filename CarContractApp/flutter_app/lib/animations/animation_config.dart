import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';

/// ============================================================
/// APPLE-INSPIRED ANIMATION CONFIGURATION
/// iOS 26 Liquid Glass Motion System
/// ============================================================

class AnimationConfig {
  AnimationConfig._();

  // ─────────────────────────────────────────────────────────────
  // DURATION CONSTANTS
  // ─────────────────────────────────────────────────────────────
  
  /// Ultra-fast micro-interactions (hover, focus)
  static const Duration micro = Duration(milliseconds: 100);
  
  /// Quick state changes (button press, toggle)
  static const Duration fast = Duration(milliseconds: 200);
  
  /// Standard transitions (modal, expand)
  static const Duration normal = Duration(milliseconds: 350);
  
  /// Smooth page transitions
  static const Duration slow = Duration(milliseconds: 500);
  
  /// Hero transitions, complex morphing
  static const Duration hero = Duration(milliseconds: 450);
  
  /// Stagger delay between sequential items
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // ─────────────────────────────────────────────────────────────
  // APPLE MOTION CURVES
  // ─────────────────────────────────────────────────────────────
  
  /// Primary motion - smooth deceleration
  static const Curve primaryCurve = Curves.easeOutCubic;
  
  /// Secondary motion - balanced ease
  static const Curve secondaryCurve = Curves.easeInOut;
  
  /// Micro-interactions - quick response
  static const Curve microCurve = Curves.easeOutQuart;
  
  /// Fast exit to slow land
  static const Curve fastToSlow = Curves.fastEaseInToSlowEaseOut;
  
  /// Entrance animations
  static const Curve entranceCurve = Curves.easeOutBack;
  
  /// Exit animations
  static const Curve exitCurve = Curves.easeInCubic;
  
  /// Spring-like bounce
  static const Curve bounceCurve = Curves.elasticOut;

  // ─────────────────────────────────────────────────────────────
  // SPRING PHYSICS CONFIGURATIONS
  // ─────────────────────────────────────────────────────────────
  
  /// Standard spring - responsive with subtle bounce
  static SpringDescription get standardSpring => const SpringDescription(
    mass: 1.0,
    stiffness: 400.0,
    damping: 30.0,
  );
  
  /// Soft spring - gentle, organic feel
  static SpringDescription get softSpring => const SpringDescription(
    mass: 1.0,
    stiffness: 200.0,
    damping: 25.0,
  );
  
  /// Snappy spring - quick response
  static SpringDescription get snappySpring => const SpringDescription(
    mass: 1.0,
    stiffness: 600.0,
    damping: 40.0,
  );
  
  /// Bouncy spring - playful interactions
  static SpringDescription get bouncySpring => const SpringDescription(
    mass: 1.0,
    stiffness: 350.0,
    damping: 15.0,
  );

  // ─────────────────────────────────────────────────────────────
  // INTERACTION SCALE VALUES
  // ─────────────────────────────────────────────────────────────
  
  /// Scale down on press
  static const double pressedScale = 0.96;
  
  /// Scale up on hover
  static const double hoverScale = 1.02;
  
  /// Standard scale
  static const double normalScale = 1.0;

  // ─────────────────────────────────────────────────────────────
  // BLUR CONFIGURATIONS
  // ─────────────────────────────────────────────────────────────
  
  /// Standard glass blur
  static const double glassBlur = 20.0;
  
  /// Light glass blur
  static const double lightBlur = 10.0;
  
  /// Heavy immersive blur
  static const double heavyBlur = 40.0;
  
  /// Blur increase on interaction
  static const double interactionBlurBoost = 5.0;

  // ─────────────────────────────────────────────────────────────
  // OPACITY VALUES
  // ─────────────────────────────────────────────────────────────
  
  /// Glass surface opacity
  static const double glassOpacity = 0.15;
  
  /// Glass border opacity
  static const double borderOpacity = 0.2;
  
  /// Highlight glow opacity
  static const double glowOpacity = 0.3;
  
  /// Shadow opacity
  static const double shadowOpacity = 0.25;
}

/// ============================================================
/// REDUCED MOTION UTILITY
/// Respects system accessibility settings
/// ============================================================

class MotionPreferences {
  static bool _reduceMotion = false;
  
  /// Check if reduced motion is preferred
  static bool get reduceMotion => _reduceMotion;
  
  /// Initialize from platform
  static void init(BuildContext context) {
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }
  
  /// Get duration respecting reduced motion
  static Duration getDuration(Duration standard) {
    return _reduceMotion ? Duration.zero : standard;
  }
  
  /// Get curve respecting reduced motion
  static Curve getCurve(Curve standard) {
    return _reduceMotion ? Curves.linear : standard;
  }
}

/// ============================================================
/// SPRING SIMULATION HELPER
/// Creates physics-based animations
/// ============================================================

class SpringAnimationHelper {
  /// Create a spring simulation for a value change
  static SpringSimulation createSpring({
    required double start,
    required double end,
    required double velocity,
    SpringDescription? spring,
  }) {
    return SpringSimulation(
      spring ?? AnimationConfig.standardSpring,
      start,
      end,
      velocity,
    );
  }
  
  /// Run a spring animation on a controller
  static void animateWithSpring(
    AnimationController controller, {
    required double target,
    double velocity = 0.0,
    SpringDescription? spring,
  }) {
    final simulation = SpringSimulation(
      spring ?? AnimationConfig.standardSpring,
      controller.value,
      target,
      velocity,
    );
    controller.animateWith(simulation);
  }
}

/// ============================================================
/// STAGGER ANIMATION UTILITY
/// Sequential reveal animations
/// ============================================================

class StaggerHelper {
  /// Get staggered delay for an item at index
  static Duration getDelay(int index) {
    return Duration(
      milliseconds: AnimationConfig.staggerDelay.inMilliseconds * index,
    );
  }
  
  /// Get staggered interval for animation
  static Interval getInterval(int index, int total) {
    final start = (index / total) * 0.5;
    final end = start + 0.5;
    return Interval(
      start.clamp(0.0, 1.0),
      end.clamp(0.0, 1.0),
      curve: AnimationConfig.primaryCurve,
    );
  }
}

/// ============================================================
/// TWEEN HELPERS
/// Common animation value interpolations
/// ============================================================

class TweenConfig {
  /// Scale tween for press effect
  static Tween<double> get pressScale => Tween<double>(
    begin: AnimationConfig.normalScale,
    end: AnimationConfig.pressedScale,
  );
  
  /// Scale tween for hover effect
  static Tween<double> get hoverScale => Tween<double>(
    begin: AnimationConfig.normalScale,
    end: AnimationConfig.hoverScale,
  );
  
  /// Opacity tween 0 to 1
  static Tween<double> get fadeIn => Tween<double>(begin: 0.0, end: 1.0);
  
  /// Offset tween for slide up entrance
  static Tween<Offset> get slideUp => Tween<Offset>(
    begin: const Offset(0, 0.1),
    end: Offset.zero,
  );
  
  /// Blur tween for interaction
  static Tween<double> get blurInteraction => Tween<double>(
    begin: AnimationConfig.glassBlur,
    end: AnimationConfig.glassBlur + AnimationConfig.interactionBlurBoost,
  );
}
