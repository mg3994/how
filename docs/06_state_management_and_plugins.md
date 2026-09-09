# 06. State Management, FFI Plugins & Migration Playbook

## 1. Modern State Management Primitives

In addition to standard Flutter `setState()`, DartNative ships lightweight reactive state primitives built directly into the framework core:

### Reactive Signals (`signal<T>`)

`signal<T>` creates a fine-grained observable value container. Calling `.watch(context)` inside a widget `build()` method binds that specific element to value changes:

```dart
import 'package:dartnative/dartnative.dart';

class CounterStore {
  final count = signal<int>(0);
  void increment() => count.value++;
}

final store = CounterStore();

class CounterTextWidget extends StatelessWidget {
  const CounterTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Repaints ONLY this widget when store.count updates
    final currentCount = store.count.watch(context);
    return Text('Count: $currentCount');
  }
}
```

### Dependency Injection (`Provided<T>`)

`Provided<T>` passes values down a widget subtree without requiring external state management packages:

```dart
// 1. Provide value
Provided<UserSession>(
  value: currentSession,
  child: const DashboardScreen(),
);

// 2. Consume in descendant
class DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = Provided.of<UserSession>(context);
    return Text('Welcome back, ${session.username}');
  }
}
```

---

## 2. FFI-Based Plugin Architecture vs Legacy MethodChannels

Legacy Flutter plugins communicate with native platforms via asynchronous `MethodChannel` binary messengers:

```
Flutter Legacy MethodChannel:
  Dart Object ──> Message Serializer ──> Binary Messenger Thread ──> Platform Channel ──> Native Execution

DartNative FFI Direct Calls:
  Dart Function ────── Direct Synchronous C/C++ FFI Function Pointer ──────> Native Execution
```

### Advantages of FFI Plugins
1. **Zero Serialization Overhead**: Data passes directly in C memory buffers (`Pointer<NativeType>`), eliminating JSON or StandardMessageCodec string conversions.
2. **Synchronous Execution**: Synchronous platform APIs (e.g., Keychain reads, SQLite queries, system status checks) return results immediately in the current thread turn without `Future` or `async/await` microtask delays.
3. **Isolate Port Callback Support**: Asynchronous platform callbacks (e.g., camera frame streams, audio buffers, location updates) post messages directly to Dart `ReceivePort` handles.

---

## 3. First-Party Plugin Catalog

DartNative provides first-party FFI plugins available via `https://dartpub.dev`:

| Category | Plugin Package | Functionality & Native Lowering |
|---|---|---|
| **Storage & DB** | `dartnative_sqlite` | Embedded SQLite C engine with direct FFI bindings |
| | `dartnative_shared_preferences` | Native `NSUserDefaults` / `SharedPreferences` |
| | `dartnative_secure_storage` | Hardware Keychain (iOS) / EncryptedSharedPreferences (Android) |
| **Media & Audio** | `dartnative_video_player` | Hardware `AVPlayer` (iOS) / `ExoPlayer` (Android) |
| | `dartnative_audio` | Real-time PCM audio streaming, playback & recording |
| | `dartnative_camera` | Native `AVCaptureSession` / `Camera2` stream binding |
| | `dartnative_lottie` | Native CoreAnimation / Lottie Android rendering |
| **Platform Services** | `dartnative_social_sign_in` | Native Sign in with Apple & Google Sign-In |
| | `dartnative_notifications` | `UserNotifications` / `NotificationManager` |
| | `dartnative_google_maps` | Native `GMSMapView` / `MapView` view integration |
| **Intelligence & AI**| `dartnative_onnxruntime` | On-device ML inference (CoreML / NNAPI backends) |
| | `dartnative_supertonic_tts` | Offline neural Text-To-Speech (31 languages) |

---

## 4. Flutter-to-DartNative Migration Playbook

### Step 1: Package Replacement Matrix

Replace legacy MethodChannel Flutter packages in `pubspec.yaml` with their DartNative FFI equivalents:

| Flutter Package | DartNative Replacement |
|---|---|
| `sqflite` | `dartnative_sqlite` |
| `shared_preferences` | `dartnative_shared_preferences` |
| `flutter_secure_storage` | `dartnative_secure_storage` |
| `video_player` | `dartnative_video_player` |
| `camera` | `dartnative_camera` |
| `url_launcher` | `dartnative_url_launcher` |
| `share_plus` | `dartnative_share` |
| `google_maps_flutter` | `dartnative_google_maps` |

### Step 2: Code Import Updates
In all Dart files, swap framework imports:

```dart
// Remove
import 'package:flutter/material.dart';

// Replace with
import 'package:dartnative/dartnative.dart';
```

### Step 3: Entry Point Initialization
In `main.dart`, ensure plugin registration precedes app startup:

```dart
import 'package:dartnative/dartnative.dart';
import 'dartnative_plugin_registrant.dart';

void main() {
  // MUST be first line to register FFI plugin bindings
  DartNativePluginRegistrant.registerAll();

  runApp(const MainScreen());
}
```
