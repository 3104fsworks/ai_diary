import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules weekly (every Sunday 21:00) and monthly (last-day-of-month 21:00)
/// local notifications reminding the user their AI radio is ready to generate.
///
/// Notification IDs:
///   2000 → weekly  (repeating, every Sunday 21:00)
///   2001 → monthly (one-shot, next month-last-day 21:00; rescheduled on tap)
class RadioNotificationService {
  RadioNotificationService._();
  static final RadioNotificationService instance =
      RadioNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _weeklyId = 2000;
  static const _monthlyId = 2001;
  static const _channelId = 'ai_radio';
  static const _channelName = 'AIラジオ';
  static const _channelDesc = '毎週・毎月のAIラジオをお知らせします。';

  // ── Init ─────────────────────────────────────────────────────────────

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

  // ── Schedule ──────────────────────────────────────────────────────────

  /// Schedules (or reschedules) weekly + monthly radio notifications.
  /// Safe to call on every app launch.
  Future<void> scheduleAll({bool enabled = true}) async {
    if (!_ready) await init();
    if (!enabled) {
      await cancelAll();
      return;
    }
    await _scheduleWeekly();
    await _scheduleNextMonthly();
  }

  /// Every Sunday at 21:00.
  Future<void> _scheduleWeekly() async {
    final now = tz.TZDateTime.now(tz.local);
    // Find the next Sunday 21:00.
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21);
    // weekday: 1=Mon … 7=Sun  →  days until Sunday
    final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
    next = next.add(Duration(days: daysUntilSunday == 0 && now.hour >= 21
        ? 7
        : daysUntilSunday));

    try {
      await _plugin.zonedSchedule(
        _weeklyId,
        '今週のAIラジオが届きました 📻',
        '今週の記録をもとにラジオを生成できます。タップして開きましょう。',
        next,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint('[RadioNotif] weekly scheduled → $next');
    } catch (e) {
      debugPrint('[RadioNotif] weekly schedule failed: $e');
    }
  }

  /// One-shot on the last day of this (or next) month at 21:00.
  Future<void> _scheduleNextMonthly() async {
    final now = DateTime.now();
    final lastThisMonth = DateTime(now.year, now.month + 1, 0);
    DateTime target;
    if (now.day < lastThisMonth.day ||
        (now.day == lastThisMonth.day && now.hour < 21)) {
      target = DateTime(now.year, now.month, lastThisMonth.day, 21);
    } else {
      // Already past this month's window → schedule next month.
      final lastNext = DateTime(now.year, now.month + 2, 0);
      target = DateTime(now.year, now.month + 1, lastNext.day, 21);
    }

    final tzTarget = tz.TZDateTime.from(target, tz.local);
    try {
      await _plugin.zonedSchedule(
        _monthlyId,
        '今月のAIラジオ 特別号 🎙️',
        '1ヶ月の記録をまとめた特別ラジオを生成できます。',
        tzTarget,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[RadioNotif] monthly scheduled → $tzTarget');
    } catch (e) {
      debugPrint('[RadioNotif] monthly schedule failed: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) await init();
    await _plugin.cancel(_weeklyId);
    await _plugin.cancel(_monthlyId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
}
