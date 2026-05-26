import 'package:flutter/material.dart';

/// Color tokens for AI Diary.
/// Inspired by a stoic, intellectual minimalism — no playfulness.
class AppColors {
  AppColors._();

  // Light
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightDivider = Color(0xFFE0E0E0);
  /// Filled background for secondary actions in light mode —
  /// a touch lighter than typical hover states.
  static const Color lightSecondaryFill = Color(0xFFF1F1EE);

  // Dark
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA8A8A8);
  static const Color darkDivider = Color(0xFF333333);
  /// Filled background for secondary actions in dark mode.
  static const Color darkSecondaryFill = Color(0xFF222226);

  // Accent — refined deep navy (default)
  static const Color accentNavy = Color(0xFF1F2A44);
  static const Color accentOrange = Color(0xFFE07A3C);
  static const Color accentEmerald = Color(0xFF1F4D3A);
  static const Color accentBlack = Color(0xFF1A1A1A);
  /// "White" accent — a warm ivory that still has presence on white bg.
  static const Color accentIvory = Color(0xFFE6DFC8);
  static const Color accentSoftPink = Color(0xFFD98AA8);
  static const Color accentSkyBlue = Color(0xFF6FA8D9);
  static const Color accentLilac = Color(0xFFA88AD9);

  static const List<Color> accentChoices = [
    accentNavy,
    accentOrange,
    accentEmerald,
    accentBlack,
    accentIvory,
    accentSoftPink,
    accentSkyBlue,
    accentLilac,
  ];
}
