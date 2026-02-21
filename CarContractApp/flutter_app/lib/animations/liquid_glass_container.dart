import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'animation_config.dart';

/// ============================================================
/// LIQUID GLASS CONTAINER
/// iOS 26 Inspired Frosted Glass with Dynamic Effects
/// ============================================================

class LiquidGlassContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurStrength;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? glowColor;
  final bool enableTapFeedback;
  final bool enableHoverEffect;
  final bool enableGlowPulse;
  final VoidCallback? onTap;
  final String? heroTag;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.blurStrength = 20.0,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
    this.enableTapFeedback = true,
    this.enableHoverEffect = true,
    this.enableGlowPulse = false,
    this.onTap,
    this.heroTag,
  });

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _scaleController;
  late AnimationController _blurController;
  late AnimationController _glowController;
  late AnimationController _hoverController;

  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _hoverAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Scale animation for tap feedback
    _scaleController = AnimationController(
      duration: AnimationConfig.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AnimationConfig.pressedScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AnimationConfig.microCurve,
    ));

    // Blur animation for interaction
    _blurController = AnimationController(
      duration: AnimationConfig.normal,
      vsync: this,
    );
    _blurAnimation = Tween<double>(
      begin: widget.blurStrength,
      end: widget.blurStrength + AnimationConfig.interactionBlurBoost,
    ).animate(CurvedAnimation(
      parent: _blurController,
      curve: AnimationConfig.secondaryCurve,
    ));

    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enableGlowPulse) {
      _glowController.repeat(reverse: true);
    }

    // Hover animation
    _hoverController = AnimationController(
      duration: AnimationConfig.fast,
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: AnimationConfig.hoverScale,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AnimationConfig.microCurve,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _blurController.dispose();
    _glowController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enableTapFeedback) return;
    setState(() => _isPressed = true);
    _scaleController.forward();
    _blurController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enableTapFeedback) return;
    setState(() => _isPressed = false);
    // Spring bounce back
    SpringAnimationHelper.animateWithSpring(
      _scaleController,
      target: 0.0,
      spring: AnimationConfig.bouncySpring,
    );
    _blurController.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enableTapFeedback) return;
    setState(() => _isPressed = false);
    _scaleController.reverse();
    _blurController.reverse();
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = true);
    _hoverController.forward();
    _blurController.forward();
  }

  void _handleMouseExit(PointerExitEvent event) {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = false);
    _hoverController.reverse();
    _blurController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Colors
    final bgColor = widget.backgroundColor ?? 
        const Color(0xFF1C1C1E).withOpacity(AnimationConfig.glassOpacity);
    final borderColor = widget.borderColor ?? 
        Colors.white.withOpacity(AnimationConfig.borderOpacity);
    final glowColor = widget.glowColor ?? 
        const Color(0xFF30D158).withOpacity(AnimationConfig.glowOpacity);

    Widget content = AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _blurAnimation,
        _glowAnimation,
        _hoverAnimation,
      ]),
      builder: (context, child) {
        // Calculate combined scale
        double scale = _scaleAnimation.value;
        if (_isHovered) {
          scale = _hoverAnimation.value;
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                // Soft diffuse shadow
                BoxShadow(
                  color: Colors.black.withOpacity(AnimationConfig.shadowOpacity),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
                // Glow effect
                if (widget.enableGlowPulse || _isPressed)
                  BoxShadow(
                    color: glowColor.withOpacity(
                      _glowAnimation.value * 0.3 + (_isPressed ? 0.2 : 0.0),
                    ),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: borderColor.withOpacity(
                        AnimationConfig.borderOpacity + 
                        (_isHovered ? 0.1 : 0.0) +
                        (_isPressed ? 0.15 : 0.0),
                      ),
                      width: 1.0,
                    ),
                    // Inner highlight gradient
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );

    // Wrap with gesture detectors
    content = MouseRegion(
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: content,
      ),
    );

    // Wrap with Hero if tag provided
    if (widget.heroTag != null) {
      content = Hero(
        tag: widget.heroTag!,
        flightShuttleBuilder: _heroFlightShuttleBuilder,
        child: Material(
          type: MaterialType.transparency,
          child: content,
        ),
      );
    }

    return content;
  }

  /// Custom Hero flight animation with blur continuity
  Widget _heroFlightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AnimationConfig.primaryCurve,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        final radius = Tween<double>(
          begin: widget.borderRadius,
          end: 0.0,
        ).evaluate(curvedAnimation);

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blurStrength,
              sigmaY: widget.blurStrength,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: (widget.backgroundColor ?? const Color(0xFF1C1C1E))
                    .withOpacity(AnimationConfig.glassOpacity),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// ============================================================
/// SCROLL REACTIVE GLASS HEADER
/// Responds to scroll with dynamic blur and opacity
/// ============================================================

class ScrollReactiveGlassHeader extends StatelessWidget {
  final ScrollController scrollController;
  final Widget child;
  final double maxBlur;
  final double height;

  const ScrollReactiveGlassHeader({
    super.key,
    required this.scrollController,
    required this.child,
    this.maxBlur = 30.0,
    this.height = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final scrollOffset = scrollController.hasClients 
            ? scrollController.offset.clamp(0.0, 100.0) 
            : 0.0;
        final progress = scrollOffset / 100.0;
        final blur = AnimationConfig.lightBlur + (progress * maxBlur);
        final opacity = 0.1 + (progress * 0.2);

        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E).withOpacity(opacity),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(progress * 0.2),
                  ),
                ),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
