import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

/// A macOS-inspired glassmorphism overlay that displays progressive
/// trust indicators during contract processing.
///
/// Uses frosted glass effect, smooth AnimatedSwitcher transitions,
/// and a liquid progress ring animation.
class TaskStatusOverlay extends StatefulWidget {
  /// Current stage: 'scanning', 'extracting', 'analyzing', 'complete', 'error'
  final String stage;

  /// Human-readable status message
  final String message;

  /// Progress percentage 0–100
  final double progress;

  /// Called when the user taps "View Results" after completion
  final VoidCallback? onComplete;

  /// Called when the user taps "Retry" on error
  final VoidCallback? onRetry;

  /// Called when the user taps "Input Manually" on error
  final VoidCallback? onManualInput;

  const TaskStatusOverlay({
    super.key,
    required this.stage,
    required this.message,
    required this.progress,
    this.onComplete,
    this.onRetry,
    this.onManualInput,
  });

  @override
  State<TaskStatusOverlay> createState() => _TaskStatusOverlayState();
}

class _TaskStatusOverlayState extends State<TaskStatusOverlay>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  IconData _iconForStage(String stage) {
    switch (stage) {
      case 'scanning':
        return Icons.document_scanner_rounded;
      case 'extracting':
        return Icons.auto_awesome;
      case 'analyzing':
        return Icons.analytics_rounded;
      case 'complete':
        return Icons.check_circle_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Color _colorForStage(String stage) {
    switch (stage) {
      case 'scanning':
        return const Color(0xFF4FC3F7);
      case 'extracting':
        return const Color(0xFF7C4DFF);
      case 'analyzing':
        return const Color(0xFFFFB74D);
      case 'complete':
        return const Color(0xFF66BB6A);
      case 'error':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _colorForStage(widget.stage);
    final isComplete = widget.stage == 'complete';
    final isError = widget.stage == 'error';

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Frosted glass background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),

          // Content
          Center(
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: stageColor.withOpacity(0.1),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated progress ring
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: AnimatedBuilder(
                          animation: _ringController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _LiquidRingPainter(
                                progress: widget.progress / 100,
                                color: stageColor,
                                rotation: _ringController.value * 2 * pi,
                                pulse: _pulseAnimation.value,
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (child, animation) =>
                                      ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                  child: Icon(
                                    _iconForStage(widget.stage),
                                    key: ValueKey(widget.stage),
                                    size: 40,
                                    color: stageColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Progress percentage
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          '${widget.progress.toInt()}%',
                          key: ValueKey(widget.progress.toInt()),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: stageColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Status message
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          widget.message,
                          key: ValueKey(widget.message),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Stage indicator dots
                      _buildStageIndicator(stageColor),

                      const SizedBox(height: 24),

                      // Action button (appears on complete or error)
                      if (isComplete)
                        _buildActionButton(
                          'View Results',
                          stageColor,
                          widget.onComplete,
                        ),
                      if (isError) ...[
                        _buildActionButton('Retry', stageColor, widget.onRetry),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          'Input Manually',
                          Colors.white.withOpacity(0.3),
                          widget.onManualInput,
                          outlined: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageIndicator(Color activeColor) {
    final stages = ['scanning', 'extracting', 'analyzing', 'complete'];
    final currentIndex = stages.indexOf(widget.stage);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(stages.length, (i) {
        final isActive = i <= currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? activeColor : Colors.white.withOpacity(0.15),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    VoidCallback? onPressed, {
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.8),
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(label, style: const TextStyle(fontSize: 15)),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

/// Custom painter that draws a liquid-style animated progress ring
class _LiquidRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double rotation;
  final double pulse;

  _LiquidRingPainter({
    required this.progress,
    required this.color,
    required this.rotation,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * pulse;
    final strokeWidth = 4.0;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * pi,
        colors: [color.withOpacity(0.0), color.withOpacity(0.6), color, color],
        stops: const [0.0, 0.3, 0.7, 1.0],
        transform: GradientRotation(rotation),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2 + rotation * 0.1,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow dot at the end of the arc
    if (progress > 0.01) {
      final dotAngle = -pi / 2 + rotation * 0.1 + sweepAngle;
      final dotX = center.dx + (radius - strokeWidth / 2) * cos(dotAngle);
      final dotY = center.dy + (radius - strokeWidth / 2) * sin(dotAngle);

      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dotX, dotY), 6, glowPaint);

      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(dotX, dotY), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidRingPainter old) => true;
}

/// Animated builder helper — wraps AnimatedBuilder for cleaner code
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(animation: animation, builder: builder);
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
