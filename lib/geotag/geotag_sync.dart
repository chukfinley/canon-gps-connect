import 'package:flutter/services.dart';

import '../gps/log_db.dart';

/// Layer-3 orchestration: once the phone is on the camera's WiFi, ask the
/// camera for the photos it captured in a time window, match each to the
/// nearest logged NMEA fix, and push it back so the camera writes GPS EXIF
/// on-device. Mirrors com.canon.eos `IMLRequestGpsTagObjectListCommand` +
/// `IMLAattachGpsTagInfoCommand`.
class GeotagSync {
  static const _ch = MethodChannel('canon_gps_connect/imagelink');
  final GpsLogDb _db;

  GeotagSync(this._db);

  /// Start the native IMLink session (must already be joined to camera WiFi).
  /// Returns the native result code (0 == OK).
  Future<int> init({
    String modelName = 'CanonGpsConnect',
    String friendlyName = 'Canon GPS Connect',
    String targetId = '00000000-0000-0000-0000-000000000000',
    String vendorExtVer = '1.0',
  }) async {
    return await _ch.invokeMethod<int>('init', {
          'modelName': modelName,
          'friendlyName': friendlyName,
          'targetId': targetId,
          'vendorExtVer': vendorExtVer,
        }) ??
        -1;
  }

  /// op31 → list of captured objects with their ISO capture time.
  Future<List<({int objectId, DateTime time})>> requestObjects(
      DateTime fromUtc, DateTime toUtc) async {
    final raw = await _ch.invokeListMethod<Map<dynamic, dynamic>>(
      'requestObjectList',
      {'from': _iso(fromUtc), 'to': _iso(toUtc)},
    );
    if (raw == null) return const [];
    return raw
        .map((m) => (
              objectId: (m['objectId'] as num).toInt(),
              time: DateTime.parse(m['timeIso'] as String),
            ))
        .toList();
  }

  /// op33 → attach the NMEA string to one object. 0 == OK.
  Future<int> attachGps(int objectId, String nmea) async {
    return await _ch.invokeMethod<int>('attachGps', {
          'objectId': objectId,
          'nmea': nmea,
        }) ??
        -1;
  }

  Future<void> destroy() => _ch.invokeMethod('destroy');

  /// Full sync: for every photo in [fromUtc..toUtc], match nearest NMEA and tag.
  /// Returns (tagged, skipped).
  Future<({int tagged, int skipped})> syncRange(
      DateTime fromUtc, DateTime toUtc,
      {void Function(String)? onLog}) async {
    final objects = await requestObjects(fromUtc, toUtc);
    onLog?.call('Camera reported ${objects.length} photos');
    var tagged = 0, skipped = 0;
    for (final o in objects) {
      final fix = await _db.nearestFix(o.time.toUtc().millisecondsSinceEpoch);
      if (fix == null) {
        skipped++;
        continue;
      }
      final rc = await attachGps(o.objectId, fix.nmea);
      if (rc == 0) {
        tagged++;
      } else {
        skipped++;
        onLog?.call('Object ${o.objectId}: attach failed rc=$rc');
      }
    }
    onLog?.call('Tagged $tagged, skipped $skipped');
    return (tagged: tagged, skipped: skipped);
  }

  // Canon uses yyyy-MM-dd'T'HH:mm:ss (Locale.US) for RequestTimeList.
  static String _iso(DateTime t) {
    final u = t.toUtc();
    String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return '${p(u.year, 4)}-${p(u.month)}-${p(u.day)}T${p(u.hour)}:${p(u.minute)}:${p(u.second)}';
  }
}
