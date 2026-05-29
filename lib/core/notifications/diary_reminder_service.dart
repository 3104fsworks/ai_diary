import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules (and cancels) a daily diary-reminder notification.
///
/// Default: every day at 21:00 local time.
/// Notification ID 1000 — does not overlap with TimeCapsule (entry-hash)
/// or Radio (2000 / 2001).
///
/// NOTE: timezone data must be initialised by [TimeCapsuleService.init]
/// before calling [scheduleDaily].  In practice [main] always inits
/// TimeCapsuleService first, so this is guaranteed.
class DiaryReminderService {
  DiaryReminderService._();
  static final DiaryReminderService instance = DiaryReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _notifId = 1000;
  static const _channelId = 'diary_reminder';
  static const _channelName = '日記リマインダー';
  static const _channelDesc = '毎日決まった時間に日記を書くよう声をかけます。';

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  // ── Permission ────────────────────────────────────────────────────────────

  /// Requests POST_NOTIFICATIONS permission on Android 13+.
  /// Returns true if granted (or on platforms where it's not required here).
  Future<bool> requestPermission() async {
    if (!_ready) await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    // iOS: permission was handled at app launch via DarwinInitializationSettings
    // or system will prompt when the first notification fires.
    return true;
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Schedules (or cancels) a daily diary-reminder at [hour]:00 local time.
  ///
  /// Safe to call on every app launch — rescheduling an existing notification
  /// with the same ID replaces it cleanly.
  Future<void> scheduleDaily({
    int hour = 21,
    bool enabled = true,
  }) async {
    if (!_ready) await init();
    if (!enabled) {
      await cancel();
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    // Find the next occurrence of today's `hour:00`.
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!next.isAfter(now)) {
      // Already past today's slot → schedule for tomorrow.
      next = next.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        _notifId,
        '今日もどんな1日でしたか？ 📓',
        '今日の出来事を、声や文章で残しましょう。',
        next,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: const BigTextStyleInformation(
              '今日の出来事を、声や文章で残しましょう。',
            ),
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
        // Repeat every day at the same hour.
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[DiaryReminder] daily scheduled → $next (hour=$hour)');
    } catch (e) {
      debugPrint('[DiaryReminder] schedule failed: $e');
    }
  }

  /// Cancels the diary reminder.
  Future<void> cancel() async {
    if (!_ready) await init();
    await _plugin.cancel(_notifId);
    debugPrint('[DiaryReminder] cancelled');
  }
}
