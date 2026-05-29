import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/radio_episode.dart';

/// Lightweight key-value store for [RadioEpisode] objects.
///
/// Metadata (script, dates, type) → SharedPreferences JSON list.
/// Audio MP3 files → app documents directory (persistent across app launches).
///
/// Keeps the last [maxEpisodes] episodes; older ones are pruned on save.
class RadioEpisodeStore {
  RadioEpisodeStore._();
  static final RadioEpisodeStore instance = RadioEpisodeStore._();

  static const _kKey = 'radio_episodes_v1';
  static const maxEpisodes = 12; // ~3 months of weekly + 3 monthly

  // ── Audio directory ───────────────────────────────────────────────────

  Future<Directory> get _audioDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/radio_audio');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Destination path for a new audio file for [episodeId].
  Future<String> audioPath(String episodeId) async {
    final dir = await _audioDir;
    // sanitise ID for filesystem
    final safe = episodeId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return '${dir.path}/$safe.mp3';
  }

  // ── CRUD ──────────────────────────────────────────────────────────────

  Future<List<RadioEpisode>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    return RadioEpisode.listFromJsonString(raw);
  }

  Future<void> save(RadioEpisode episode) async {
    final all = await loadAll();
    // Replace existing episode with same id, or prepend new one.
    final idx = all.indexWhere((e) => e.id == episode.id);
    if (idx >= 0) {
      all[idx] = episode;
    } else {
      all.insert(0, episode);
    }
    // Sort newest-first, then prune.
    all.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    final pruned = all.take(maxEpisodes).toList();
    // Delete audio files for pruned episodes.
    for (final old in all.skip(maxEpisodes)) {
      _deleteAudio(old.audioFilePath);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, RadioEpisode.listToJsonString(pruned));
  }

  Future<void> delete(String episodeId) async {
    final all = await loadAll();
    final removed = all.where((e) => e.id == episodeId).toList();
    for (final e in removed) {
      _deleteAudio(e.audioFilePath);
    }
    all.removeWhere((e) => e.id == episodeId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, RadioEpisode.listToJsonString(all));
  }

  void _deleteAudio(String path) {
    if (path.isEmpty) return;
    File(path).delete().catchError((_) => File(''));
  }

  // ── Generation-date helpers ───────────────────────────────────────────

  /// Returns the id for this week's Sunday episode.
  static String weeklyId(DateTime sunday) {
    final s = sunday.toIso8601String().substring(0, 10);
    return 'weekly_$s';
  }

  /// Returns the id for this month's last-day episode.
  static String monthlyId(DateTime lastDay) {
    final s = lastDay.toIso8601String().substring(0, 10);
    return 'monthly_$s';
  }

  /// The most recent Sunday on or before [date].
  static DateTime lastSunday(DateTime date) {
    // weekday: 1=Mon … 7=Sun
    final daysBack = date.weekday % 7; // Sun=0, Mon=1…Sat=6
    return DateTime(date.year, date.month, date.day - daysBack);
  }

  /// The last day of [date]'s month.
  static DateTime lastDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  /// Whether today (or a past due date) is a weekly generation day.
  static bool isWeeklyDue(DateTime now) => now.weekday == DateTime.sunday;

  /// Whether today is a monthly generation day.
  static bool isMonthlyDue(DateTime now) {
    final last = lastDayOfMonth(now);
    return now.day == last.day;
  }
}
