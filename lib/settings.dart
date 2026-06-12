import 'package:shared_preferences/shared_preferences.dart';

/// User settings shared between the UI isolate and the foreground-service
/// isolate (both read SharedPreferences).
class Settings {
  static const _kInterval = 'gps_interval_seconds';
  static const _kNickname = 'nickname';

  /// Selectable GPS update intervals (seconds). Lower = smoother track, more
  /// battery. The camera only receives fixes while it asks for them anyway.
  static const intervalOptions = <int>[1, 3, 5, 10, 30, 60];
  static const defaultInterval = 10;

  static Future<int> intervalSeconds() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kInterval) ?? defaultInterval;
  }

  static Future<void> setIntervalSeconds(int s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kInterval, s);
  }

  static Future<String> nickname() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kNickname) ?? 'CCGPS';
  }

  static Future<void> setNickname(String n) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kNickname, n);
  }
}
