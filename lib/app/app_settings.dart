import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/ai_personality.dart';
import '../data/models/goal_item.dart';
import 'theme/app_colors.dart';

/// App-wide UI settings — persisted via SharedPreferences.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  static const _kThemeMode = 'theme_mode';
  static const _kAccent = 'accent_color';
  static const _kPersonality = 'ai_personality';
  static const _kOnboardingDone = 'onboarding_done';
  static const _kGeminiApiKey = 'gemini_api_key';
  static const _kLocationEnabled = 'location_enabled';
  static const _kHealthEnabled = 'health_enabled';
  static const _kCalendarEnabled = 'calendar_enabled';
  static const _kTasksEnabled = 'tasks_enabled';
  static const _kCurrentUserId = 'current_user_id';
  static const _kIsPremium = 'is_premium';
  static const _kLastFreeGenerationDate = 'last_free_generation_date';
  static const _kLocale = 'locale_override';
  static const _kCustomGoals = 'custom_goals';
  static const _kVoiceTooltipSeen = 'voice_tooltip_seen';
  static const _kFontScale = 'font_scale';
  static const _kLifetimeFree = 'lifetime_free';
  static const _kPremiumUntil = 'premium_until_iso';
  static const _kRedeemedCode = 'redeemed_code';

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(prefs);
  }

  ThemeMode get themeMode {
    final v = _prefs.getString(_kThemeMode);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Color get accent {
    final v = _prefs.getInt(_kAccent);
    if (v == null) return AppColors.accentBlack;
    // Reconstruct from stored int — match against known palette
    for (final c in AppColors.accentChoices) {
      if (_colorToInt(c) == v) return c;
    }
    return AppColors.accentBlack;
  }

  /// Stored personality preference (Premium feature).
  AiPersonality get personality =>
      AiPersonality.fromStorage(_prefs.getString(_kPersonality));

  /// Personality that will actually be sent to the AI.
  /// Free users get [AiPersonality.standard] regardless of preference.
  AiPersonality get effectivePersonality {
    if (isPremium || geminiApiKey.isNotEmpty) return personality;
    return AiPersonality.standard;
  }

  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  bool get locationEnabled => _prefs.getBool(_kLocationEnabled) ?? false;

  bool get healthEnabled => _prefs.getBool(_kHealthEnabled) ?? false;

  bool get calendarEnabled => _prefs.getBool(_kCalendarEnabled) ?? false;

  bool get tasksEnabled => _prefs.getBool(_kTasksEnabled) ?? false;

  /// Anonymous-ish identifier for the signed-in user (Firebase UID once
  /// the real auth is wired up). Empty when signed out.
  String get currentUserId => _prefs.getString(_kCurrentUserId) ?? '';

  bool get isSignedIn => currentUserId.isNotEmpty;

  bool get hasSeenVoiceTooltip => _prefs.getBool(_kVoiceTooltipSeen) ?? false;

  /// Accessibility: text & UI scale.
  /// Stored as the literal multiplier (0.9, 1.0, 1.15, 1.3).
  FontScale get fontScale {
    final v = _prefs.getDouble(_kFontScale);
    if (v == null) return FontScale.medium;
    return FontScale.values.firstWhere(
      (s) => (s.scale - v).abs() < 0.001,
      orElse: () => FontScale.medium,
    );
  }

  /// Locale picked explicitly by the user (overrides OS).
  /// null when the user hasn't picked yet → follow OS locale.
  Locale? get localeOverride {
    final code = _prefs.getString(_kLocale);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  bool get hasPickedLanguage => localeOverride != null;

  /// User-defined goals (Premium can have up to 6, Free up to 3).
  List<GoalItem> get customGoals {
    final raw = _prefs.getString(_kCustomGoals);
    if (raw == null || raw.isEmpty) return _defaultGoals;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => GoalItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _defaultGoals;
    }
  }

  // Start empty — users add their own goals from Settings → Goals.
  // Avoids "default chips the user never agreed to" feeling on first open.
  static const List<GoalItem> _defaultGoals = [];

  /// Manual / subscription-derived premium flag (RevenueCat target).
  bool get _manualPremium => _prefs.getBool(_kIsPremium) ?? false;

  /// Granted by a permanent free invite code (e.g. influencer giveaway).
  bool get lifetimeFree => _prefs.getBool(_kLifetimeFree) ?? false;

  /// Time-limited premium granted by a 1-month invite code, etc.
  DateTime? get premiumUntil {
    final raw = _prefs.getString(_kPremiumUntil);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Code the user has already redeemed (so they can't redeem twice).
  String? get redeemedCode => _prefs.getString(_kRedeemedCode);

  /// Effective premium status, combining all sources.
  bool get isPremium {
    if (_manualPremium) return true;
    if (lifetimeFree) return true;
    final until = premiumUntil;
    if (until != null && until.isAfter(DateTime.now())) return true;
    return false;
  }

  /// Returns true if the free user has already used today's single AI
  /// generation. Premium users / BYOK users bypass this check.
  bool get freeGenerationUsedToday {
    final raw = _prefs.getString(_kLastFreeGenerationDate);
    if (raw == null) return false;
    final today = _ymd(DateTime.now());
    return raw == today;
  }

  Future<void> markFreeGenerationUsed() async {
    await _prefs.setString(_kLastFreeGenerationDate, _ymd(DateTime.now()));
    notifyListeners();
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Gemini API key — empty string when not configured.
  String get geminiApiKey => _prefs.getString(_kGeminiApiKey) ?? '';

  /// Masks all but the last 4 chars: "AIza••••••••aB3z".
  String get geminiApiKeyMasked {
    final k = geminiApiKey;
    if (k.isEmpty) return '';
    if (k.length <= 8) return '•' * k.length;
    return '${k.substring(0, 4)}${'•' * (k.length - 8)}${k.substring(k.length - 4)}';
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_kThemeMode, v);
    notifyListeners();
  }

  Future<void> setAccent(Color color) async {
    await _prefs.setInt(_kAccent, _colorToInt(color));
    notifyListeners();
  }

  Future<void> setPersonality(AiPersonality p) async {
    await _prefs.setString(_kPersonality, p.storageKey);
    notifyListeners();
  }

  Future<void> setOnboardingDone(bool done) async {
    await _prefs.setBool(_kOnboardingDone, done);
    notifyListeners();
  }

  Future<void> setLocationEnabled(bool enabled) async {
    await _prefs.setBool(_kLocationEnabled, enabled);
    notifyListeners();
  }

  Future<void> setHealthEnabled(bool enabled) async {
    await _prefs.setBool(_kHealthEnabled, enabled);
    notifyListeners();
  }

  Future<void> setCalendarEnabled(bool enabled) async {
    await _prefs.setBool(_kCalendarEnabled, enabled);
    notifyListeners();
  }

  Future<void> setTasksEnabled(bool enabled) async {
    await _prefs.setBool(_kTasksEnabled, enabled);
    notifyListeners();
  }

  Future<void> setCurrentUserId(String uid) async {
    if (uid.isEmpty) {
      await _prefs.remove(_kCurrentUserId);
    } else {
      await _prefs.setString(_kCurrentUserId, uid);
    }
    notifyListeners();
  }

  Future<void> markVoiceTooltipSeen() async {
    await _prefs.setBool(_kVoiceTooltipSeen, true);
    notifyListeners();
  }

  Future<void> setFontScale(FontScale scale) async {
    await _prefs.setDouble(_kFontScale, scale.scale);
    notifyListeners();
  }

  Future<void> setPremium(bool premium) async {
    await _prefs.setBool(_kIsPremium, premium);
    notifyListeners();
  }

  Future<void> grantLifetimeFree({required String redeemedCode}) async {
    await _prefs.setBool(_kLifetimeFree, true);
    await _prefs.setString(_kRedeemedCode, redeemedCode);
    notifyListeners();
  }

  /// Extends premium access by [duration] from now (or from existing
  /// premiumUntil if it's already in the future).
  Future<void> grantTimedPremium({
    required Duration duration,
    required String redeemedCode,
  }) async {
    final base = premiumUntil != null && premiumUntil!.isAfter(DateTime.now())
        ? premiumUntil!
        : DateTime.now();
    final until = base.add(duration);
    await _prefs.setString(_kPremiumUntil, until.toIso8601String());
    await _prefs.setString(_kRedeemedCode, redeemedCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_kLocale);
    } else {
      await _prefs.setString(_kLocale, locale.languageCode);
    }
    notifyListeners();
  }

  Future<void> setCustomGoals(List<GoalItem> goals) async {
    final encoded = jsonEncode(goals.map((g) => g.toJson()).toList());
    await _prefs.setString(_kCustomGoals, encoded);
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_kGeminiApiKey);
    } else {
      await _prefs.setString(_kGeminiApiKey, trimmed);
    }
    notifyListeners();
  }

  static int _colorToInt(Color c) {
    final a = (c.a * 255).round() & 0xff;
    final r = (c.r * 255).round() & 0xff;
    final g = (c.g * 255).round() & 0xff;
    final b = (c.b * 255).round() & 0xff;
    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}

/// Inherited access — minimal alternative to Provider.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope missing in widget tree');
    return scope!.notifier!;
  }
}

/// Accessibility text/UI scale. Default is [medium] (1.0×).
enum FontScale {
  small(0.9, '小'),
  medium(1.0, '標準'),
  large(1.15, '大'),
  extraLarge(1.3, '特大');

  final double scale;
  final String labelJa;
  const FontScale(this.scale, this.labelJa);
}
