# Canon GPS Connect (Flutter)

Clones **only the live GPS geotagging** of Canon Camera Connect: pair once over
Bluetooth, then a persistent background service auto-connects whenever the camera
powers on and streams the phone's location to it over BLE — the camera writes the
GPS into each photo's EXIF as you shoot. **Bluetooth only, no WiFi.**

Protocol reverse-engineered from the official APK and verified byte-for-byte against
a real EOS 250D Bluetooth capture. See `../CANON_GPS_PROTOCOL.md`.

## What it does
- **Pair once.** First connect registers the app on the camera (camera in "register
  device" mode); a persisted GUID + flag means every later connect is automatic.
- **Background service.** A foreground service (`flutter_foreground_task`, types
  `location` + `connectedDevice`) keeps the BLE link alive when the app is
  backgrounded or swiped away, and auto-starts on boot. The camera is detected and
  handled automatically when it powers on.
- **Battery-friendly.** The BLE link is cheap and stays connected to detect the
  camera; the GPS (the expensive part) runs **only while the camera asks for it**
  and stops the moment it doesn't.
- **Adjustable rate.** GPS update interval is user-selectable (1 / 3 / 5 / 10 / 30 / 60 s).
- **NMEA log** of every fix is kept in SQLite (Canon `CCGpsLogData` schema).

## How the BLE GPS works (verified)
1. Scan matches Canon **manufacturer id 425 (0x01A9)**.
2. Connect + bond, then the EOS **registration + auth** handshake (control service
   `00010000`: register on `00010006`, auth opcodes on `0001000a` — persisted 16-byte
   GUID + nickname).
3. Camera signals **WANTED** on `00040003`; the app streams a **20-byte binary frame**
   (`buildBleGpsFrame`) to `00040002` on every fix: `0x04`, N/S, float32 LE lat, E/W,
   float32 LE lon, alt sign, float32 LE alt, int32 LE unix-seconds.

## Layout
```
lib/
  main.dart                    thin UI: status, start/stop, rate selector, logs
  settings.dart                persisted interval + nickname
  service/canon_task_handler.dart   foreground-service isolate: owns BLE + GPS
  ble/canon_ble.dart           scan / pair-once / auth handshake / live GPS push
  gps/gps_service.dart         on-demand location stream (configurable interval)
  gps/nmea.dart                NMEA encoder + 20-byte BLE GPS frame
  gps/log_db.dart              SQLite NMEA log (Canon schema)
```

## Run
```bash
flutter pub get
flutter run
```
First launch: grant **Location → Allow all the time**, **Nearby devices**, and allow
the battery-optimisation exemption. Put the camera in "connect to smartphone → register
device" mode, tap **Start**. After that it reconnects and tracks on its own whenever the
camera turns on.

> Note: GPS geotagging here is **Bluetooth-only** (live, as you shoot). The official
> app's separate "tag photos already on the card over WiFi" feature is **not** included.
