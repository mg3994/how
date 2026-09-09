# 13. `flutter_tools` Modifications & Flutter Zero Core Adaptations

## 1. Overview of `flutter_tools` Rebranding & Architecture

In DartNative (and its underlying Flutter Zero fork), Meta/Google's upstream `packages/flutter_tools` package underwent systemic modification to adapt the CLI from a canvas-painting Flutter framework tool to a platform-native view framework tool (`dn`).

These changes are tagged throughout the `flutter_tools` codebase with annotations like `// rebrand (REBRAND.md P2)` and `// rebrand (docs/zero/TELEMETRY.md)`.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        packages/flutter_tools                          │
├────────────────────────────────────────────────────────────────────────┤
│  Rebranded CLI Entry Point (`bin/flutter_tools.dart` -> `dn`)           │
│  ├── Hidden Legacy Commands (`channel`, `drive`, `downgrade`)          │
│  ├── Added Commands (`dn release`, `dn patch`, `dn plugin sync`)       │
│  ├── Platform Scope Enforcement (iOS + Android active; Desktop hidden)│
│  ├── Zero Telemetry & Crash Reporting Kill Switch                      │
│  ├── Custom Manifest Parsing (`dartnative:` pubspec section)           │
│  └── Automatic Plugin Registrant Generator                             │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Key Codebase Modifications Summary

### 1. Telemetry & Analytics Hard-Off Kill Switch (`src/reporting/`)
Upstream `flutter_tools` collects Google Analytics and crash telemetry by default. DartNative completely disables telemetry:
- `unified_analytics.dart`: `kDartNativeTelemetryEnabled = false` serves as a master kill switch for all tracking.
- `first_run.dart` & `crash_reporting.dart`: Telemetry consent prompts and crash reporting uploading logic are bypassed.

### 2. Platform Scope Restriction
Upstream Flutter supports Web, macOS, Windows, Linux, and Embedded targets. DartNative focuses exclusively on mobile platform perfection:
- `src/commands/create_base.dart`: Mobile target enforcement (`iOS` and `Android` only). Desktop scaffolds and web templates are disabled or hidden from `dn create`.
- `src/commands/create.dart`: Java template option removed; Kotlin and Swift are standard defaults for native scaffolds.

### 3. Rebranded Manifest & Plugin Parsing (`src/flutter_manifest.dart`)
- Rather than looking solely for `flutter:` keys in `pubspec.yaml`, the manifest parser inspects the `dartnative:` section.
- Scans `pubspec.lock` for FFI native plugins declaring `dartnative: plugin` entries and feeds them to the automatic registrant generator (`lib/dartnative_plugin_registrant.dart`).

### 4. Code Push Commands (`src/commands/code_push.dart`)
Adds first-class over-the-air (OTA) code update commands to `flutter_tools`:
- **`dn release [android|ios]`**: Captures AOT kernel snapshots (`.dn_code_push/release_<version>.kernel`), generates version files (`dn_release_version.g.dart`), and uploads release metadata to `dartpub.dev`.
- **`dn patch [android|ios]`**: Computes differential kernel updates against the baseline release snapshot and deploys minimal OTA payloads.

### 5. Private Registry & Package Overrides (`src/dart/pub.dart`)
- Redirects default package resolution to `https://dartpub.dev` (or configured `PUB_HOSTED_URL`).
- Automatically forwards developer authentication tokens (`dnp_…` tokens configured via `dn config --publish-token`).
- Pipes stdio from `pub get` through display-time rebrand filters to reformat output logs from `flutter` to `dn`.

### 6. Native Xcode & Gradle Build Settings (`src/ios/` & `src/android/`)
- `xcode_build_settings.dart`: Replaces `FLUTTER_*` build settings keys with `DN_*` build setting parameters (`DN_ROOT`, `DN_APPLICATION_PATH`, `DN_BUILD_DIR`).
- `gradle_utils.dart`: Writes `dn.*` property definitions into Android `gradle.properties`.
- Disables outdated 32-bit `android-x86` engine artifact downloads, restricting builds to 64-bit modern mobile architectures (`arm64-v8a`, `armeabi-v7a`, `x86_64`).

---

## 3. Comparison Matrix: Upstream `flutter` vs DartNative `dn` CLI

| Feature / Command | Upstream Flutter Tool | DartNative (`dn`) |
|---|---|---|
| **Primary Binary Name** | `flutter` | `dn` |
| **Default CDN Host** | `https://storage.googleapis.com` | `https://cdn.dartnative.com` |
| **Default Package Registry** | `https://pub.dev` | `https://dartpub.dev` |
| **Target Platforms** | Mobile, Web, macOS, Windows, Linux | iOS & Android (Optimized Mobile Focus) |
| **Telemetry / Analytics** | Enabled by default (Google Analytics) | Hard-disabled (`kDartNativeTelemetryEnabled = false`) |
| **Code Push Support** | None (Requires external services) | Built-in (`dn release` & `dn patch`) |
| **Plugin Registration** | MethodChannel Registrars | Static FFI Registrant (`DartNativePluginRegistrant`) |
| **Engine Binaries** | Impeller / Skia Canvas Engine | Yoga Flexbox + Real Platform View Engine |
