import '../../data/models/diary_entry.dart';
import 'calendar_service.dart';

/// Returns canned demo events. Used while Google OAuth isn't configured.
/// Drop in `RealGoogleCalendarService` once an OAuth client is set up.
class MockCalendarService implements CalendarService {
  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<ScheduleItem>> getEventsFor(DateTime date) async {
    return const [
      ScheduleItem(title: '渋谷で打ち合わせ', time: '14:00'),
      ScheduleItem(title: 'カフェで読書', time: '17:30'),
    ];
  }
}
