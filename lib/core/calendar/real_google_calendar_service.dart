import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';

import '../../data/models/diary_entry.dart';
import '../auth/auth_service.dart';
import 'calendar_service.dart';

/// Live implementation backed by Google Calendar v3. Reads events from the
/// user's primary calendar for the requested day. Read-only.
class RealGoogleCalendarService implements CalendarService {
  RealGoogleCalendarService({required this.auth});

  final AuthService auth;

  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermissions() async {
    // Cheap probe: try to instantiate a client. If the user hasn't granted
    // the calendar scope yet, the OAuth screen will surface that on the
    // first real request — we don't pre-check here to avoid an extra round.
    return auth.isGoogleUser;
  }

  @override
  Future<bool> requestPermissions() {
    return auth.requestGoogleScopes(const [GoogleApiScopes.calendarReadonly]);
  }

  @override
  Future<List<ScheduleItem>> getEventsFor(DateTime date) async {
    final client = await auth.authenticatedGoogleClient();
    if (client == null) return const [];
    try {
      final api = gcal.CalendarApi(client);
      final start = DateTime(date.year, date.month, date.day).toUtc();
      final end = start.add(const Duration(days: 1));
      final events = await api.events.list(
        'primary',
        timeMin: start,
        timeMax: end,
        singleEvents: true,
        orderBy: 'startTime',
      );
      final items = events.items ?? const <gcal.Event>[];
      return items
          .where((e) => (e.summary ?? '').isNotEmpty)
          .map((e) => ScheduleItem(
                title: e.summary!,
                time: _formatTime(e.start),
              ))
          .toList();
    } catch (_) {
      return const [];
    } finally {
      client.close();
    }
  }

  /// Formats `EventDateTime` as "HH:mm". All-day events return null.
  String? _formatTime(gcal.EventDateTime? edt) {
    final dt = edt?.dateTime?.toLocal();
    if (dt == null) return null; // all-day or missing → no time prefix
    return DateFormat('HH:mm').format(dt);
  }
}
