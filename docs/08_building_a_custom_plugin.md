# 08. Building a Custom Native FFI Plugin

## 1. Plugin Architecture & Structure

In DartNative, custom plugins do not use legacy Flutter `MethodChannel` binary messengers. Instead, plugins rely on direct C-ABI foreign function interfaces (FFI).

A DartNative plugin package structure follows standard Dart pub convention with native source directories:

```
my_custom_sensor/
├── pubspec.yaml
├── lib/
│   ├── my_custom_sensor.dart                  # High-level Dart public API
│   └── src/
│       └── my_custom_sensor_bindings.g.dart   # FFI function pointers
├── ios/
│   ├── my_custom_sensor.podspec
│   └── Classes/
│       └── MyCustomSensorPlugin.m              # Objective-C / C ABI wrapper
├── android/
│   ├── build.gradle
│   └── src/main/cpp/
│       └── my_custom_sensor.cpp               # C/C++ JNI / C ABI implementation
└── example/                                   # Example test app
```

---

## 2. Step 1: Native C-ABI Interface (`ios/Classes` & `android/cpp`)

Every plugin exposes C-compatible functions (`extern "C"`) that can be invoked directly by Dart FFI pointers.

### iOS Objective-C / C implementation (`ios/Classes/MyCustomSensorPlugin.m`)

```objc
#import <Foundation/Foundation.h>

// Export C-ABI functions with C linkage
__attribute__((visibility("default"))) __attribute__((used))
int32_t ReadBatteryLevelPercent(void) {
    #if TARGET_OS_SIMULATOR
    return 100;
    #else
    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    float level = UIDevice.currentDevice.batteryLevel;
    if (level < 0) return -1;
    return (int32_t)(level * 100);
    #endif
}

__attribute__((visibility("default"))) __attribute__((used))
int32_t PerformFastAddition(int32_t a, int32_t b) {
    return a + b;
}
```

### Android C/C++ implementation (`android/src/main/cpp/my_custom_sensor.cpp`)

```cpp
#include <stdint.h>

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int32_t ReadBatteryLevelPercent() {
    // Direct Linux/Android system call or JNI bridge call
    return 85;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int32_t PerformFastAddition(int32_t a, int32_t b) {
    return a + b;
}
```

---

## 3. Step 2: High-Level Dart FFI Bindings (`lib/my_custom_sensor.dart`)

The Dart library opens the dynamic library (`DynamicLibrary.process()` or `DynamicLibrary.open()`) and resolves function symbols into typed Dart function handles.

```dart
import 'dart:ffi';
import 'dart:io';

// 1. Define C function signatures
typedef ReadBatteryC = Int32 Function();
typedef ReadBatteryDart = int Function();

typedef AddC = Int32 Function(Int32 a, Int32 b);
typedef AddDart = int Function(int a, int b);

class MyCustomSensor {
  static final DynamicLibrary _nativeLib = _openNativeLibrary();

  static DynamicLibrary _openNativeLibrary() {
    if (Platform.isIOS || Platform.isMacOS) {
      return DynamicLibrary.process(); // Symbols statically linked in process
    } else if (Platform.isAndroid) {
      return DynamicLibrary.open('libmy_custom_sensor.so');
    }
    throw UnsupportedError('Unsupported operating system');
  }

  // 2. Resolve native symbols
  static final ReadBatteryDart _readBattery = _nativeLib
      .lookup<NativeFunction<ReadBatteryC>>('ReadBatteryLevelPercent')
      .asFunction<ReadBatteryDart>();

  static final AddDart _fastAdd = _nativeLib
      .lookup<NativeFunction<AddC>>('PerformFastAddition')
      .asFunction<AddDart>();

  // 3. Expose clean Dart public API
  static int getBatteryLevel() {
    return _readBattery();
  }

  static int add(int a, int b) {
    return _fastAdd(a, b);
  }

  static void registerWith() {
    // Mandatory registration hook called by DartNativePluginRegistrant
  }
}
```

---

## 4. Step 3: `pubspec.yaml` Configuration

Configure `pubspec.yaml` to notify `dn` CLI that this package contains a native DartNative plugin:

```yaml
name: my_custom_sensor
description: A high-performance native sensor plugin for DartNative.
version: 1.0.0
homepage: https://dartpub.dev

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  dartnative: ^1.0.0

dartnative:
  plugin:
    platforms:
      ios:
        pluginClass: MyCustomSensor
      android:
        package: com.example.my_custom_sensor
        pluginClass: MyCustomSensor
```

---

## 5. Asynchronous Native Callbacks (Isolate Ports)

When native code needs to send async events back to Dart (e.g. sensor data streams), use `Dart_PostCObject` with a `NativePort`:

```c
#include "dart_api_dl.h"

// Native thread posts event to Dart ReceivePort
void StreamSensorDataToDart(Dart_Port port_id, float x, float y, float z) {
    Dart_CObject obj;
    obj.type = Dart_CObject_kArray;
    // Pack sensor values and post to Dart Isolate Port synchronously
    Dart_PostCObject_DL(port_id, &obj);
}
```

On the Dart side:
```dart
final receivePort = ReceivePort();
receivePort.listen((message) {
  print('Sensor update received: $message');
});

// Pass native port ID to C function
startSensorStream(receivePort.sendPort.nativePort);
```
