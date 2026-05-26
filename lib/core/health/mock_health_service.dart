import 'health_service.dart';

/// Used on Web and as a fallback when the platform store is unavailable.
/// Returns the same demo numbers the diary screen had hard-coded before,
/// so the UI still has something to render.
class MockHealthService implements HealthService {
  @override
  bool get isSupported => false;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<HealthSnapshot> getTodaySnapshot() async {
    return const HealthSnapshot(steps: 7432, sleepHours: 7.5);
  }
}
