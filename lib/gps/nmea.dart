import 'package:geolocator/geolocator.dart';

/// Exact Dart port of Canon's `i4.j` NMEA builder (decompiled from
/// jp.co.canon.ic.cameraconnect). The camera receives THIS string per photo
/// (IMLink opcode 33 / GPSInformation.mGps) and parses it itself into EXIF.
///
/// Output format (verbatim from `i4.j.b`):
/// `$GPGGA,hhmmss.000,ddmm.mmmmm,N,dddmm.mmmmm,E,1,6,0,[alt],M,0,M,,*XX`
/// `$GPRMC,hhmmss.000,A,ddmm.mmmmm,N,dddmm.mmmmm,E,[spd],[brg],ddmmyy,0,A*XX`
class NmeaFix {
  final int timeMillis; // UTC epoch millis (location.getTime())
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speed;
  final double bearing;
  final String nmea;

  const NmeaFix({
    required this.timeMillis,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speed,
    required this.bearing,
    required this.nmea,
  });

  factory NmeaFix.fromPosition(Position p) {
    final nmea = buildNmea(
      timeMillis: p.timestamp.toUtc().millisecondsSinceEpoch,
      latitude: p.latitude,
      longitude: p.longitude,
      altitude: p.altitude,
      hasAltitude: true,
      speed: p.speed,
      hasSpeed: p.speed > 0,
      bearing: p.heading,
      hasBearing: p.heading > 0,
    );
    return NmeaFix(
      timeMillis: p.timestamp.toUtc().millisecondsSinceEpoch,
      latitude: p.latitude,
      longitude: p.longitude,
      altitude: p.altitude,
      accuracy: p.accuracy,
      speed: p.speed,
      bearing: p.heading,
      nmea: nmea,
    );
  }

  Map<String, Object?> toRow() => {
        'time': timeMillis,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'speed': speed,
        'bearing': bearing,
        'nmea': nmea,
      };

  static NmeaFix fromRow(Map<String, Object?> r) => NmeaFix(
        timeMillis: (r['time'] as num).toInt(),
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
        altitude: (r['altitude'] as num).toDouble(),
        accuracy: (r['accuracy'] as num?)?.toDouble() ?? 0,
        speed: (r['speed'] as num?)?.toDouble() ?? 0,
        bearing: (r['bearing'] as num?)?.toDouble() ?? 0,
        nmea: r['nmea'] as String,
      );
}

/// `i4.j.a(deg)` — degrees to NMEA "ddmm.mmmmm" (lat 2 int digits, lon 3).
String _nmeaDegMin(double absDeg) {
  final intPart = absDeg.truncate(); // (int) cast in Java
  final minutes = (absDeg - intPart) * 60.0;
  var min = minutes.toStringAsFixed(5); // "%7.5f"
  // Java: if (format.indexOf(".") < 2) prepend "0"  -> ensures 2-digit minutes
  if (min.indexOf('.') < 2) min = '0$min';
  return '$intPart$min'; // "%1.0f" + minutes
}

int _xorChecksum(String body) {
  final bytes = body.codeUnits;
  var c = bytes[0];
  for (var i = 1; i < bytes.length; i++) {
    c ^= bytes[i];
  }
  return c & 0xFF;
}

String _hex2(int v) => v.toRadixString(16).toUpperCase().padLeft(2, '0');

/// Verbatim port of `i4.j.b(Location)`. All time fields are UTC.
String buildNmea({
  required int timeMillis,
  required double latitude,
  required double longitude,
  required double altitude,
  bool hasAltitude = true,
  double speed = 0,
  bool hasSpeed = false,
  double bearing = 0,
  bool hasBearing = false,
}) {
  final t = DateTime.fromMillisecondsSinceEpoch(timeMillis, isUtc: true);
  final hms =
      '${_p2(t.hour)}${_p2(t.minute)}${_p2(t.second)}.000'; // hhmmss.000
  final dmy =
      '${_p2(t.day)}${_p2(t.month)}${_p2(t.year % 100)}'; // ddmmyy

  final latRef = latitude < 0 ? 'S' : 'N';
  final lat = _nmeaDegMin(latitude.abs());
  final lonRef = longitude < 0 ? 'W' : 'E';
  final lon = _nmeaDegMin(longitude.abs());

  final altStr = hasAltitude ? altitude.toStringAsFixed(1) : '0';
  final spdStr = hasSpeed ? speed.toStringAsFixed(1) : '';
  final brgStr = hasBearing ? bearing.toStringAsFixed(1) : '';

  // GPGGA,<time>,<lat>,<N|S>,<lon>,<E|W>,1,6,0,<alt>,M,0,M,,
  final gga = 'GPGGA,$hms,$lat,$latRef,$lon,$lonRef,1,6,0,$altStr,M,0,M,,';
  // GPRMC,<time>,A,<lat>,<N|S>,<lon>,<E|W>,<spd>,<brg>,<date>,0,A
  final rmc =
      'GPRMC,$hms,A,$lat,$latRef,$lon,$lonRef,$spdStr,$brgStr,$dmy,0,A';

  return '\$$gga*${_hex2(_xorChecksum(gga))}\r\n'
      '\$$rmc*${_hex2(_xorChecksum(rmc))}\r\n';
}

String _p2(int v) => v.toString().padLeft(2, '0');
