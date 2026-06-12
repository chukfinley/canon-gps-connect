import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'log_db.dart';
import 'nmea.dart';

/// Background GPS logger. Mirrors Canon's `i4.n` location config:
/// PRIORITY_HIGH_ACCURACY, 10 s interval (5 s fastest).
class GpsService {
  GpsService(this._db);
  final GpsLogDb _db;

  StreamSubscription<Position>? _sub;
  NmeaFix? _last;
  int? _termStart;

  final _fixController = StreamController<NmeaFix>.broadcast();
  Stream<NmeaFix> get fixes => _fixController.stream;
  NmeaFix? get lastFix => _last;
  bool get running => _sub != null;

  // Canon: locationRequest interval 10000ms, fastest 5000ms, HIGH_ACCURACY.
  static final _settings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    intervalDuration: const Duration(seconds: 10),
    distanceFilter: 0,
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: 'Canon GPS Connect',
      notificationText: 'Logging location for your camera',
      enableWakeLock: true,
    ),
  );

  Future<void> start() async {
    if (_sub != null) return;
    _termStart = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.beginTerm(_termStart!);
    _sub = Geolocator.getPositionStream(locationSettings: _settings)
        .listen(_onPosition, onError: (_) {});
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
