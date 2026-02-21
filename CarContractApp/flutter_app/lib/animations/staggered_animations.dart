import 'package:flutter/material.dart';
import 'animation_config.dart';

/// ============================================================
/// STAGGERED ANIMATIONS
/// Sequential reveal with Apple-inspired timing
/// ============================================================

/// Staggered list animation wrapper
class StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final Curve curve;
  final Offset slideOffset;
  final bool fadeIn;
  final bool slideIn;
  final Axis axis;

  const StaggeredList({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.curve = Curves.easeOutCubic,
    this.slideOffset = const Offset(0, 20),
    this.fadeIn = true,
    this.slideIn = true,
    this.axis = Axis.vertical,
  });

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    final totalDuration = widget.itemDuration +
        Duration(milliseconds: widget.staggerDelay.inMilliseconds * widget.children.length);

    _controller = AnimationController(
      duration: totalDuration,
      vsync: this,
    );

    for (int i = 0; i < widget.children.length; i++) {
      final startTime = (widget.staggerDelay.inMilliseconds * i) / 
          totalDuration.inMilliseconds;
      final endTime = startTime + 
          (widget.itemDuration.inMilliseconds / totalDuration.inMilliseconds);

      final interval = Interval(
        startTime.clamp(0.0, 1.0),
        endTime.clamp(0.0, 1.0),
        curve: widget.curve,
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: interval),
        ),
      );

      _slideAnimations.add(
        Tween<Offset>(begin: widget.slideOffset, end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: interval),
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final children = <Widget>[];
        
        for (int i = 0; i < widget.children.length; i++) {
          Widget item = widget.children[i];

          if (widget.slideIn) {
            item = Transform.translate(
              offset: _slideAnimations[i].value,
              child: item,
            );
          }

          if (widget.fadeIn) {
            item = Opacity(
              opacity: _fadeAnimations[i].value,
              child: item,
            );
          }

          children.add(item);
        }

        if (widget.axis == Axis.vertical) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        } else {
          return Row(children: children);
        }
      },
    );
  }
}

/// ============================================================
/// ANIMATED ENTRANCE WIDGET
/// Single item entrance animation
/// ============================================================

class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset slideFrom;
  final double scaleFrom;
  final bool fade;
  final bool slide;
  final bool scale;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.slideFrom = const Offset(0, 30),
    this.scaleFrom = 0.9,
    this.fade = true,
    this.slide = true,
    this.scale = false,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideFrom,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _scaleAnimation = Tween<double>(
      begin: widget.scaleFrom,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget result = widget.child;

        if (widget.scale) {
          result = Transform.scale(
            scale: _scaleAnimation.value,
            child: result,
          );
        }

        if (widget.slide) {
          result = Transform.translate(
            offset: _slideAnimation.value,
            child: result,
          );
        }

        if (widget.fade) {
          result = Opacity(
            opacity: _fadeAnimation.value,
            child: result,
          );
        }

        return result;
      },
    );
  }
}

/// ============================================================
/// DASHBOARD CARD STAGGER
/// Specialized stagger for dashboard contract cards
/// ============================================================

class DashboardCardStagger extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int, Animation<double>) itemBuilder;
  final ScrollController? scrollController;

  const DashboardCardStagger({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollController,
  });

  @override
  State<DashboardCardStagger> createState() => _DashboardCardStaggerState();
}

class _DashboardCardStaggerState extends State<DashboardCardStagger>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(
        milliseconds: 300 + (widget.itemCount * 80),
      ),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        final startTime = (index * 0.1).clamp(0.0, 0.5);
        final endTime = (startTime + 0.5).clamp(0.0, 1.0);
        
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            startTime,
            endTime,
            curve: AnimationConfig.entranceCurve,
          ),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - animation.value)),
              child: Opacity(
                opacity: animation.value,
                child: Transform.scale(
                  scale: 0.95 + (0.05 * animation.value),
                  child: widget.itemBuilder(context, index, animation),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
