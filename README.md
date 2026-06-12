# Canon GPS Connect (Flutter)

A focused clone of **only the GPS feature** of Canon Camera Connect: pair once over
Bluetooth, keep GPS running in the background, auto-reconnect when the camera powers on,
and geotag the photos already on the camera — the GPS string sent is the **raw NMEA**,
exactly like the official app (parsed by the camera into EXIF on-device).

Protocol reverse-engineered from the official APK — see `../CANON_GPS_PROTOCOL.md`.

## How Canon's GPS actually works (the important bit)
- **Bluetooth** = wake + auto-connect + GPS-mode handshake (camera on → phone reconnects).
- **WiFi (IMLink / PTP-IP)** = the actual photo geotagging. Camera opens its SoftAP, phone
  joins, app asks for captured-photo list (opcode 31), matches each photo's UTC capture
  time to the nearest logged NMEA fix, and writes it back (opcode 33). Tag lands in the
  photo EXIF on the SD card.
- The per-photo GPS payload **is the NMEA string** (`$GPGGA…\r\n$GPRMC…\r\n`). Verbatim
  port in `lib/gps/nmea.dart` (from Canon `i4.j`).

## Status
| Layer | What | State |
|-------|------|-------|
| 1 | Pair once, background GPS foreground-service, auto-reconnect on camera power-on | built |
| 2 | NMEA log → SQLite (`CCGpsLogData`, exact Canon schema + dedup) | built |
| 3 | WiFi IMLink geotag via Canon native libs (op31 list, op33 attach, timestamp match) | built + compiles; needs live-camera verification |

### Layer 3 remaining (needs the physical camera)
- **BLE→WiFi handover**: trigger over BLE service `0x0003` to get the camera SoftAP
  SSID/key/IP, then auto-join (`WifiNetworkSpecifier`). Today: join the camera WiFi
  manually, then tap "Geotag photos now".
- Verify `nativeCreate` device-info args + capture-time timezone offset (`btsnoop` / EDSDK log).

## Native dependency (Layer 3)
Layer 3 reuses Canon's own native transport (no PTP/IP reimplementation):
`libimagelink.so`, `libimagelinkjni.so`, `libEDSDKCore.so`, `libCHHLLite.so`,
`libMyJniUtil.so` in `android/app/src/main/jniLibs/arm64-v8a/`, driven through the exact
JNI wrapper `jp.co.canon.android.imagelink.ImageLinkService` (copied from the decompiled
app). **arm64 only.** Proprietary Canon binaries — for personal/research use.

## Layout
```
lib/
  gps/nmea.dart        NMEA encoder (port of i4.j)
  gps/log_db.dart      SQLite log store (i4.l schema)
  gps/gps_service.dart background location stream (HIGH_ACCURACY, 10s)
  ble/canon_ble.dart   scan(0x0001)/connect/bond/auto-reconnect + GPS service 0x0004
  geotag/geotag_sync.dart  Layer-3 orchestration over the platform channel
android/app/src/main/
  java/jp/co/canon/android/imagelink/ImageLinkService.java   Canon JNI wrapper
  kotlin/.../ImageLinkBridge.kt   native IMLink session (op31/op33)
  kotlin/.../MainActivity.kt      MethodChannel canon_gps_connect/imagelink
```

## Run
```bash
flutter pub get
flutter run            # arm64 device
```
First launch: grant Location (allow **all the time**) + Nearby devices, tap **Start**,
turn the camera on → it pairs once, then auto-reconnects on every power-on.
