import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import 'service/canon_task_handler.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Port for UI <-> foreground-service-isolate messages.
  FlutterForegroundTask.initCommunicationPort();
  runApp(const CanonGpsApp());
}

class CanonGpsApp extends StatelessWidget {
  const CanonGpsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamConnect GPS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE60012),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      // Handles relaunch from the service notification.
      home: const WithForegroundTask(child: HomePage()),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _running = false;
  String _state = 'idle';
  String? _device;
  bool _wanted = false;
  double? _lat, _lon;
  int _interval = Settings.defaultInterval;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onData);
    _bootstrap();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onData);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _interval = await Settings.intervalSeconds();
    await _initFgs();
    _running = await FlutterForegroundTask.isRunningService;
    if (mounted) setState(() {});
  }

  Future<void> _initFgs() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'canon_gps',
        channelName: 'CamConnect GPS',
        channelDescription: 'Keeps the camera connection and GPS alive',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Low-power: tick rarely just to refresh status; GPS itself is driven
        // on-demand by the camera, not by this event.
        eventAction: ForegroundTaskEventAction.repeat(15000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  void _onData(Object data) {
    if (data is! Map) return;
    if (data['log'] is String) {
      setState(() {
        _log.insert(0, data['log'] as String);
        if (_log.length > 80) _log.removeLast();
      });
    }
    final s = data['status'];
    if (s is Map) {
      setState(() {
        _state = (s['state'] as String?) ?? _state;
        _device = s['device'] as String?;
        _wanted = (s['wanted'] as bool?) ?? false;
        _interval = (s['interval'] as num?)?.toInt() ?? _interval;
        if (s['lat'] is num) _lat = (s['lat'] as num).toDouble();
        if (s['lon'] is num) _lon = (s['lon'] as num).toDouble();
      });
    }
  }

  Future<bool> _ensurePermissions() async {
    await FlutterForegroundTask.requestNotificationPermission();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    if (!await Permission.locationWhenInUse.isGranted) {
      await Permission.locationWhenInUse.request();
    }
    final fine = await Permission.locationWhenInUse.isGranted;
    if (fine && !await Permission.locationAlways.isGranted) {
      await Permission.locationAlways.request();
    }
    // Best-effort: ask the OS to exempt us from battery optimisation so the
    // service survives Doze (this does NOT increase battery use — GPS is still
    // on-demand; it just stops the OS from killing the connection).
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    final ok = fine && await Permission.bluetoothConnect.isGranted;
    if (!ok) _toast('Grant Location + Nearby devices to start');
    return ok;
  }

  Future<void> _start() async {
    if (!await _ensurePermissions()) return;
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'CamConnect GPS',
      notificationText: 'Searching for your camera…',
      callback: startCallback,
    );
    setState(() => _running = true);
  }

  Future<void> _stop() async {
    await FlutterForegroundTask.stopService();
    setState(() {
      _running = false;
      _state = 'idle';
      _wanted = false;
    });
  }

  Future<void> _setInterval(int v) async {
    await Settings.setIntervalSeconds(v);
    setState(() => _interval = v);
    if (_running) {
      FlutterForegroundTask.sendDataToTask({'cmd': 'setInterval', 'value': v});
    }
  }

  void _forget() {
    FlutterForegroundTask.sendDataToTask({'cmd': 'forget'});
    _toast('Camera forgotten — will re-pair next time');
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('CamConnect GPS'),
        actions: [
          IconButton(
            tooltip: 'Forget camera',
            onPressed: _running ? _forget : null,
            icon: const Icon(Icons.link_off),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusHero(
            running: _running,
            state: _state,
            device: _device,
            wanted: _wanted,
            lat: _lat,
            lon: _lon,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: _running
                ? OutlinedButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop service'),
                  )
                : FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Start — connect & track'),
                  ),
          ),
          const SizedBox(height: 24),
          Text('GPS update rate',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          _IntervalSelector(value: _interval, onChanged: _setInterval),
          const SizedBox(height: 6),
          Text(
            'GPS only runs while the camera asks for it. Faster = smoother track, more battery.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _LogPanel(lines: _log),
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.running,
    required this.state,
    required this.device,
    required this.wanted,
    required this.lat,
    required this.lon,
  });
  final bool running;
  final String state;
  final String? device;
  final bool wanted;
  final double? lat, lon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, color, label) = !running
        ? (Icons.power_off, cs.outline, 'Service stopped')
        : wanted
            ? (Icons.gps_fixed, const Color(0xFF22C55E), 'Streaming GPS to camera')
            : state == 'ready' || state == 'connected'
                ? (Icons.bluetooth_connected, cs.primary, 'Connected — idle')
                : (Icons.bluetooth_searching, cs.tertiary, _pretty(state));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(device ?? (running ? 'No camera yet' : 'Press start'),
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          if (lat != null && lon != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.place, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '${lat!.toStringAsFixed(5)},  ${lon!.toStringAsFixed(5)}',
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 15),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _pretty(String s) => switch (s) {
        'scanning' => 'Searching for camera…',
        'connecting' => 'Connecting…',
        'bonding' => 'Pairing…',
        'registering' => 'Registering on camera…',
        _ => 'Working…',
      };
}

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  String _label(int s) => s < 60 ? '${s}s' : '${s ~/ 60}m';

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: Settings.intervalOptions.map((s) {
        final sel = s == value;
        return ChoiceChip(
          label: Text(_label(s)),
          selected: sel,
          onSelected: (_) => onChanged(s),
        );
      }).toList(),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false, // collapsed by default
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 8),
        title: Text('Activity log (${lines.length})',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: lines.isEmpty
                ? Text('No activity yet',
                    style: TextStyle(color: cs.onSurfaceVariant))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: lines.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(lines[i],
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace')),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
