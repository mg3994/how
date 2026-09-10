# 27. Device Info Kit & Hardware Capabilities Integration

## 1. Overview of `device_info_kit`

The `device_info_kit` package (available at `https://github.com/mg3994/device_info_kit` and `dartpub.dev`) is a high-performance system capability inspection plugin written specifically for DartNative using direct C-ABI FFI bindings.

Unlike legacy `device_info_plus` plugins that serialize JSON metadata across asynchronous method channels, `device_info_kit` reads platform hardware registers, device identifiers, memory statistics, and OS build versions **synchronously**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        device_info_kit Architecture                   │
├────────────────────────────────────────────────────────────────────────┤
│  Dart API: DeviceInfoKit.readIosDeviceInfo() / readAndroidDeviceInfo() │
│                     │                                                  │
│                     ▼ Direct C-ABI FFI Call (0ms Latency)             │
│  Native C/Objective-C/C++ Export Interface                             │
│   ├── iOS: `uname()`, `sysctlbyname()`, `UIDevice.currentDevice`       │
│   └── Android: `/system/build.prop`, `android.os.Build`, `/proc/meminfo`│
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Reading iOS Device Metadata Synchronously

```dart
import 'package:dartnative/dartnative.dart';
import 'package:device_info_kit/device_info_kit.dart';

void inspectIosDevice() {
  if (Platform.isIOS) {
    final iosInfo = DeviceInfoKit.getIosDeviceInfo();

    print('Device Model      : ${iosInfo.model}');          // e.g. "iPhone15,2"
    print('System Name       : ${iosInfo.systemName}');     // e.g. "iOS"
    print('System Version    : ${iosInfo.systemVersion}');  // e.g. "17.4"
    print('Is Physical Device: ${iosInfo.isPhysicalDevice}');// true/false
    print('Total RAM (MB)    : ${iosInfo.totalPhysicalMemoryMB}');// e.g. 6144
  }
}
```

---

## 3. Reading Android Device Metadata Synchronously

```dart
import 'package:dartnative/dartnative.dart';
import 'package:device_info_kit/device_info_kit.dart';

void inspectAndroidDevice() {
  if (Platform.isAndroid) {
    final androidInfo = DeviceInfoKit.getAndroidDeviceInfo();

    print('Brand / Manufacturer: ${androidInfo.brand} / ${androidInfo.manufacturer}');
    print('Device Model        : ${androidInfo.model}');       // e.g. "Pixel 8"
    print('Android OS Version  : ${androidInfo.version.release}');// e.g. "14"
    print('SDK Int             : ${androidInfo.version.sdkInt}');// e.g. 34
    print('Supported ABIs      : ${androidInfo.supportedAbis}');// e.g. ["arm64-v8a"]
  }
}
```

---

## 4. Hardware System Capability Matrix

`device_info_kit` exposes unified capability flags across platforms:

```dart
final capabilities = DeviceInfoKit.getCapabilities();

if (capabilities.supportsHaptics) {
  HapticFeedback.vibrate();
}

if (capabilities.isLowRamDevice) {
  // Lower FastList keepAliveCount to save memory on low-tier hardware
  chatListKeepAlive = 10;
}
```
