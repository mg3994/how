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
