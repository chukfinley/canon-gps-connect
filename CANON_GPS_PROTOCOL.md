# Canon Camera Connect — GPS/BLE Protocol (reverse-engineered)

Source: decompiled `jp.co.canon.ic.cameraconnect` base.apk (pulled via adb), jadx.
EOS SDK lives in obfuscated `com.canon.eos.*`. GPS logger lives in `i4.*`.

## 1. BLE service / characteristic map

Base UUID pattern: `XXXXYYYY-0000-1000-0000-d8492fffa821`
(note `...-0000-d8492fffa821`, NOT the standard `...-8000-00805f9b34fb`).

Defined in `com.canon.eos.C0224b.onServicesDiscovered`:

| Service UUID                              | Handler | Purpose |
|-------------------------------------------|---------|---------|
| `0000180a-0000-1000-8000-00805f9b34fb`    | std DIS | Device Information (manufacturer/model serial) |
| `00010000-0000-1000-0000-d8492fffa821`    | class T | **Primary / control / pairing / feature flags** — this is the ADVERTISED service used for scanning |
| `00020000-0000-1000-0000-d8492fffa821`    | class B | secondary control |
| `00030000-0000-1000-0000-d8492fffa821`    | class N | **Remote control (shutter) + WiFi handover** |
| `00040000-0000-1000-0000-d8492fffa821`    | class C0299u | **GPS service** |
| `00080000-0000-1000-0000-d8492fffa821`    | class E | (firmware/other) |

### Service 0x0001 (primary) characteristics
- `00010005` r/w  – control
- `0001000a` w    – op-code channel (e.g. auto-power-off prohibit: `[0x0A, 0x01|0x02]`)
- `0001000b` r    – **feature flags bitfield** (int): bit3=0x08, bit4=0x10, bit5=0x20(autopoweroff), bit6=0x40, bit7=0x80(wifi), bit8=0x100, bit9=0x200
- `00010006`, `0001000c`

### Service 0x0004 (GPS) characteristics — `com.canon.eos.C0299u`
- `00040001` read/notify – **status**. `value[0]` bit1 (0x02) set ⇒ camera GPS active/wants location; `value[1]` = capability flags `h`.
- `00040002` write       – **command channel** (app → camera).
- `00040003` read/notify – **GPS source select**. `value[0]`==5 ⇒ select report; `value[1]` = source:
  - `0` DISABLE
  - `1` GPS_RECEIVER
  - `2` BUILTIN_GPS
  - `3` BUILTIN_GPS_POWER_SW_OFF
  - `4` **SMARTPHONE**  ← the mode the app uses

GPS capability flags `h` (from `00040001` value[1]), enum `EnumC0295t`:
`0x01`=DISABLE `0x02`=GPS_RECEIVER `0x04`=BUILTIN_GPS `0x08`=BUILTIN_GPS_POWER_SW_OFF `0x10`=SMARTPHONE

### GPS command writes (to `00040002`)
- Set GPS source mode (`C0276o.I`): write 1 byte `{1}` / `{2}` / `{3}` (index of mode).
- Enable handshake (`C0299u.a`, fired when status `00040001` reports bit1): write 8-byte buffer, `buf[0]=5`, rest 0:
  `[0x05,0,0,0,0,0,0,0]`.

## 2. Location → NMEA encoding  (`i4.j.b(Location)`)

The app converts each Android `Location` into **two NMEA sentences** (GPGGA + GPRMC),
joined, each with XOR checksum, CRLF terminated. This NMEA is what gets logged and
matched to photos.

```
$GPGGA,<hhmmss.000>,<lat ddmm.mmmmm>,<N|S>,<lon dddmm.mmmmm>,<E|W>,1,6,0,<alt>,M,0,M,,*<XX>\r\n
$GPRMC,<hhmmss.000>,A,<lat>,<N|S>,<lon>,<E|W>,<speed>,<bearing>,<ddmmyy>,0,A*<XX>\r\n
```

- Time is **UTC**, from `location.getTime()`.
- lat/lon NMEA format = `degrees*100 + minutes` i.e. `ddmm.mmmmm` (lat 2 int digits, lon 3),
  minutes = (decimal_deg - int_deg) * 60, `%7.5f`, zero-padded.
- Fix quality hard-coded `1`, satellites `6`, HDOP `0`.
- alt `%3.1f` (or `0`), speed `%3.1f` (m/s), bearing `%3.1f`.
- Checksum `XX` = XOR of all bytes between `$` and `*`, uppercase hex `%02X`.

Encoder helper (lat/lon):
```java
// a(deg): int part + ((deg-int)*60 formatted %7.5f), pad to ddmm / dddmm
```

## 3. Location acquisition  (`i4.n.p`)

FusedLocationProvider (`com.google.android.gms.location`):
- priority `100` = PRIORITY_HIGH_ACCURACY
- interval `10000` ms (10 s), fastest `5000` ms (5 s)
- runs inside foreground service `CCGpsLogService` (`foregroundServiceType="location"`).

Each fix → `i4.C0604a.onLocationChanged` → `i4.j.b()` → stored in:
- SQLite `CCGpsLogDatabase.db`, table `CCGpsLogData`
  `(time INTEGER PK, latitude REAL, longitude REAL, altitude REAL, accuracy REAL, speed REAL, bearing REAL, nmea TEXT)`
- table `CCGpsLogTerm (start INTEGER PK, end INTEGER)` — logging session ranges
- also raw NMEA appended to files in `<filesDir>/.geolog/` (re-imported by `i4.l.e()`).
- Dedup rule: a fix replaces an existing same-`time` row only if accuracy is better.

## 3b. REAL-TIME location push over BLE  (`d4.C0501A.G(Location)`)  — BLE-ONLY

**Correction to an earlier assumption: the camera DOES get live coordinates over BLE.**
Method `d4.C0501A.G(Location)` (jadx could not decompile it — recovered via baksmali)
runs on every fix and, when the camera GPS state is WANTED, writes a **20-byte binary
frame** to the GPS command characteristic `00040002` (write-no-response):

```
[0]     0x04  opcode
[1]     lat hemisphere  0x4E 'N' / 0x53 'S'
[2:6]   float32 abs(latitude)   little-endian
[6]     lon hemisphere  0x45 'E' / 0x57 'W'
[7:11]  float32 abs(longitude)  little-endian
[11]    alt sign  0x2B '+' / 0x2D '-' / 0x00 (none)
[12:16] float32 abs(altitude)   little-endian
[16:20] int32 unix time seconds little-endian
```
(NOT the NMEA string — that is only for the WiFi photo-tag path below.)

Gating / state machine (`com.canon.eos.C0299u`):
- Char `00040001` (status) notify, byte0 bit `0x02` set ⇒ camera active ⇒ phone acks with
  the 8-byte handshake `05 00 00 00 00 00 00 00` to `00040002`.
- Char `00040003` (select) notify, byte0: `1`=UNWANTED, `2`=WANTED, `3`=SETUP,
  `5`=source report (byte1: `4`=SMARTPHONE). On **WANTED** the phone streams the 20-byte
  frame on every fix (~5–10 s, fused provider). Phone is GATT **client** throughout — it
  never runs a GATT server and never advertises (verified: zero `BluetoothGattServer` /
  `BluetoothLeAdvertiser` usage in the whole app).

Confirmed against a real EOS 250D btsnoop capture: phone writes `0500000000000000` to the
GPS command handle on every (re)connect.

## 4. Geotagging ALREADY-STORED photos  (`i4.n`)  — the WiFi "match" step

This is a SEPARATE feature (retro-tagging existing shots), not the live link above.
Canon does NOT stream NMEA per-shot for this; instead:
1. Camera connected → app requests captured-object list for a time window:
   `EOSCamera.F0(startDate, endDate, cb)`  (`attachCameraGpsTagObject`).
2. For each returned image object's capture timestamp, app finds nearest GPS-log row.
3. App writes GPS EXIF tags onto the camera's image via EOS command
   (`EOSAattachGpsTagInfoCommand` / `IMLAattachGpsTagInfoCommand`).
   `SDK.GpsInfo { mGPSLatitude, mGPSLatitudeRef, mGPSLongitude, mGPSLongitudeRef,
                  mGPSAltitude, mGPSAltitudeRef, mGPSDateStamp, mGPSTimeStamp, mGPSStatus }`.

### 4a. Transport = ImageLink (IMLink) PTP/IP over WiFi  — NATIVE

`jp.co.canon.android.imagelink.ImageLinkService` is a thin JNI wrapper. Real protocol is
in native libs (present in `split_config.arm64_v8a.apk`):
`libimagelink.so`, `libimagelinkjni.so`, `libEDSDKCore.so`, `libCHHLLite.so`,
`libMyJniUtil.so`, `libic_hevcdec.so`. `System.loadLibrary("imagelink"/"imagelinkjni")`.

Dispatch: `U2.l.d(opcode, payload, respCb, null)` →
- opcode **31** = RequestGpsTagObjectList. payload `ImageLinkService.RequestTimeList(startISO, endISO, 0, 0)`, paged via `setIndex(n+1)`. ISO = `yyyy-MM-dd'T'HH:mm:ss`. Returns objects `(objectHandle, UTCTime)`.
- opcode **33** = AttachGpsTagInfo. payload `ImageLinkService.GPSInformation[]{ new GPSInformation(objectHandle, gpsString) }`.

**Key: `gpsString` (GPSInformation.mGps) IS the raw NMEA string** (`$GPGGA..\r\n$GPRMC..\r\n`)
from the matched log row — see `i4.n.b()` line 283-285: `l02.f4338q = i6.a` (i6 = `i4.j`, `.a` = nmea).
The camera parses NMEA itself to fill GPS EXIF (lat/lon ref + altitude + UTC date/time stamp).

Match logic (`i4.n.b` / `i(time)`): for each photo object UTC time, pick nearest GPS-log
NMEA entry, send via opcode 33.

WiFi handover trigger: BLE service `0x0003` (class N, chars `00030010..00030031`) +
`CCWifiHandOverService` negotiates camera SoftAP SSID/key/IP, phone joins, then IMLink
PTP/IP session over that WiFi.

### 4b. Layer-3 build options (real geotag)
- **(A) Reuse Canon native libs**: bundle the 6 `.so` + recreate the exact JNI Java class
  `jp.co.canon.android.imagelink.ImageLinkService` (2293-line data-class layout must match
  for JNI marshalling) + `nativeCreate(...)` session. Call from Flutter via platform channel.
  Realistic path. (Proprietary binaries — legal gray, technically works.)
- **(B) Reimplement Canon PTP/IP in Dart** from gphoto2 EOS knowledge. Huge, uncertain.
- Photo geotag CANNOT be done BLE-only on these models — it needs the WiFi IMLink session.

## 5. Connection / auto-reconnect / background wake  (`com.canon.eos.C0240f`)

- Scan filter (`startScan`): `ScanFilter.setServiceUuid("00010000-0000-1000-0000-d8492fffa821")`,
  `ScanSettings` scanMode `2` (LOW_LATENCY).
- On match → `connectGatt`, `discoverServices`.
- **Bonding**: after discovery, if `device.getBondState()==BOND_NONE` → `device.createBond()`
  (registers `BOND_STATE_CHANGED` receiver). One-time pairing.
- Auto-reconnect: on `onConnectionStateChange` STATE_DISCONNECTED (status 133/0) →
  `stopScan(); startScan()` (rescan loop). Camera turning on re-advertises 0x0001 ⇒ reconnect.
- Persistence in background: foreground services keep process alive —
  `CCBleConnectService` (`foregroundServiceType="connectedDevice"`) +
  `CCGpsLogService` (`foregroundServiceType="location"`).

## 5c. REGISTRATION + AUTH handshake (REQUIRED before GPS)  — verified vs EOS 250D

The camera ignores the GPS service until the app completes EOS registration/auth.
Handle→UUID from the capture's GATT discovery; opcodes from `com.canon.eos` `T`/`Q`/`S`.

Identity the clone must own:
- **initiator GUID** = 16 bytes, generated once (`UUID.randomUUID`), persisted
  (`AESDKSettings/initiatorGUID`), replayed every connect. Sent as UUID bytes MSB→LSB.
  Camera stores it at first registration; re-advertises a truncated form so the app
  recognises "its" camera. Any stable 16 bytes work.
- **nickname** = free ASCII the app picks + persists (default `NoName`). Shown on the
  camera. The captured device used `"A015"`. Used in register + auth.

Ordered sequence (after connect + Android `createBond`):
```
1. indicate ON  00010005 (state)
2. write 00010006 = 01 <nickname-ascii>        # S.REQUEST register
   indicate ON 00010006 ; await indicate:
     0x02 = S.OK (registered)  0x03 = S.NG (reject -> user must register app on camera)
3. read 0001000b (capability flags)
4. notify/indicate ON all chars of services 0x0002 / 0x0003 / 0x0004
5. write 0001000a (auth, Q enum):
     03 <16-byte GUID>     # Q.UUID
     04 <nickname-ascii>   # Q.NICK_NAME
     05 02                 # Q.TYPE  (constant {5,2})
6. write 00020002 = 0a  -> camera notifies conn/WiFi info (TLV 7f10…, has 192.168 IP)
7. write 0001000a = 01   # Q.SUCCESS (auth complete)
8. camera notifies 00040001 bit1 -> app writes 00040002 = 05 00..00 (8B) ; indicate
   00040003 = 02 (WANTED) -> stream 20-byte frames (§3b).
```
`0001000a` opcode table (Q): 01 SUCCESS, 02 FAILURE, 03 UUID, 04 NICK_NAME, 05 TYPE,
06/07 MODEL_NAME halves, 08 WIFI_FREQ, 0A PROHIBIT_AUTO_POWER_OFF, 0C WIFI_AP_FREQ.

First-pair vs reconnect: camera advertises (manufacturer id 425) — manuf-data len 19
carries the registered app GUID (reconnect), len 6 = register mode. `C0276o.w()` returns
true (needs pairing) when advertised GUID is all-zero; then step 2 runs and the user must
select the app on the camera. Reconnect skips step 2's wait; identity writes (5) re-sent
every time.

## 6. Android manifest essentials (clone needs)

Permissions:
```
ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_BACKGROUND_LOCATION
BLUETOOTH, BLUETOOTH_ADMIN, BLUETOOTH_SCAN, BLUETOOTH_CONNECT
FOREGROUND_SERVICE, FOREGROUND_SERVICE_LOCATION, FOREGROUND_SERVICE_CONNECTED_DEVICE
POST_NOTIFICATIONS
```
Services:
```
location-type FGS  → keeps GPS in background
connectedDevice-type FGS → keeps BLE link in background
```
Note: `BLUETOOTH_SCAN` should NOT set `neverForLocation` here because scan results are
used together with location. Background BLE scan + reconnect requires a running FGS
(or CompanionDeviceManager association to wake from cold-killed state).
