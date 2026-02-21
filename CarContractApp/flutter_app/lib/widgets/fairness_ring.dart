import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fairness Score Ring Widget
class FairnessRing extends StatelessWidget {
  final int score;
  final double size;

  const FairnessRing({super.key, required this.score, this.size = 120});

  Color get scoreColor {
    if (score >= 80) return AppTheme.accentGreen;
    if (score >= 60) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: AppTheme.glassBg,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Fairness',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: size * 0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
