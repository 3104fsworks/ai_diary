import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../data/models/diary_entry.dart';
import '../../data/repositories/timeline_repository.dart';

/// Tracks the user's location while the app is in the foreground and
/// groups nearby readings into "stays". Uses LocationAccuracy.low to keep
/// battery cost minimal (cellular/wifi triangulation, no GPS lock).
///
/// Clustering rule:
///   • If a new reading is within [_radiusMeters] of the current cluster's
///     centroid, it joins the cluster.
///   • When a cluster ends, if it lasted ≥ [_minStayDuration], it is saved
///     as a TimelineStop.
class LocationTimelineService {
  LocationTimelineService({required TimelineRepository repository})
      : _repo = repository;

  final TimelineRepository _repo;

  static const _radiusMeters = 200.0;
  static const _minStayDuration = Duration(minutes: 10);
  static const _pollInterval = Duration(minutes: 5);

  StreamSubscription<Position>? _sub;
  _Cluster? _current;
  bool _running = false;

  bool get isRunning => _running;

  /// Returns true if started successfully; false if permission was denied
  /// or the platform doesn't have location services available.
  Future<bool> start() async {
    if (_running) return true;

    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 100,
        timeLimit: _pollInterval,
      ),
    ).listen(
      _handlePosition,
      onError: (_) {/* swallow — service continues to run */},
    );
    _running = true;
    return true;
  }

  Future<void> stop() async {
    await _flushCurrent();
    await _sub?.cancel();
    _sub = null;
    _running = false;
  }

  Future<void> _handlePosition(Position p) async {
    final now = DateTime.now();
    final cluster = _current;

    if (cluster == null) {
      _current = _Cluster(start: now, lat: p.latitude, lng: p.longitude);
      return;
    }

    final dist = Geolocator.distanceBetween(
      cluster.lat,
      cluster.lng,
      p.latitude,
      p.longitude,
    );

    if (dist <= _radiusMeters) {
      cluster.extend(now, p.latitude, p.longitude);
      return;
    }

    // Different place — finalize previous, start new.
    await _flushCurrent();
    _current = _Cluster(start: now, lat: p.latitude, lng: p.longitude);
  }

  Future<void> _flushCurrent() async {
    final c = _current;
    _current = null;
    if (c == null) return;

    final duration = c.end.difference(c.start);
    if (duration < _minStayDuration) return;

    final place = await _placeName(c.lat, c.lng);
    final stay = TimelineStop(
      place: place,
      time: '${_hhmm(c.start)} – ${_hhmm(c.end)}',
    );

    await _repo.appendStay(c.start, stay);
  }

  /// Reverse-geocoding (lat/lng → place name) is temporarily disabled —
  /// the `geocoding` plugin's Android side is locked to compileSdk 33 and
  /// breaks the build. Until upstream updates, we show coordinates.
  Future<String> _placeName(double lat, double lng) async {
    return '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}';
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> dispose() async => stop();
}

class _Cluster {
  _Cluster({required this.start, required this.lat, required this.lng})
      : end = start;

  final DateTime start;
  DateTime end;
  double lat;
  double lng;

  void extend(DateTime t, double nLat, double nLng) {
    // Running average centroid — keeps cluster anchored to the actual stay.
    lat = (lat + nLat) / 2;
    lng = (lng + nLng) / 2;
    end = t;
  }
}
