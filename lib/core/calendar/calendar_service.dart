import '../../data/models/diary_entry.dart';

/// Read-only bridge to the user's calendar (Google Calendar today,
/// Apple Calendar in a future iteration).
abstract class CalendarService {
  /// Whether this device + this build supports real calendar fetch.
  bool get isSupported;

  /// Has the user already granted calendar read access?
  Future<bool> hasPermissions();

  /// Trigger the platform OAuth / permission dialog.
  Future<bool> requestPermissions();

  /// Returns the events scheduled for [date]. Empty list when the user
  /// has nothing on, or permission is missing.
  Future<List<ScheduleItem>> getEventsFor(DateTime date);
}
