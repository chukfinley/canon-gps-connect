import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble/canon_ble.dart';
import 'geotag/geotag_sync.dart';
import 'gps/gps_service.dart';
import 'gps/log_db.dart';
import 'gps/nmea.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await GpsLogDb.open();
  runApp(CanonGpsApp(db: db));
}

class CanonGpsApp extends StatelessWidget {
  const CanonGpsApp({super.key, required this.db});
  final GpsLogDb db;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canon GPS Connect',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFCC0000),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomePage(db: db),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.db});
  final GpsLogDb db;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GpsService _gps = GpsService(widget.db);
  late final CanonBle _ble = CanonBle();
  late final GeotagSync _geotag = GeotagSync(widget.db);

  final List<String> _log = [];
  LinkState _link = LinkState.idle;
  NmeaFix? _lastFix;
  int _logCount = 0;
  bool _permsOk = false;

  @override
  void initState() {
    super.initState();
    _ble.state.listen((s) => setState(() => _link = s));
    _ble.log.listen(_addLog);
    _gps.fixes.listen((f) async {
      final c = await widget.db.count();
      if (!mounted) return;
      setState(() {
        _lastFix = f;
        _logCount = c;
      });
    });
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final c = await widget.db.count();
    if (mounted) setState(() => _logCount = c);
  }

  void _addLog(String m) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, m);
      if (_log.length > 60) _log.removeLast();
    });
  }

  Future<bool> _ensurePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();
    // Background location must be requested separately, after while-in-use.
    final bg = await Permission.locationAlways.request();
    final ok = await Permission.locationWhenInUse.isGranted &&
        await Permission.bluetoothConnect.isGranted;
    _addLog(ok
        ? 'Permissions granted (background: ${bg.isGranted})'
        : 'Permissions missing — enable in settings');
    if (mounted) setState(() => _permsOk = ok);
    return ok;
  }

  Future<void> _startAll() async {
    if (!await _ensurePermissions()) return;
    if (!await Geolocator.isLocationServiceEnabled()) {
      _addLog('Turn on device location services');
      return;
    }
    await _gps.start();
    _addLog('GPS logging started (10s, high accuracy)');
    await _ble.start();
    setState(() {});
  }

  Future<void> _stopAll() async {
    await _gps.stop();
    await _ble.stop();
    _addLog('Stopped');
    setState(() {});
  }

  Future<void> _syncNow() async {
    _addLog('Geotag sync: join the camera WiFi first, then run this.');
    try {
      final rc = await _geotag.init();
      if (rc != 0) {
        _addLog('IMLink init failed rc=$rc (on camera WiFi?)');
        return;
      }
      final now = DateTime.now().toUtc();
      final res = await _geotag.syncRange(
        now.subtract(const Duration(days: 2)),
        now,
        onLog: _addLog,
      );
      _addLog('Done: tagged ${res.tagged}, skipped ${res.skipped}');
      await _geotag.destroy();
    } catch (e) {
      _addLog('Sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final running = _gps.running;
    return Scaffold(
      appBar: AppBar(title: const Text('Canon GPS Connect')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusCard(
              link: _link,
              deviceName: _ble.deviceName,
              cameraWants: _ble.cameraWantsLocation,
              lastFix: _lastFix,
              logCount: _logCount,
              permsOk: _permsOk,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: running ? null : _startAll,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: running ? _stopAll : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _syncNow,
                  icon: const Icon(Icons.wifi_find),
                  label: const Text('Geotag photos now (WiFi)'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Forget camera',
                onPressed: () => _ble.forget(),
                icon: const Icon(Icons.link_off),
              ),
            ]),
            const SizedBox(height: 12),
            const Text('Activity',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(_log[i],
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gps.dispose();
    _ble.dispose();
    super.dispose();
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.link,
    required this.deviceName,
    required this.cameraWants,
    required this.lastFix,
    required this.logCount,
    required this.permsOk,
  });

  final LinkState link;
  final String? deviceName;
  final bool cameraWants;
  final NmeaFix? lastFix;
  final int logCount;
  final bool permsOk;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Camera', deviceName ?? 'not paired'),
            _row(
                'BLE link',
                link.name +
                    (cameraWants ? '  • camera wants GPS' : '')),
            _row('Permissions', permsOk ? 'ok' : 'needed'),
            _row('Logged fixes', '$logCount'),
            if (lastFix != null)
              _row('Last fix',
                  '${lastFix!.latitude.toStringAsFixed(5)}, ${lastFix!.longitude.toStringAsFixed(5)}'),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
                width: 120,
                child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
