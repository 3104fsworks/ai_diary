import '../models/diary_entry.dart';

/// Provides week-scoped queries on diary data for the weekly AI radio
/// and the voice time-capsule feature.
///
/// Implementations should layer on top of [DiaryRepository] so storage
/// details stay encapsulated. The weekly radio UI only asks this repository —
/// it never calls DiaryRepository directly.
abstract class WeeklySummaryRepository {
  /// All entries within the last 7 calendar days (today inclusive).
  ///
  /// The weekly AI radio calls this every Sunday to build its episode.
  /// The list is sorted newest-first and may contain at most 7 items.
  Future<List<DiaryEntry>> getLastSevenDays();

  /// All entries for the calendar week that starts on [weekStart].
  ///
  /// [weekStart] is typically a Monday. The range is [weekStart, weekStart+7).
  /// Used to retrieve archived radio episodes for premium playback.
  Future<List<DiaryEntry>> getWeekEntries(DateTime weekStart);

  /// Average [VoiceMetadata.emotionTemperature] for [entries].
  ///
  /// Returns null when none of the entries have voice metadata.
  /// The weekly radio uses this to auto-select the ambient BGM mood:
  ///   ≥ 0.6 → bright ambient    0.3–0.6 → neutral   < 0.3 → lo-fi / quiet
  double? averageEmotionTemperature(List<DiaryEntry> entries) {
    final temps = entries
        .map((e) => e.voiceMetadata?.emotionTemperature)
        .whereType<double>()
        .toList();
    if (temps.isEmpty) return null;
    return temps.reduce((a, b) => a + b) / temps.length;
  }

  /// Returns the BGM mood string for the weekly radio based on [temperature].
  ///
  /// Callers use this to look up a local asset or a streaming URL.
  static String bgmMood(double temperature) {
    if (temperature >= 0.6) return 'bright_ambient';
    if (temperature >= 0.3) return 'neutral';
    return 'lofi_quiet'; // tired / calm weeks
  }
}
