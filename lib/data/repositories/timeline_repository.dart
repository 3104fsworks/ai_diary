import '../models/diary_entry.dart';

/// Persists the user's daily location-timeline ("stays").
/// Implementation: local file per day. Cloud sync is layered on later.
abstract class TimelineRepository {
  /// Returns the list of stays detected so far for [date].
  Future<List<TimelineStop>> getStays(DateTime date);

  /// Appends a single stay to [date]'s timeline.
  Future<void> appendStay(DateTime date, TimelineStop stay);

  /// Replaces the entire timeline for [date] (used when re-clustering).
  Future<void> replace(DateTime date, List<TimelineStop> stays);
}
