import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'animation_config.dart';

/// ============================================================
/// PHYSICS-BASED ANIMATIONS
/// Spring-driven interactions with Apple motion feel
/// ============================================================

/// Spring-driven tap button with bounce feedback
class PhysicsTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final SpringDescription? spring;

  const PhysicsTapButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = 0.95,
    this.spring,
  });

  @override
  State<PhysicsTapButton> createState() => _PhysicsTapButtonState();
}

class _PhysicsTapButtonState extends State<PhysicsTapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.animateTo(
      1.0,
      duration: AnimationConfig.fast,
      curve: AnimationConfig.microCurve,
    );
  }

  void _onTapUp(TapUpDetails details) {
    _bounceBack();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _bounceBack();
  }

  void _bounceBack() {
    // Use physics simulation for natural bounce
    final spring = widget.spring ?? AnimationConfig.bouncySpring;
    final simulation = SpringSimulation(spring, _controller.value, 0.0, 0.0);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// ============================================================
/// ELASTIC DRAG CONTAINER
/// Drag-based UI elasticity with rubber band effect
/// ============================================================

class ElasticDragContainer extends StatefulWidget {
  final Widget child;
  final double maxOffset;
  final Axis axis;
  final Function(double)? onDragEnd;

  const ElasticDragContainer({
    super.key,
    required this.child,
    this.maxOffset = 100.0,
    this.axis = Axis.vertical,
    this.onDragEnd,
  });

  @override
  State<ElasticDragContainer> createState() => _ElasticDragContainerState();
}

class _ElasticDragContainerState extends State<ElasticDragContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _offset = 0.0;
  double _previousOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final delta = widget.axis == Axis.vertical
          ? details.delta.dy
          : details.delta.dx;
      
      // Rubber band effect - resistance increases with offset
      final resistance = 1 - (_offset.abs() / widget.maxOffset).clamp(0.0, 0.8);
      _offset += delta * resistance;
      _offset = _offset.clamp(-widget.maxOffset, widget.maxOffset);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    widget.onDragEnd?.call(_offset);
    
    // Spring back to zero
    final simulation = SpringSimulation(
      AnimationConfig.softSpring,
      _offset,
      0.0,
      details.velocity.pixelsPerSecond.dy / 1000,
    );

    _previousOffset = _offset;
    _controller.addListener(_updateOffset);
    _controller.animateWith(simulation).then((_) {
      _controller.removeListener(_updateOffset);
    });
  }

  void _updateOffset() {
    setState(() {
      _offset = _previousOffset * (1 - _controller.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: widget.axis == Axis.vertical
            ? Offset(0, _offset)
            : Offset(_offset, 0),
        child: widget.child,
      ),
    );
  }
}

/// ============================================================
/// GLOW RIPPLE BUTTON
/// Tap creates spreading glow ripple across surface
/// ============================================================

class GlowRippleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color glowColor;
  final double borderRadius;

  const GlowRippleButton({
    super.key,
    required this.child,
    this.onTap,
    this.glowColor = const Color(0xFF30D158),
    this.borderRadius = 16.0,
  });

  @override
  State<GlowRippleButton> createState() => _GlowRippleButtonState();
}

class _GlowRippleButtonState extends State<GlowRippleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnimation;
  late Animation<double> _opacityAnimation;
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConfig.slow,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.primaryCurve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.primaryCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    setState(() {
      _tapPosition = details.localPosition;
    });
    _controller.forward(from: 0.0);
  }

  void _onTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTap: _onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (!_controller.isAnimating && _controller.value == 0) {
                    return const SizedBox.shrink();
                  }

                  return CustomPaint(
                    painter: _RipplePainter(
                      center: _tapPosition,
                      progress: _rippleAnimation.value,
                      opacity: _opacityAnimation.value,
                      color: widget.glowColor,
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
}

class _RipplePainter extends CustomPainter {
  final Offset center;
  final double progress;
  final double opacity;
  final Color color;

  _RipplePainter({
    required this.center,
    required this.progress,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = (size.width > size.height ? size.width : size.height);
    final radius = maxRadius * progress;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}

/// ============================================================
/// PARALLAX SCROLL CONTAINER
/// Depth illusion with layered parallax movement
/// ============================================================

class ParallaxContainer extends StatelessWidget {
  final ScrollController scrollController;
  final Widget child;
  final double parallaxFactor;
  final Offset baseOffset;

  const ParallaxContainer({
    super.key,
    required this.scrollController,
    required this.child,
    this.parallaxFactor = 0.3,
    this.baseOffset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        
        final parallaxOffset = Offset(
          baseOffset.dx,
          baseOffset.dy - (scrollOffset * parallaxFactor),
        );

        return Transform.translate(
          offset: parallaxOffset,
          child: child,
        );
      },
    );
  }
}
