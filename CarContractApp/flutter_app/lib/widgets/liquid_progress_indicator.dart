import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidCircularProgressIndicator extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final Color baseColor;

  const LiquidCircularProgressIndicator({
    Key? key,
    required this.value,
    this.label = '',
    this.baseColor = Colors.blueAccent,
  }) : super(key: key);

  @override
  State<LiquidCircularProgressIndicator> createState() =>
      _LiquidCircularProgressIndicatorState();
}

class _LiquidCircularProgressIndicatorState
    extends State<LiquidCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _LiquidPainter(
            value: widget.value,
            animationValue: _animationController.value,
            baseColor: widget.baseColor,
          ),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(widget.value * 100).toInt()}",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double value;
  final double animationValue;
  final Color baseColor;

  _LiquidPainter({
    required this.value,
    required this.animationValue,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = min(size.width / 2, size.height / 2);
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Draw background circle
    final Paint bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // Clip to circle before drawing waves
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Calculate wave height based on value
    // value = 0.0 -> wave at bottom
    // value = 1.0 -> wave at top
    final double fillHeight = (1.0 - value) * size.height;

    // Draw Waves
    final Paint wavePaint = Paint()
      ..color = baseColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final Paint wavePaint2 = Paint()
      ..color = baseColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    _drawWave(canvas, size, fillHeight, wavePaint, animationValue, 1.0, 15);
    _drawWave(
      canvas,
      size,
      fillHeight,
      wavePaint2,
      animationValue + 0.5,
      1.2,
      10,
    );

    canvas.restore();
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double fillHeight,
    Paint paint,
    double animValue,
    double frequency,
    double amplitude,
  ) {
    final Path path = Path();
    path.moveTo(0, size.height);

    // Create sine wave
    for (double i = 0; i <= size.width; i++) {
      final double x = i;
      final double y =
          fillHeight +
          math.sin(
                (animValue * 2 * math.pi) +
                    (i / size.width * frequency * math.pi * 2),
              ) *
              amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.value != value ||
        oldDelegate.baseColor != baseColor;
  }

  double min(double a, double b) => a < b ? a : b;
}
