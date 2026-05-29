// ignore_for_file: prefer_initializing_formals
// Private field names (_diary, _isPremium) cannot be used as named parameters
// outside this library, so initializing formals are not applicable here.
import 'dart:io';

import '../../data/repositories/diary_repository.dart';

/// Deletes audio files that are past the retention policy on app startup.
///
/// Retention policy:
///   Free users    → audio files older than 7 days are deleted.
///   Premium users → audio files are kept permanently ("lifetime archive").
///
/// Only the audio file is deleted. The diary entry (JSON + .md) and all other
/// data (text, AI journal, photos) are **never** touched. The [audioFilePath]
/// field in the entry is intentionally left as-is — it serves as a breadcrumb
/// so the UI knows a recording once existed. Playback UIs should call
/// `File(entry.audioFilePath!).existsSync()` before showing a play button.
///
/// This runs synchronously on startup so it finishes before the user opens
/// their history. The typical run time is <100 ms because we only scan entries
/// older than 7 days and skip premium users entirely.
class AudioCleanupService {
  final DiaryRepository _diary;
  final bool _isPremium;

  const AudioCleanupService({
    required DiaryRepository diary,
    required bool isPremium,
  })  : _diary = diary,
        _isPremium = isPremium;

  /// Runs the cleanup. Safe to call multiple times — each call is idempotent
  /// (missing files are silently skipped, already-deleted files are no-ops).
  Future<void> run() async {
    // Premium users keep their audio forever — skip entirely.
    if (_isPremium) return;

    final all = await _diary.listEntries();
    final now = DateTime.now();
    // Cutoff = start of today minus 7 days (midnight boundary, not rolling
    // 168-hour window) so users with a 7-day-old entry always get a full week.
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));

    for (final entry in all) {
      if (entry.date.isAfter(cutoff)) continue; // within retention window
      final path = entry.audioFilePath;
      if (path == null || path.isEmpty) continue; // no audio to delete

      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // File in use or permissions issue — skip silently.
          // Next startup will retry.
        }
      }
    }
  }
}
