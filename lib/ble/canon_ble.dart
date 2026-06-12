import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Canon BLE UUIDs (reverse-engineered from com.canon.eos.C0224b).
/// Base pattern: XXXXYYYY-0000-1000-0000-d8492fffa821  (NOTE the 0000- group).
class CanonUuids {
  static Guid svc(String x) =>
      Guid('${x}0000-0000-1000-0000-d8492fffa821');
  static Guid chr(String x) =>
      Guid('$x-0000-1000-0000-d8492fffa821');

  // Primary/advertised service used as the scan filter.
  static final primaryService = svc('0001');
  // GPS service + characteristics.
  static final gpsService = svc('0004');
  static final gpsStatus = chr('00040001'); // read/notify: byte0 bit1 = active
  static final gpsCommand = chr('00040002'); // write: source select / handshake
  static final gpsSelect = chr('00040003'); // notify: byte1 = source (4=phone)
}

enum CanonGpsSource { disable, gpsReceiver, builtinGps, builtinGpsOff, smartphone }

enum LinkState { idle, scanning, connecting, connected, bonding, ready }

/// Pairs once, auto-reconnects when the camera powers on (re-advertises the
/// primary service), and drives the GPS service into SMARTPHONE mode.
/// Mirrors com.canon.eos.C0240f (scan/reconnect) + C0299u (GPS handshake).
class CanonBle {
  static const _prefKey = 'paired_remote_id';

  final _stateController = StreamController<LinkState>.broadcast();
  Stream<LinkState> get state => _stateController.stream;
  LinkState _state = LinkState.idle;
  LinkState get currentState => _state;

  final _logController = StreamController<String>.broadcast();
  Stream<String> get log => _logController.stream;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _gpsCommand;
  BluetoothCharacteristic? _gpsStatus;
  BluetoothCharacteristic? _gpsSelect;
  StreamSubscription? _scanSub;
  StreamSubscription? _connSub;
  bool _wantConnection = false;
  bool _cameraWantsLocation = false;

  bool get cameraWantsLocation => _cameraWantsLocation;
  String? get deviceName => _device?.platformName;
  String? get deviceId => _device?.remoteId.str;

  void _setState(LinkState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  void _log(String m) {
    if (!_logController.isClosed) _logController.add(m);
  }

  Future<String?> pairedId() async =>
      (await SharedPreferences.getInstance()).getString(_prefKey);

  Future<void> _savePaired(String id) async =>
      (await SharedPreferences.getInstance()).setString(_prefKey, id);

  Future<void> forget() async {
    _wantConnection = false;
    await _device?.disconnect();
    (await SharedPreferences.getInstance()).remove(_prefKey);
    _device = null;
    _setState(LinkState.idle);
  }

  /// Start the auto-connect loop. If a device was paired before, reconnect to
  /// it; otherwise scan for any Canon camera advertising the primary service.
  Future<void> start() async {
    _wantConnection = true;
    if (await FlutterBluePlus.adapterState.first !=
        BluetoothAdapterState.on) {
      _log('Bluetooth is off');
      return;
    }
    final paired = await pairedId();
    if (paired != null) {
      _device = BluetoothDevice.fromId(paired);
      _log('Reconnecting to $paired');
      await _connect(_device!);
    } else {
      await _scanForCamera();
    }
  }

  Future<void> stop() async {
    _wantConnection = false;
    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
    await _connSub?.cancel();
    await _device?.disconnect();
    _setState(LinkState.idle);
  }

  // ---- scan (C0240f: ScanFilter on primaryService, LOW_LATENCY) ----
  Future<void> _scanForCamera() async {
    _setState(LinkState.scanning);
    _log('Scanning for Canon camera…');
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((results) async {
      if (results.isEmpty) return;
      final r = results.first;
      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();
      _device = r.device;
      _log('Found ${r.device.platformName.isEmpty ? r.device.remoteId.str : r.device.platformName}');
      await _connect(r.device);
    });
    await FlutterBluePlus.startScan(
      withServices: [CanonUuids.primaryService],
      androidScanMode: AndroidScanMode.lowLatency,
      continuousUpdates: false,
    );
  }

  // ---- connect + bond + discover GPS service ----
  Future<void> _connect(BluetoothDevice device) async {
    _setState(LinkState.connecting);
    await _connSub?.cancel();
    _connSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) {
        _onDisconnected();
      }
    });
    try {
      // autoConnect=true makes Android reconnect when the camera powers back on.
      await device.connect(autoConnect: true, mtu: null);
      await device.connectionState
          .firstWhere((s) => s == BluetoothConnectionState.connected);
      _setState(LinkState.connected);
      _log('Connected — bonding…');

      // One-time pairing/bond (C0224b: createBond after discovery).
      if (await device.bondState.first != BluetoothBondState.bonded) {
        _setState(LinkState.bonding);
        await device.createBond();
      }
      await _savePaired(device.remoteId.str);

      try {
        await device.requestMtu(247);
      } catch (_) {}

      await _discoverGps(device);
      _setState(LinkState.ready);
      _log('Ready — GPS service in SMARTPHONE mode');
    } catch (e) {
      _log('Connect failed: $e');
      _onDisconnected();
    }
  }

  Future<void> _discoverGps(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final s in services) {
      if (s.uuid == CanonUuids.gpsService) {
        for (final c in s.characteristics) {
          if (c.uuid == CanonUuids.gpsCommand) _gpsCommand = c;
          if (c.uuid == CanonUuids.gpsStatus) _gpsStatus = c;
          if (c.uuid == CanonUuids.gpsSelect) _gpsSelect = c;
        }
      }
    }
    if (_gpsStatus != null) {
      await _gpsStatus!.setNotifyValue(true);
      _gpsStatus!.onValueReceived.listen(_onGpsStatus);
    }
    if (_gpsSelect != null) {
      await _gpsSelect!.setNotifyValue(true);
    }
    // Tell the camera: use the smartphone as GPS source.
    await setGpsSource(CanonGpsSource.smartphone);
  }

  /// C0276o.I — write source-select byte to the GPS command characteristic.
  /// Decompiled mapping: index 0->{1}, 1->{2}, 2->{3}.
  Future<void> setGpsSource(CanonGpsSource src) async {
    if (_gpsCommand == null) return;
    // SMARTPHONE handshake: C0299u.a writes [5,0,0,0,0,0,0,0] when enabled.
    final payload = switch (src) {
      CanonGpsSource.gpsReceiver => [1],
      CanonGpsSource.builtinGps => [2],
      CanonGpsSource.builtinGpsOff => [3],
      CanonGpsSource.smartphone => [5, 0, 0, 0, 0, 0, 0, 0],
      CanonGpsSource.disable => [0],
    };
    await _gpsCommand!.write(payload, withoutResponse: false);
    _log('GPS source -> $src');
  }

  // C0299u.a: status byte0 bit1 (0x02) => camera wants location now.
  void _onGpsStatus(List<int> value) {
    if (value.isEmpty) return;
    final active = (value[0] & 0x02) == 0x02;
    if (active != _cameraWantsLocation) {
      _cameraWantsLocation = active;
      _log('Camera GPS active: $active');
    }
  }

  void _onDisconnected() {
    _gpsCommand = _gpsStatus = _gpsSelect = null;
    _cameraWantsLocation = false;
    if (!_wantConnection) return;
    _log('Disconnected — will reconnect when camera powers on');
    _setState(LinkState.scanning);
    // With autoConnect the OS handles reconnect; also rescan as a fallback.
  }

  void dispose() {
    _stateController.close();
    _logController.close();
  }
}
