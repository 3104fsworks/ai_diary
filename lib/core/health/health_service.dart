/// A day's snapshot from the platform health store.
/// All fields are nullable — a permission may be granted while data is absent.
class HealthSnapshot {
  final int? steps;
  final double? sleepHours;

  const HealthSnapshot({this.steps, this.sleepHours});

  bool get isEmpty => steps == null && sleepHours == null;
}

/// Read-only bridge to the platform health store
/// (Android Health Connect / iOS HealthKit).
abstract class HealthService {
  /// Whether this device supports a real health store.
  bool get isSupported;

  /// Whether the user has already granted permission.
  Future<bool> hasPermissions();

  /// Show the system permission dialog. Returns true on full grant.
  Future<bool> requestPermissions();

  /// Latest snapshot for the user's "today" (00:00 → now in local time)
  /// + the immediately-preceding sleep session.
  Future<HealthSnapshot> getTodaySnapshot();
}
