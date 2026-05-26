import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static const double radius = 12;
  static const double radiusSmall = 8;

  static ThemeData light({Color accent = AppColors.accentNavy}) {
    final onAccent = _readableOn(accent);
    final scheme = ColorScheme.light(
      primary: accent,
      onPrimary: onAccent,
      secondary: accent,
      onSecondary: onAccent,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      error: const Color(0xFFB00020),
      onError: Colors.white,
    );

    final text = AppTypography.textTheme(
      AppColors.lightTextPrimary,
      AppColors.lightTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      dividerColor: AppColors.lightDivider,
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 24,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextPrimary,
        size: 22,
        weight: 300,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(
          color: AppColors.lightTextPrimary,
          size: 22,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          elevation: 0,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          backgroundColor: AppColors.lightSecondaryFill,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        hintStyle: text.bodyLarge?.copyWith(color: AppColors.lightTextSecondary),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.lightDivider),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark({Color accent = AppColors.accentNavy}) {
    // For very dark accents, lift them in dark mode so they stay legible.
    Color darkAccent = accent;
    if (accent == AppColors.accentNavy) {
      darkAccent = const Color(0xFF4D5E85);
    } else if (accent == AppColors.accentBlack) {
      darkAccent = const Color(0xFFE0E0E0);
    } else if (accent == AppColors.accentEmerald) {
      darkAccent = const Color(0xFF4D8A6B);
    }

    final onDarkAccent = _readableOn(darkAccent);
    final scheme = ColorScheme.dark(
      primary: darkAccent,
      onPrimary: onDarkAccent,
      secondary: darkAccent,
      onSecondary: onDarkAccent,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      error: const Color(0xFFCF6679),
      onError: Colors.black,
    );

    final text = AppTypography.textTheme(
      AppColors.darkTextPrimary,
      AppColors.darkTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      dividerColor: AppColors.darkDivider,
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 24,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextPrimary,
        size: 22,
        weight: 300,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 22,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: onDarkAccent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          elevation: 0,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          backgroundColor: AppColors.darkSecondaryFill,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        hintStyle: text.bodyLarge?.copyWith(color: AppColors.darkTextSecondary),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.darkDivider),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Picks black or white text depending on which gives better contrast.
  /// W3C relative luminance formula.
  static Color _readableOn(Color bg) {
    double channel(double c) {
      final v = c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055);
      return v <= 0.03928 ? v : v;
    }

    // Color.r/g/b are 0..1 doubles in Flutter 3.44+
    final r = channel(bg.r);
    final g = channel(bg.g);
    final b = channel(bg.b);
    final luminance =
        0.2126 * _gamma(r) + 0.7152 * _gamma(g) + 0.0722 * _gamma(b);
    return luminance > 0.5 ? const Color(0xFF1A1A1A) : Colors.white;
  }

  static double _gamma(double c) {
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }
}
