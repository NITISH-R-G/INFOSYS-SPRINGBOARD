import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple Dark Glass Theme for ContractAI
class AppTheme {
  // Core colors
  static const Color background = Color(0xFF1C1C1E);
  static const Color surface = Color(0xFF2C2C2E);
  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);
  static const Color textMuted = Color(0x66FFFFFF);

  // Accent colors
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentRed = Color(0xFFFF3B30);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentBlue = Color(0xFF007AFF);

  // ─────────────────────────────────────────────────────────────
  // LIQUID GLASS CONFIGURATION
  // ─────────────────────────────────────────────────────────────

  /// Glass blur strengths
  static const double glassBlurLight = 10.0;
  static const double glassBlurStandard = 20.0;
  static const double glassBlurHeavy = 40.0;

  /// Glass opacities
  static const double glassOpacity = 0.15;
  static const double glassBorderOpacity = 0.2;
  static const double glassGlowOpacity = 0.3;

  /// Glass glow colors
  static const Color glowGreen = Color(0xFF30D158);
  static const Color glowBlue = Color(0xFF0A84FF);
  static const Color glowPurple = Color(0xFFBF5AF2);

  /// Shadow configuration
  static const double shadowOpacity = 0.25;
  static const double shadowBlur = 30.0;
  static const Offset shadowOffset = Offset(0, 10);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34C759), Color(0xFF30D158)],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentGreen,
      colorScheme: const ColorScheme.dark(
        primary: accentGreen,
        secondary: accentBlue,
        surface: surface,
        error: accentRed,
      ),
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGreen, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
