import 'dart:async';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gps/nmea.dart';

/// Canon BLE UUIDs (reverse-engineered from com.canon.eos.C0224b).
/// Base pattern: XXXXYYYY-0000-1000-0000-d8492fffa821  (NOTE the 0000- group).
class CanonUuids {
  static Guid svc(String x) => Guid('${x}0000-0000-1000-0000-d8492fffa821');
  static Guid chr(String x) => Guid('$x-0000-1000-0000-d8492fffa821');

  // Primary/advertised control service (scan filter).
  static final primaryService = svc('0001');
  static final ctrlState = chr('00010005'); // indicate: camera state
  static final ctrlRegister = chr('00010006'); // write+indicate: register/nick
  static final ctrlAuth = chr('0001000a'); // write: auth opcode channel (Q enum)
  static final ctrlCapability = chr('0001000b'); // read: feature flags

  // Connection-info service (WiFi/identity handover).
  static final connInfo = chr('00020002'); // write 0x0a -> notify conn info

  // GPS service + characteristics.
  static final gpsService = svc('0004');
  static final gpsStatus = chr('00040001'); // notify: byte0 bit1 = wants loc
  static final gpsCommand = chr('00040002'); // write: source/handshake/frame
  static final gpsSelect = chr('00040003'); // indicate: 1=unwanted 2=WANTED ...
}

/// Auth-channel opcodes written to 0001000a (com.canon.eos.Q enum).
class _AuthOp {
  static const success = 0x01; // Q.SUCCESS
  static const uuid = 0x03; // Q.UUID  + 16-byte initiator GUID
  static const nickName = 0x04; // Q.NICK_NAME + ascii
  static const type = 0x05; // Q.TYPE -> constant {5,2}
}

enum CanonGpsSource { disable, gpsReceiver, builtinGps, builtinGpsOff, smartphone }

enum LinkState { idle, scanning, connecting, connected, bonding, registering, ready }

/// Full EOS BLE client: pairs once, registers + authenticates with the camera
/// (the handshake the camera REQUIRES before it will accept GPS), auto-reconnects
/// on power-on, and streams real-time location frames while the camera wants them.
///
/// Handshake verified against a real EOS 250D btsnoop capture. Mirrors
/// com.canon.eos C0276o.B() (registration), T/Q (auth opcodes), C0299u (GPS).
class CanonBle {
  static const _prefPaired = 'paired_remote_id';
  static const _prefGuid = 'initiator_guid';
  static const _prefNick = 'nickname';
  static const _defaultNick = 'CCGPS';

  final _stateController = StreamController<LinkState>.broadcast();
  Stream<LinkState> get state => _stateController.stream;
  LinkState _state = LinkState.idle;
  LinkState get currentState => _state;

  final _logController = StreamController<String>.broadcast();
  Stream<String> get log => _logController.stream;

  BluetoothDevice? _device;
  // Control-service characteristics.
  BluetoothCharacteristic? _register, _auth, _capability, _connInfo;
  // GPS-service characteristics.
  BluetoothCharacteristic? _gpsCommand, _gpsSelect;
  StreamSubscription? _scanSub, _connSub;
  final List<StreamSubscription> _valueSubs = [];

  bool _wantConnection = false;
  bool _cameraWantsLocation = false;
  bool _gpsWanted = false;
  bool _handshaking = false;
  bool _ready = false;

  bool get cameraWantsLocation => _cameraWantsLocation;
  bool get gpsWanted => _gpsWanted;
  String? get deviceName => _device?.platformName;
  String? get deviceId => _device?.remoteId.str;

  void _setState(LinkState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  void _log(String m) {
    if (!_logController.isClosed) _logController.add(m);
  }

  // ---- identity (persisted once, replayed every connect) -------------------

  /// 16-byte initiator GUID. Generated once, stored, sent in the 0x03 auth op.
  /// The camera ties registration to this value — must be stable.
  Future<List<int>> _identityGuid() async {
    final prefs = await SharedPreferences.getInstance();
    var hex = prefs.getString(_prefGuid);
    if (hex == null) {
      final r = Random.secure();
      final b = List<int>.generate(16, (_) => r.nextInt(256));
      hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(_prefGuid, hex);
    }
    return [
      for (var i = 0; i < 32; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16)
    ];
  }

  Future<List<int>> _nickBytes() async {
    final prefs = await SharedPreferences.getInstance();
    final nick = prefs.getString(_prefNick) ?? _defaultNick;
    return nick.codeUnits; // ASCII
  }

  Future<void> setNickname(String nick) async =>
      (await SharedPreferences.getInstance()).setString(_prefNick, nick);

  // ---- pairing bookkeeping -------------------------------------------------

  Future<String?> pairedId() async =>
      (await SharedPreferences.getInstance()).getString(_prefPaired);

  Future<void> _savePaired(String id) async =>
      (await SharedPreferences.getInstance()).setString(_prefPaired, id);

  // Per-camera "already registered" flag. Once the camera has accepted our GUID
  // (indicate 0x02 on 00010006), we NEVER re-run the register write — that is
  // what makes it "register once, then silently reconnect". (C0276o.B(): the
  // 00010006 write only runs when the camera advertises it needs pairing.)
  String _regKey(String id) => 'registered_$id';

  Future<bool> _isRegistered(String id) async =>
      (await SharedPreferences.getInstance()).getBool(_regKey(id)) ?? false;

  Future<void> _setRegistered(String id) async =>
      (await SharedPreferences.getInstance()).setBool(_regKey(id), true);

  Future<void> forget() async {
    _wantConnection = false;
    await _device?.disconnect();
    final prefs = await SharedPreferences.getInstance();
    final id = _device?.remoteId.str ?? prefs.getString(_prefPaired);
    if (id != null) await prefs.remove(_regKey(id));
    await prefs.remove(_prefPaired);
    _device = null;
    _setState(LinkState.idle);
  }

  Future<void> start() async {
    _wantConnection = true;
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
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

  // Canon manufacturer id in BLE advertisements (com.canon.eos C0232d).
  static const _canonManufacturerId = 0x01A9; // 425

  // ---- scan: match Canon manufacturer data, NOT just the service UUID. A
  // registered camera advertises its real UUID, so a service-UUID-only filter
  // can miss it (C0232d validates getManufacturerSpecificData(425)). ----------
  Future<void> _scanForCamera() async {
    _setState(LinkState.scanning);
    _log('Scanning for Canon camera…');
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((results) async {
      for (final r in results) {
        if (!r.advertisementData.manufacturerData
            .containsKey(_canonManufacturerId)) {
          continue;
        }
        await FlutterBluePlus.stopScan();
        await _scanSub?.cancel();
        _scanSub = null;
        final name = r.device.platformName.isEmpty
            ? r.device.remoteId.str
            : r.device.platformName;
        _log('Found Canon camera: $name');
        await _connect(r.device);
        return;
      }
    });
    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
      continuousUpdates: true,
    );
  }

  // ---- connect + bond + handshake; the connectionState listener re-runs the
  // handshake on every (re)connect and re-arms after a drop. autoConnect=true
  // lets Android re-link when the camera powers on again. --------------------
  Future<void> _connect(BluetoothDevice device) async {
    _device = device;
    _ready = false;
    _setState(LinkState.connecting);
    await _connSub?.cancel();
    _connSub = device.connectionState.listen((s) async {
      if (s == BluetoothConnectionState.connected) {
        await _onConnected(device);
      } else if (s == BluetoothConnectionState.disconnected) {
        _onDisconnected();
      }
    });
    try {
      await device.connect(autoConnect: true, mtu: null);
    } catch (e) {
      _log('connect: $e');
    }
    // Fallback: if autoConnect hasn't linked in 25 s, scan for the camera.
    Future.delayed(const Duration(seconds: 25), () async {
      if (_wantConnection && !_ready && _state != LinkState.connected) {
        if (await device.connectionState.first !=
            BluetoothConnectionState.connected) {
          _log('Still not connected — rescanning');
          await _scanForCamera();
        }
      }
    });
  }

  Future<void> _onConnected(BluetoothDevice device) async {
    if (_handshaking || _ready) return;
    _handshaking = true;
    try {
      _setState(LinkState.connected);
      if (await device.bondState.first != BluetoothBondState.bonded) {
        _setState(LinkState.bonding);
        _log('Bonding…');
        await device.createBond();
      }
      await _savePaired(device.remoteId.str);
      try {
        await device.requestMtu(247);
      } catch (_) {}
      await _runHandshake(device);
      _ready = true;
      _setState(LinkState.ready);
      _log('Ready — authenticated, awaiting GPS request');
    } catch (e) {
      _log('Handshake failed: $e');
      try {
        await device.disconnect();
      } catch (_) {}
    } finally {
      _handshaking = false;
    }
  }

  /// The sequence the camera requires before it will send GPS (verified vs
  /// real EOS 250D btsnoop). Without this the camera ignores the GPS service.
  Future<void> _runHandshake(BluetoothDevice device) async {
    final services = await device.discoverServices();
    BluetoothCharacteristic? state;
    final notifyChars = <BluetoothCharacteristic>[];

    for (final s in services) {
      for (final c in s.characteristics) {
        final u = c.uuid;
        if (u == CanonUuids.ctrlState) state = c;
        if (u == CanonUuids.ctrlRegister) _register = c;
        if (u == CanonUuids.ctrlAuth) _auth = c;
        if (u == CanonUuids.ctrlCapability) _capability = c;
        if (u == CanonUuids.connInfo) _connInfo = c;
        if (u == CanonUuids.gpsCommand) _gpsCommand = c;
        if (u == CanonUuids.gpsSelect) _gpsSelect = c;
        // Collect every notify/indicate char on services 0x0002/0x0003/0x0004.
        final svc = s.uuid.str.substring(0, 4);
        if ((c.properties.notify || c.properties.indicate) &&
            (svc == '0002' || svc == '0003' || svc == '0004')) {
          notifyChars.add(c);
        }
      }
    }
    if (_auth == null || _register == null) {
      throw StateError('Canon control service not found');
    }

    final guid = await _identityGuid();
    final nick = await _nickBytes();
    final id = device.remoteId.str;
    final alreadyRegistered = await _isRegistered(id);

    // 1) Enable indicate on camera-state char.
    if (state != null) await state.setNotifyValue(true);
    await _register!.setNotifyValue(true);

    // 2) Register — ONLY the first time. After the camera has accepted our GUID
    //    we skip this entirely and just reconnect+auth (the "connect once" path).
    if (!alreadyRegistered) {
      _setState(LinkState.registering);
      // S.OK = 0x02 (accept). S.NG = 0x03 is a transient "waiting for the user
      // to confirm on the camera body" state — keep waiting, don't abort on it.
      final regOk = _register!.onValueReceived
          .firstWhere((v) => v.isNotEmpty && v[0] == 0x02)
          .timeout(const Duration(seconds: 120), onTimeout: () => const <int>[]);
      await _register!.write([0x01, ...nick], withoutResponse: false);
      _log('First-time registration as "${String.fromCharCodes(nick)}" — '
          'confirm on the camera (connect to smartphone → register device)');
      final reg = await regOk;
      if (reg.isEmpty || reg[0] != 0x02) {
        throw StateError(
            'Registration not confirmed on the camera. On the camera: '
            'Wi-Fi/Bluetooth → connect to smartphone → register this device, then retry.');
      }
      await _setRegistered(id);
      _log('Registered & saved — future connects are automatic');
    } else {
      _log('Already registered — reconnecting');
    }

    // 3) Read capability flags (drives feature availability).
    try {
      if (_capability != null) await _capability!.read();
    } catch (_) {}

    // 4) Enable notifications/indications on conn + GPS service chars.
    for (final c in notifyChars) {
      try {
        await c.setNotifyValue(true);
      } catch (_) {}
    }
    _attachGpsListeners();

    // 5) Auth channel (0001000a): UUID, NICK_NAME, TYPE.
    await _auth!.write([_AuthOp.uuid, ...guid], withoutResponse: false);
    await _auth!.write([_AuthOp.nickName, ...nick], withoutResponse: false);
    await _auth!.write([_AuthOp.type, 0x02], withoutResponse: false);

    // 6) Connection-info exchange: write 0x0a, AWAIT the camera's notify before
    //    completing auth (official app gates SUCCESS on this — B.a()).
    if (_connInfo != null) {
      try {
        final notif = _connInfo!.onValueReceived.first
            .timeout(const Duration(seconds: 5), onTimeout: () => const <int>[]);
        await _connInfo!.write([0x0a], withoutResponse: false);
        await notif;
      } catch (_) {}
    }

    // 7) Auth complete.
    await _auth!.write([_AuthOp.success], withoutResponse: false);
    _log('Authenticated');
  }

  void _attachGpsListeners() {
    // Guard against double-attach if the handshake re-runs without a disconnect.
    for (final s in _valueSubs) {
      s.cancel();
    }
    _valueSubs.clear();
    if (_gpsSelect != null) {
      _valueSubs.add(_gpsSelect!.onValueReceived.listen(_onGpsSelect));
    }
  }

  /// Send the 8-byte enable handshake (C0299u.a: [05,0,0,0,0,0,0,0]) to the GPS
  /// command char so the camera starts/keeps the smartphone GPS source.
  Future<void> _sendGpsEnable() async {
    if (_gpsCommand == null) return;
    try {
      await _gpsCommand!
          .write([5, 0, 0, 0, 0, 0, 0, 0], withoutResponse: false);
    } catch (_) {}
  }

  // C0299u.b: 00040003 indicate. byte0: 1=UNWANTED 2=WANTED 3=SETUP 5=source.
  // (00040001 status is read-only on this camera, so WANTED comes via select.)
  void _onGpsSelect(List<int> value) {
    if (value.isEmpty) return;
    switch (value[0]) {
      case 1:
        _gpsWanted = false;
        _cameraWantsLocation = false;
        _log('Camera GPS: not wanted');
      case 2:
        _gpsWanted = true;
        _cameraWantsLocation = true;
        _log('Camera GPS: WANTED — streaming location over BLE');
        _sendGpsEnable();
      case 3:
        _log('Camera GPS: setup');
      case 5:
        _log('Camera GPS source = ${value.length > 1 ? value[1] : -1} (4=phone)');
    }
  }

  /// Real-time location push over BLE (d4.C0501A.G): 20-byte frame to 00040002.
  Future<void> pushLocation(NmeaFix fix) async {
    if (!_gpsWanted || _gpsCommand == null) return;
    final frame = buildBleGpsFrame(
      latitude: fix.latitude,
      longitude: fix.longitude,
      altitude: fix.altitude,
      timeMillis: fix.timeMillis,
    );
    try {
      await _gpsCommand!.write(frame, withoutResponse: true);
    } catch (e) {
      _log('Location push failed: $e');
    }
  }

  void _onDisconnected() {
    for (final s in _valueSubs) {
      s.cancel();
    }
    _valueSubs.clear();
    _register = _auth = _capability = _connInfo = null;
    _gpsCommand = _gpsSelect = null;
    _cameraWantsLocation = false;
    _gpsWanted = false;
    _ready = false;
    _handshaking = false;
    if (!_wantConnection) return;
    // Keep _connSub alive: with autoConnect=true Android re-links when the
    // camera powers on again, and the connectionState listener re-runs the
    // handshake via _onConnected. As a fallback, rescan after a short backoff.
    _log('Disconnected — will reconnect when camera powers on');
    _setState(LinkState.scanning);
    Future.delayed(const Duration(seconds: 20), () async {
      if (_wantConnection && !_ready && _device != null) {
        if (await _device!.connectionState.first !=
            BluetoothConnectionState.connected) {
          await _scanForCamera();
        }
      }
    });
  }

  void dispose() {
    for (final s in _valueSubs) {
      s.cancel();
    }
    _stateController.close();
    _logController.close();
  }
}
