import 'package:health/health.dart';

import 'health_service.dart';

/// Live implementation backed by the `health` package
/// (Android: Health Connect, iOS: HealthKit).
class RealHealthService implements HealthService {
  RealHealthService() : _health = Health() {
    _health.configure();
  }

  final Health _health;

  static const _types = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
  ];

  static const _permissions = <HealthDataAccess>[
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermissions() async {
    final granted = await _health.hasPermissions(_types, permissions: _permissions);
    if (granted == true) return true;
    // Same fallback as request: Health Connect can return null here even
    // when permission is actually in place.
    return await _canReadAnyData();
  }

  @override
  Future<bool> requestPermissions() async {
    // Health Connect on Android also wants ACTIVITY_RECOGNITION at runtime.
    try {
      await Health().installHealthConnect();
    } catch (_) {/* not critical — package may no-op on iOS */}

    // 1) Try the official request flow. This OFTEN returns false even on a
    //    successful grant (known issue with health 13.x + Health Connect).
    final requested = await _health.requestAuthorization(
      _types,
      permissions: _permissions,
    );
    if (requested) return true;

    // 2) Re-query the authoritative state. Health Connect sometimes reports
    //    null here too, so this is only one of three signals.
    final has = await _health.hasPermissions(_types, permissions: _permissions);
    if (has == true) return true;

    // 3) Final, most reliable signal: try to actually read data. If the
    //    platform lets us through, the permission is effectively granted.
    return await _canReadAnyData();
  }

  /// Probes whether the platform will actually serve health data to us.
  /// Used as a last resort when the official permission APIs lie.
  Future<bool> _canReadAnyData() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _health.getTotalStepsInInterval(startOfDay, now);
      if (steps != null) return true;
    } catch (_) {/* fall through */}
    try {
      await _health.getHealthDataFromTypes(
        types: const [HealthDataType.SLEEP_ASLEEP],
        startTime: startOfDay.subtract(const Duration(hours: 12)),
        endTime: now,
      );
      // Even an empty list means the read SUCCEEDED — permission is OK.
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<HealthSnapshot> getTodaySnapshot() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    int? steps;
    try {
      steps = await _health.getTotalStepsInInterval(startOfDay, now);
    } catch (_) {
      steps = null;
    }

    // Sleep window: last night (yesterday 18:00) → today noon, take longest session.
    double? sleepHours;
    try {
      final sleepStart = startOfDay
          .subtract(const Duration(hours: 6)); // yesterday 18:00
      final sleepEnd = startOfDay.add(const Duration(hours: 12)); // today noon
      final data = await _health.getHealthDataFromTypes(
        types: const [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_IN_BED,
        ],
        startTime: sleepStart,
        endTime: sleepEnd,
      );
      Duration total = Duration.zero;
      for (final point in data) {
        // Each point has a from/to range.
        total += point.dateTo.difference(point.dateFrom);
      }
      if (total.inMinutes > 0) {
        sleepHours = total.inMinutes / 60.0;
      }
    } catch (_) {
      sleepHours = null;
    }

    return HealthSnapshot(steps: steps, sleepHours: sleepHours);
  }
}
