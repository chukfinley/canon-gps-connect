import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../ble/canon_ble.dart';
import '../gps/gps_service.dart';
import '../gps/log_db.dart';
import '../settings.dart';

/// Entry point of the foreground-service isolate. Must be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(CanonTaskHandler());
}

/// Runs BLE + GPS inside the persistent foreground service, so it keeps working
/// when the app is backgrounded or swiped away, and auto-starts on boot.
///
/// Battery: the BLE link is cheap and stays connected to detect the camera; the
/// GPS (the expensive part) is started ONLY while the camera asks for location
/// (CanonBle.wantedChanges) and stopped as soon as it doesn't.
class CanonTaskHandler extends TaskHandler {
  CanonBle? _ble;
  GpsService? _gps;
  GpsLogDb? _db;
  final _subs = <StreamSubscription>[];
  int _interval = Settings.defaultInterval;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _interval = await Settings.intervalSeconds();
    _db = await GpsLogDb.open();
    final db = _db!;
    final gps = _gps = GpsService(db);
    final ble = _ble = CanonBle();

    // Camera asks for / stops asking for location -> start / stop GPS polling.
    _subs.add(ble.wantedChanges.listen((wanted) async {
      if (wanted) {
        await gps.start(seconds: _interval);
        _notify('Streaming GPS to ${ble.deviceName ?? "camera"}');
      } else {
        await gps.stop();
        _notify('Connected — idle (camera not requesting GPS)');
      }
      _pushStatus();
    }));

    // Every fix: push to the camera (gps.fixes also persists to the DB).
    _subs.add(gps.fixes.listen((fix) async {
      await ble.pushLocation(fix);
      _pushStatus(lat: fix.latitude, lon: fix.longitude);
    }));

    _subs.add(ble.state.listen((_) {
      _notify(_stateText());
      _pushStatus();
    }));
    _subs.add(ble.log.listen((m) =>
        FlutterForegroundTask.sendDataToMain({'log': m})));

    await ble.start(); // auto-connect / reconnect loop
    _notify(_stateText());
    _pushStatus();
  }

  // The service ticks rarely (eventAction repeat) just to refresh status.
  @override
  void onRepeatEvent(DateTime timestamp) => _pushStatus();

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _gps?.stop();
    await _ble?.stop();
    _ble?.dispose();
    _gps?.dispose();
  }

  /// Commands from the UI isolate.
  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    switch (data['cmd']) {
      case 'setInterval':
        final v = (data['value'] as num?)?.toInt();
        if (v != null) {
          _interval = v;
          Settings.setIntervalSeconds(v);
          _gps?.setInterval(v);
        }
      case 'forget':
        _ble?.forget();
      case 'status':
        _pushStatus();
    }
  }

  String _stateText() {
    final ble = _ble;
    if (ble == null) return 'Starting…';
    return switch (ble.currentState) {
      LinkState.idle => 'Idle',
      LinkState.scanning => 'Searching for camera…',
      LinkState.connecting => 'Connecting…',
      LinkState.connected => 'Connected',
      LinkState.bonding => 'Pairing…',
      LinkState.registering => 'Registering on camera…',
      LinkState.ready => ble.gpsWanted ? 'Streaming GPS' : 'Connected — idle',
    };
  }

  void _notify(String text) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'Canon GPS Connect',
      notificationText: text,
    );
  }

  void _pushStatus({double? lat, double? lon}) {
    final ble = _ble;
    final status = <String, dynamic>{
      'state': ble?.currentState.name ?? 'idle',
      'device': ble?.deviceName,
      'wanted': ble?.gpsWanted ?? false,
      'interval': _interval,
    };
    if (lat != null) status['lat'] = lat;
    if (lon != null) status['lon'] = lon;
    FlutterForegroundTask.sendDataToMain({'status': status});
  }
}
