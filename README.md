# DartNative Deep-Dive Technical Documentation & Internal Architecture Guide

Copyright (c) 2026 Presence Network Inc. All rights reserved.
*DartNative (https://dartnative.com) is a product of Presence Network Inc.*

---

## Executive Summary

**DartNative** is a next-generation cross-platform mobile framework developed by Presence Network Inc. It combines the expressive Dart programming language and Flutter-like declarative UI widget hierarchy with direct native platform UI primitives (`UIKit` on iOS, `Android Views` on Android) laid out via Meta's **Yoga Flexbox** engine.

Unlike traditional Flutter—which bypasses platform UI controls by painting pixels onto a GPU raster canvas using Skia/Impeller—and unlike React Native—which manages native views through asynchronous bridge serialized queues—DartNative runs everything synchronously on the platform's main UI thread. A Dart `setState()` call diffs the Dart widget tree, updates native UI views (`UIView`, `UILabel`, `UIScrollView`, `TextView`, `RecyclerView`), computes CSS flexbox layout via Yoga, and commits the frame in a single synchronous call stack before the next VSYNC.

---

## Architecture At A Glance

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Your Dart Application Code                      │
│            (Scaffold, Column, Text, FastList, signal<T>, setState)     │
├────────────────────────────────────────────────────────────────────────┤
│                           DartNative Core                              │
│      · Diffs Dart widget elements against platform view targets        │
│      · Direct synchronous C/C++ FFI bindings to platform APIs           │
├────────────────────────────────────────────────────────────────────────┤
│                       Native UI & View Platform                        │
│   iOS (UIKit): UIView, UILabel, UITextField, UIScrollView, UITableView │
│   Android: View, TextView, EditText, ScrollView, RecyclerView      │
├────────────────────────────────────────────────────────────────────────┤
│                     Yoga Flexbox Layout Engine                         │
│            (Computes O(n) linear tree layouts synchronously)            │
├────────────────────────────────────────────────────────────────────────┤
│                     Platform GPU Frame Compositor                      │
└────────────────────────────────────────────────────────────────────────┘
          ▲ EVERYTHING EXECUTES SYNCHRONOUSLY ON MAIN UI THREAD ▲
```

---

## Technical Documentation Suite (Master Index)

This directory contains deep-dive internal architecture specifications, mechanics breakdowns, and implementation playbooks:

1. [**Overview & Architecture Mechanics**](docs/01_overview_and_architecture.md)
   - Detailed execution model: Main UI Thread synchronicity without bridges.
   - Theoretical comparison: Flutter (Canvas Painting) vs React Native (Shadow Tree) vs DartNative (Direct Native View Mapping).
   - Embedded Dart VM & Flutter Zero runtime roots.
   - Licensing, framework token governance, and 90-day BSD 3-Clause Sunset Commitment.

2. [**`dn` CLI Tooling & Engine Lifecycle**](docs/02_dn_cli_and_tooling.md)
   - CLI execution flow: `/bin/dn`, `bin/internal/shared.sh`, and `packages/flutter_tools`.
   - SDK layout, engine artifact caching (`~/zero/bin/cache`), and `engine.version` pins.
   - Dynamic plugin registration (`DartNativePluginRegistrant.registerAll()`).
   - Code Push architecture (`dn release`, `dn patch`, `.dn_code_push/`).
   - Complete CLI command reference guide.

3. [**Rendering & Layout Pipeline**](docs/03_rendering_and_layout_pipeline.md)
   - Widget → Element → Platform View lifecycle.
   - Yoga Flexbox O(n) layout solver vs Apple Auto Layout O(n²) constraint solver.
   - Property diffing, minimal view mutation, and layout invalidation dirty flags.
   - CoreGraphics & Android Canvas painting vs optional Skia acceleration (`dartnative_skia` & SkSL shaders).

4. [**iOS & Android Platform Mechanics**](docs/04_android_and_ios_build_mechanics.md)
   - **iOS Deep Dive**: `DartNativeAppDelegate`, `DartNativeSceneDelegate`, CocoaPods `podhelper.rb`, and iOS 26 Liquid Glass rendering.
   - **Android Deep Dive**: Gradle integration, native view lowering, Material 3, and Dynamic Color / Material You.
   - **IME Input Choreography**: Synchronous frame-by-frame keyboard height matching via `Scaffold.bottomInputBar`.

5. [**High-Performance Scroll Recycling & Fast Widgets**](docs/05_scroll_recycling_and_fast_widgets.md)
   - `ListView` (Static Scroll) vs `FastList` (`UITableView` / `RecyclerView` Recycling).
   - View cell recycling mechanics and `keepAliveCount` sliding window.
   - Image decode memory management (`Image.cacheWidth`/`cacheHeight`).
   - `FastGrid` & `MasonryFastGrid` staggered collection views.
   - Programmatic native scrolling using `FastListController`.

6. [**State Management, FFI Plugins & Migration Playbook**](docs/06_state_management_and_plugins.md)
   - State primitives: `setState`, `signal<T>`, `.watch(context)`, `Provided<T>`, and `ChangeNotifier`.
   - FFI-based Plugin Architecture: C/C++ native bindings and thread isolate ports vs MethodChannel overhead.
   - Comprehensive first-party plugin ecosystem catalog (`dartnative_sqlite`, `dartnative_video_player`, `dartnative_camera`, etc.).
   - Flutter-to-DartNative migration guide and package replacement matrix.

7. [**End-to-End Application Building & Compilation Pipeline**](docs/07_end_to_end_app_building_and_compilation.md)
   - JIT Debug mode vs AOT Release mode compilation mechanics.
   - `gen_snapshot` parameters, `App.framework`, and `libapp.so` binary layout.
   - Platform build system integration (`xcode_backend.sh` & `draft-gradle-plugin`).
   - Debug vs Release binary payload, symbol stripping, and cold start performance.

8. [**Building a Custom Native FFI Plugin**](docs/08_building_a_custom_plugin.md)
   - Directory structure for custom native FFI plugins.
   - Writing C-ABI interface wrappers in Objective-C (iOS) and C/C++ (Android).
   - Dynamic library symbol resolution in Dart using `DynamicLibrary.process()`.
   - Synchronous FFI bindings vs async event streaming using Dart Isolate Ports (`Dart_PostCObject`).

9. [**Practical App Walkthrough: Real-Time Chat & Media App**](docs/09_practical_app_walkthrough_chat_screen.md)
   - Complete production-grade application architecture.
   - Integration of `FastList` recycling, `Scaffold.bottomInputBar` keyboard animation tracking, and iOS 26 Liquid Glass.
   - Local persistence via `dartnative_sqlite` and offline speech using `dartnative_supertonic_tts`.

10. [**Debugging, Logging & Hot Reload Architecture**](docs/10_debugging_logging_and_hot_reload.md)
    - Hot Reload vs Hot Restart internal execution pipelines.
    - Embedded Dart VM Service WebSocket protocol and DevTools integration.
    - Native platform logging hooks (`NSLog` / `android.util.Log`).
    - Debug troubleshooting matrix for white screen, layout, and plugin issues.

11. [**Advanced Media & Hardware Platform Integration**](docs/11_advanced_media_and_hardware_integration.md)
    - Hardware camera stream embedding (`dartnative_camera`).
    - Hardware-accelerated video playback (`dartnative_video_player`).
    - Vector Lottie animations (`dartnative_lottie`), Google Maps (`dartnative_google_maps`), and Social Sign-In (`dartnative_social_sign_in`).

12. [**Low-Level Custom Graphics & Skia Runtime Shaders**](docs/12_native_canvas_and_skia_shaders.md)
    - CoreGraphics & `android.graphics.Canvas` context drawing (`CustomPaint`).
    - GPU Skia engine integration (`CanvasSurface` & `dartnative_skia`).
    - Custom SkSL runtime fragment shaders (`RuntimeEffect`).

13. [**`flutter_tools` Modifications & Flutter Zero Core Adaptations**](docs/13_flutter_tools_and_zero_modifications.md)
    - Analysis of modifications inside `packages/flutter_tools`.
    - Telemetry kill switches, mobile scope restriction, and manifest rebrand parsing (`dartnative:` section).
    - Code Push CLI integration, private registry overrides (`dartpub.dev`), and `DN_*` build setting parameters.

14. [**Internal FFI Bridge & Memory Management**](docs/14_internal_ffi_bridge_and_memory_management.md)
    - Low-level C/C++ FFI pointer mechanics and `Pointer<Void>` handles.
    - Memory lifecycle synchronization: Dart GC vs Native ARC Reference Counting.
    - `NativeFinalizer` safety nets and zero-copy buffer passing (`Pointer<Uint8>`).

15. [**Deep Dive: Flutter Zero & Engine Fork Architecture**](docs/15_deep_dive_flutter_zero_and_engine_fork.md)
    - Stripping Flutter's Impeller/Skia LayerTree and DisplayList rasterizers.
    - Engine binary size savings (~4MB stripped core).
    - Window attachment and `DartNativeViewController` / `DartNativeActivity` mounting.

16. [**Performance Benchmarks & Profiling Analysis**](docs/16_performance_benchmarks_and_profiling.md)
    - Cold start latency (~190ms) and idle memory footprint benchmarks (~22MB RAM).
    - 60Hz / 120Hz ProMotion VSYNC frame pacing budget analysis (3.6ms per frame).
    - Memory profiling best practices and Native Instruments profiling.

17. [**Troubleshooting Guide & Common Pitfalls**](docs/17_troubleshooting_and_common_pitfalls.md)
    - Comprehensive troubleshooting matrix for white screens, FFI symbol lookup errors, and keyboard overlaps.
    - White screen decision tree diagnostic flow.
    - iOS project surgery checklist for in-place Flutter app migrations.

18. [**Native Accessibility & Internationalization (l10n)**](docs/18_internationalization_and_accessibility.md)
    - Native platform accessibility lowering (VoiceOver & TalkBack) with zero virtual bridge overhead.
    - Multi-language localization pipeline via `dartnative_intl` and ARB files.
    - Dynamic font registration using `DartNativeFontRegistrant`.

19. [**Security, Sandboxing & Code Signing Architecture**](docs/19_security_sandboxing_and_code_signing.md)
    - OS application sandboxing boundaries on iOS and Android.
    - Hardware security storage using `dartnative_secure_storage` (Keychain & KeyStore).
    - Cryptographic Ed25519 patch signature verification for Code Push OTA updates.

20. [**Architecture Deep-Dive Summary & Developer Cheat Sheet**](docs/20_architecture_deep_dive_summary_and_cheat_sheet.md)
    - Consolidated framework comparison matrix (DartNative vs Flutter vs React Native).
    - `dn` CLI command reference cheat sheet.
    - Quick Flutter-to-DartNative API migration reference table.

21. [**Custom Native Views & Platform View Embedding**](docs/21_custom_native_views_and_platform_views.md)
    - Zero-layer platform view embedding inside Yoga flexbox trees using `PlatformView`.
    - Writing custom Swift/Objective-C view factories and native gesture touch event routing.

22. [**Testing & CI/CD Automation Pipelines**](docs/22_testing_and_ci_cd_pipelines.md)
    - Testing hierarchy (Unit testing, signal store testing, element reconciliation tests).
    - Automated `dn test` and `dn build` verification workflows.
    - GitHub Actions CI/CD configuration YAML for automated DartNative builds.

---

## Getting Started

To install the SDK and run your first application:

```bash
# 1. Install the SDK to ~/zero and add bin/ to PATH
curl -fsSL https://cdn.dartnative.com/install.sh | sh

# 2. Add ~/zero/bin to your active shell path
export PATH="$HOME/zero/bin:$PATH"

# 3. Create a new DartNative project
dn create my_app

# 4. Run the app on an attached device or emulator
cd my_app
dn run
```
