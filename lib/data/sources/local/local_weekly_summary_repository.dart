import '../../models/diary_entry.dart';
import '../../repositories/diary_repository.dart';
import '../../repositories/weekly_summary_repository.dart';

/// Local implementation of [WeeklySummaryRepository] that wraps
/// [DiaryRepository]. No additional storage is needed — it simply
/// applies date-range filters on top of the existing diary list.
///
/// Uses `extends` (not `implements`) to inherit the concrete helper methods
/// [averageEmotionTemperature] and [bgmMood] defined in the abstract class.
class LocalWeeklySummaryRepository extends WeeklySummaryRepository {
  final DiaryRepository _diary;

  LocalWeeklySummaryRepository(this._diary);

  @override
  Future<List<DiaryEntry>> getLastSevenDays() async {
    final all = await _diary.listEntries();
    final now = DateTime.now();
    // Include today through exactly 7 days ago (midnight boundary).
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));
    return all
        .where((e) => !e.date.isBefore(cutoff))
        .toList(); // already sorted newest-first by LocalDiaryRepository
  }

  @override
  Future<List<DiaryEntry>> getWeekEntries(DateTime weekStart) async {
    final all = await _diary.listEntries();
    // Normalise to midnight so time-of-day differences don't shift entries.
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    return all
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .toList();
  }
}
