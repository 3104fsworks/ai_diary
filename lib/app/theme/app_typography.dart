import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Arial';

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 32,
        height: 1.2,
        letterSpacing: -0.4,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 22,
        height: 1.3,
        letterSpacing: -0.2,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 18,
        height: 1.3,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.4,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.6,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.4,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.3,
        letterSpacing: 0.2,
        color: primary,
      ),
    );
  }
}
