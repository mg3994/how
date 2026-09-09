# 07. End-to-End Application Building & Compilation Pipeline

## 1. Overview of the Compilation Pipeline

Building a DartNative application involves two main compilation stages:
1. **Dart Code Compilation**: Transforming Dart source files into executable code (either Kernel Dil bytecode for JIT Debug or target AOT Assembly/Machine code for Release).
2. **Native Platform Bundling**: Linking the compiled Dart runtime payload with the C++ DartNative Engine, Yoga Flexbox engine, and native iOS/Android shell projects via Xcode or Gradle.

```
┌─────────────────────────┐
│   Dart Source Code      │
│   (lib/main.dart + …)   │
└────────────┬────────────┘
             │
             ├─── JIT Debug Mode ────> Frontend Compiler (DDC) ───> App.dill (Kernel Payload)
             │                                                          │
             └─── AOT Release Mode ──> Dart AOT Compiler ──────────> App.so / App.framework (Native Machine Code)
                                                                        │
                                                                        ▼
                                                         ┌───────────────────────────────┐
                                                         │ Platform Native Build System  │
                                                         │ (xcodebuild / gradle assemble)│
                                                         └──────────────┬────────────────┘
                                                                        │
                                                                        ▼
                                                         ┌───────────────────────────────┐
                                                         │ Final Application Binary      │
                                                         │ (.ipa / .apk / .aab)          │
                                                         └───────────────────────────────┘
```

---

## 2. Debug Build Mechanics & Hot Reload Pipeline

In Debug mode (`dn run`), build speed and developer feedback loops are prioritized:

1. **Incremental Frontend Compilation**: The Dart Frontend Compiler (`frontend_server.dart.snapshot`) compiles the application source into incremental `.dill` kernel bytecode files.
2. **VM Service & Hot Reload**:
   - The Dart VM runs in JIT (Just-In-Time) mode with the VM Service protocol enabled (WebSocket connection).
   - When code is modified, `dn` sends an incremental kernel diff over the VM Service connection.
   - The Dart VM updates class definitions and method implementations in place.
   - DartNative triggers a top-level widget element re-evaluation on the main UI thread, preserving state while instantly refreshing host platform views.

---

## 3. iOS Release Build Lifecycle (`dn build ios` / `dn build ipa`)

Building a production iOS binary (`.ipa` or `.framework`) executes the following sequential steps:

```
  dn build ios
      │
      ├──> 1. Plugin Registrant Generation (lib/dartnative_plugin_registrant.dart)
      │
      ├──> 2. CocoaPods Dependency Resolution (podhelper.rb -> pod install)
      │
      ├──> 3. Dart AOT Compilation (gen_snapshot)
      │       ├── Inputs: lib/main.dart, pubspec dependencies
      │       └── Output: App.framework (containing arm64 assembly machine code)
      │
      ├──> 4. Xcode Project Compilation (xcodebuild)
      │       ├── Compiles Runner.xcodeproj, Swift/ObjC delegates
      │       ├── Embeds DartNativeEngine.framework and App.framework
      │       └── Signs app bundle with Apple Code Signing Certificate
      │
      └──> 5. Output: build/ios/iphoneos/Runner.app (or build/ios/ipa/App.ipa)
```

### Xcode Build Integration (`xcode_backend.sh`)
Inside Xcode build phases, DartNative injects `xcode_backend.sh` script invocations to automate artifact compilation:
- **`xcode_backend.sh build`**: Invokes `gen_snapshot` with parameters tailored to the target iOS architecture (`--snapshot_kind=app-aot-assembly`, `--abi=arm64`).
- **`xcode_backend.sh embed`**: Copies `App.framework` and native dynamic libraries into `Runner.app/Frameworks/` and signs them.

---

## 4. Android Release Build Lifecycle (`dn build apk` / `dn build appbundle`)

Building a production Android binary (`.apk` or `.aab`) executes:

```
  dn build apk
      │
      ├──> 1. Plugin Registrant Generation
      │
      ├──> 2. Dart AOT Compilation (gen_snapshot)
      │       ├── Target ABIs: arm64-v8a, armeabi-v7a, x86_64
      │       └── Output: libapp.so (shared object ELF binaries per ABI)
      │
      ├──> 3. Gradle Tasks Execution (./gradlew assembleRelease)
      │       ├── Executes draft-gradle-plugin tasks
      │       ├── Packages libapp.so into lib/<abi>/ inside APK
      │       ├── Bundles C++ DartNative Engine (`libdartnative.so`) and Yoga (`libyoga.so`)
      │       └── Applies R8/ProGuard code shrinking and bytecode optimization
      │
      └──> 4. Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 5. Artifact Comparison: Debug vs Release Payload

| Metric / Attribute | Debug Mode (`dn run`) | Release Mode (`dn build`) |
|---|---|---|
| **Dart Runtime** | Dart VM JIT (Just-In-Time) + Mirror/Reflect Support | Dart VM AOT (Ahead-Of-Time) Strip-Optimized |
| **Dart Binary Format** | `.dill` Kernel Bytecode Payload (~5-10MB) | Native `.so` / `.framework` Machine Code |
| **Hot Reload Support** | Enabled via VM Service WebSockets | Disabled |
| **Symbol Stripping** | Preserved with full debug symbols and stack traces | DWARF debug symbols stripped (saved to separate `.dSYM`) |
| **App Startup Time** | ~1.2s - 2.0s (VM boot & JIT warmup) | ~150ms - 300ms (Cold start directly into main UI) |
