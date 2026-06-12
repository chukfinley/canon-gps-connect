import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'log_db.dart';
import 'nmea.dart';

/// On-demand GPS logger. Runs inside the foreground-service isolate. To save
/// battery it only polls location while a camera actually wants it; the update
/// interval is user-configurable.
class GpsService {
  GpsService(this._db);
  final GpsLogDb _db;

  StreamSubscription<Position>? _sub;
  NmeaFix? _last;
  int? _termStart;
  int _intervalSeconds = 10;

  final _fixController = StreamController<NmeaFix>.broadcast();
  Stream<NmeaFix> get fixes => _fixController.stream;
  NmeaFix? get lastFix => _last;
  bool get running => _sub != null;
  int get intervalSeconds => _intervalSeconds;

  AndroidSettings _settings(int seconds) => AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: Duration(seconds: seconds),
        // Don't gate on distance — a stationary camera still wants periodic fixes.
        distanceFilter: 0,
      );

  /// Start polling at [seconds] interval. Safe to call repeatedly.
  Future<void> start({int? seconds}) async {
    if (seconds != null) _intervalSeconds = seconds;
    if (_sub != null) return;
    _termStart = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.beginTerm(_termStart!);
    _sub = Geolocator.getPositionStream(locationSettings: _settings(_intervalSeconds))
        .listen(_onPosition, onError: (_) {});
  }

  /// Change the interval; restarts the stream if currently running.
  Future<void> setInterval(int seconds) async {
    _intervalSeconds = seconds;
    if (_sub != null) {
      await _sub!.cancel();
      _sub = Geolocator.getPositionStream(
              locationSettings: _settings(_intervalSeconds))
          .listen(_onPosition, onError: (_) {});
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    if (_termStart != null) {
      await _db.endTerm(
          _termStart!, DateTime.now().toUtc().millisecondsSinceEpoch);
      _termStart = null;
    }
  }

  Future<void> _onPosition(Position p) async {
    final fix = NmeaFix.fromPosition(p);
    _last = fix;
    await _db.saveFix(fix);
    if (!_fixController.isClosed) _fixController.add(fix);
  }

  void dispose() => _fixController.close();
}
