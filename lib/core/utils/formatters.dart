import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale-aware date formatting.
/// ja: 2026.05.23 SAT — en: May 23, 2026
String formatDateHeader(DateTime date, Locale locale) {
  final code = locale.languageCode;
  if (code == 'ja') {
    final dow = DateFormat.E('en_US').format(date).toUpperCase();
    final ymd = DateFormat('yyyy.MM.dd').format(date);
    return '$ymd $dow';
  }
  return DateFormat.yMMMMd('en_US').format(date);
}

/// Long date header used at the top of the diary edit screen.
/// ja: "2026年5月25日 Monday" — en: "May 25, 2026 Monday"
String formatDateLong(DateTime date, Locale locale) {
  final code = locale.languageCode;
  final weekday = DateFormat.EEEE('en_US').format(date);
  if (code == 'ja') {
    final ymd = DateFormat('yyyy年M月d日').format(date);
    return '$ymd $weekday';
  }
  final mdy = DateFormat.yMMMMd('en_US').format(date);
  return '$mdy $weekday';
}

/// US/UK uses Fahrenheit, everyone else Celsius.
String formatTemperature(double celsius, Locale locale) {
  final country = locale.countryCode;
  final useFahrenheit = country == 'US' || country == 'LR' || country == 'KY';
  if (useFahrenheit) {
    final f = celsius * 9 / 5 + 32;
    return '${f.toStringAsFixed(0)}°F';
  }
  return '${celsius.toStringAsFixed(0)}°C';
}
