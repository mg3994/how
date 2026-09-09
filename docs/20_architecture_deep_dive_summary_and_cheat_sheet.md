# 20. Architecture Deep-Dive Summary & Developer Cheat Sheet

## 1. Executive Summary & Framework Comparison

| Metric / Dimension | Flutter (Impeller/Skia) | React Native (Fabric) | DartNative |
|---|---|---|---|
| **UI Primitives** | Custom Painted Pixels on Canvas | Native Views (`UIView` / `View`) | **Native Views (`UIView` / `View`)** |
| **Execution Thread** | Multi-threaded (UI thread / Raster thread) | Multi-threaded (JS / Shadow Tree / UI) | **Single-Threaded Main UI Loop** |
| **Layout Engine** | RenderObject Box Constraints | Yoga C++ (Shadow Tree) | **Yoga C++ (Direct View Mounting)** |
| **Layout Complexity** | $O(n^2)$ worst-case | $O(n)$ linear | **$O(n)$ linear** |
| **Bridge Overhead** | BinaryMessenger / MethodChannels | JSI (C++ serialization) | **Zero (Direct C-ABI Synchronous FFI)** |
| **Idle Memory Footprint** | ~62 MB | ~88 MB | **~22 MB** |
| **Cold Startup Latency** | ~420 ms | ~580 ms | **~190 ms** |

---

## 2. `dn` CLI Commands Cheat Sheet

```bash
# Environment & Setup
dn doctor                 # Diagnoses environment dependencies (Xcode, Android SDK, CocoaPods)
dn create my_app          # Scaffolds new DartNative app with native iOS/Android projects

# Development & Execution
dn run                    # Builds and launches app on device/emulator with Hot Reload
dn clean                  # Deletes build artifacts and temporary kernel caches
dn pub get                # Resolves packages and regenerates dartnative_plugin_registrant.dart

# Production Builds & Code Push
dn build ipa              # Compiles iOS release IPA binary
dn build apk              # Compiles Android release APK binary
dn release ios            # Records release baseline kernel artifact for Code Push
dn patch ios              # Generates and uploads signed OTA patch to dartpub.dev
```

---

## 3. Quick Flutter-to-DartNative API Cheat Sheet

```dart
// 1. Imports
import 'package:flutter/material.dart';      // REMOVE
import 'package:dartnative/dartnative.dart'; // USE THIS

// 2. Main Entry Point
void main() {
  DartNativePluginRegistrant.registerAll(); // MUST BE LINE 1
  runApp(const HomeScreen());              // Pass screen directly
}

// 3. Reactive State
final count = signal<int>(0);
Widget build(BuildContext context) {
  final current = count.watch(context);     // Subscribes element to signal updates
  return Text('$current');
}

// 4. Keyboard Sticky Input Bar
Scaffold(
  body: FastList(...),
  bottomInputBar: ChatInputBar(),            // Binds to native IME animation curve
)
```
