import 'package:flutter/material.dart';

/// Same design system as PDDS: emerald on near-black.
/// Change [accent] here and the whole app follows.
class AppTheme {
  static const Color background = Color(0xFF0A0F0D);
  static const Color surface = Color(0xFF121A17);
  static const Color surfaceHigh = Color(0xFF18231F);
  static const Color border = Color(0xFF223029);
  static const Color accent = Color(0xFF34D399);
  static const Color accentDim = Color(0xFF1F8F68);
  static const Color textPrimary = Color(0xFFE7F0EB);
  static const Color textSecondary = Color(0xFF8FA79B);
  static const Color warning = Color(0xFFF5B14C);
  static const Color danger = Color(0xFFE2685E);

  /// Confidence colour ramp: low = muted, high = alarming.
  static Color forConfidence(double p) {
    if (p >= 0.65) return danger;
    if (p >= 0.40) return warning;
    return accent;
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: accent,
      secondary: accentDim,
      surface: surface,
      error: danger,
      onPrimary: background,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withAlpha(41),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            letterSpacing: 0.3,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? accent : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? accent : textSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.2),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12.5, height: 1.45, color: textSecondary),
        labelSmall: TextStyle(
            fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: textSecondary),
      ),
    );
  }

  static BoxDecoration get card => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      );
}
