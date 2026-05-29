import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules (and cancels) local push notifications for diary time-capsule
/// delivery.
///
/// Call [init] once at app startup (before scheduling anything).
/// Call [schedule] after saving a [DiaryEntry] that has a [capsuleDeliveryDate].
/// Call [cancel] if the user deletes the entry.
class TimeCapsuleService {
  TimeCapsuleService._();
  static final TimeCapsuleService instance = TimeCapsuleService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // ── Android notification channel ──────────────────────────────────────────
  static const _channelId = 'time_capsule';
  static const _channelName = 'タイムカプセル';
  static const _channelDesc = '過去の日記を未来のあなたに届けます。';

  /// Must be called once at app startup (after Flutter engine is ready).
  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // we ask later, in context
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  /// Requests POST_NOTIFICATIONS permission on Android 13+.
  /// Returns true if granted (or on older Android / iOS where not needed here).
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true; // iOS permission is requested separately
  }

  /// Schedules a time-capsule notification for [entryId] at [deliveryDate].
  ///
  /// [title] and [body] should be localised by the caller.
  /// The notification id is derived from [entryId] so it's idempotent.
  Future<void> schedule({
    required String entryId,
    required DateTime deliveryDate,
    required String title,
    required String body,
  }) async {
    if (!_ready) await init();
    if (deliveryDate.isBefore(DateTime.now())) return; // already past

    final id = _stableId(entryId);
    final tzDate = tz.TZDateTime.from(deliveryDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('[TimeCapsule] scheduled id=$id at $deliveryDate');
  }

  /// Cancels a previously scheduled notification for [entryId].
  Future<void> cancel(String entryId) async {
    if (!_ready) await init();
    await _plugin.cancel(_stableId(entryId));
  }

  /// Derives a stable int id from the entry's string id (UUID → hash mod 2^31).
  int _stableId(String entryId) => entryId.hashCode.abs() % 2147483647;
}
