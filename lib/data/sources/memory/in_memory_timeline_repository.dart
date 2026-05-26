import '../../models/diary_entry.dart';
import '../../repositories/timeline_repository.dart';

/// Web / preview fallback. Lives only for the current session.
class InMemoryTimelineRepository implements TimelineRepository {
  final Map<String, List<TimelineStop>> _byDate = {};

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<TimelineStop>> getStays(DateTime date) async {
    return List.unmodifiable(_byDate[_key(date)] ?? const []);
  }

  @override
  Future<void> appendStay(DateTime date, TimelineStop stay) async {
    final k = _key(date);
    _byDate[k] = [...(_byDate[k] ?? const []), stay];
  }

  @override
  Future<void> replace(DateTime date, List<TimelineStop> stays) async {
    _byDate[_key(date)] = List.of(stays);
  }
}
