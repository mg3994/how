# 01. Overview & Architecture Mechanics

## 1. Single-Thread Execution Model

Every cross-platform framework must decide how to bridge application code and platform UI. Traditional solutions introduce thread boundaries, message queues, or custom rasterization engines.

DartNative eliminates bridges and queues by executing the Dart VM, widget tree diffing, Yoga layout calculations, and platform UI view mutations synchronously on the platform's **Main UI Thread** (the RunLoop on iOS, the Looper/MainThread on Android).

```
 ┌──────────────────────────────────────────────────────────────────┐
 │                         Main UI Thread                           │
 │                                                                  │
 │  ┌──────────────┐   ┌──────────────┐   ┌──────────┐   ┌───────┐  │
 │  │  User Event  │──>│  Dart Event  │──>│ Yoga     │──>│ Frame │  │
 │  │  (e.g. Tap)  │   │  Diff & State│   │ Layout   │   │ Commit│  │
 │  └──────────────┘   └──────────────┘   └──────────┘   └───────┘  │
 └──────────────────────────────────────────────────────────────────┘
```

When an event occurs (such as a touch tap or a timer tick):
1. The platform dispatches the native event directly to the Dart event loop on the main thread.
2. Dart executes reactive state updates (`setState()` or `signal.value = x`).
3. Dart diffs the widget element tree and identifies changed attributes or child hierarchies.
4. Dart invokes native C/C++ FFI methods to mutate properties directly on platform target views (`UIView`, `UILabel`, `TextView`, etc.).
5. Yoga recalculates CSS flexbox node dimensions for dirty subtrees in $O(n)$ time.
6. The native OS compositor renders the updated view tree during the current VSYNC cycle.

Because there are no inter-thread serializations or message passing queues, frame processing completes within the single synchronous call stack.

---

## 2. Framework Architecture Comparison

| Architecture Dimension | Flutter | React Native (New Arch / Fabric) | DartNative |
|---|---|---|---|
| **UI Primitives** | Custom painted pixels via Skia/Impeller canvas | Platform Native Views (`UIView`, `android.view.View`) | Platform Native Views (`UIView`, `android.view.View`) |
| **Layout Engine** | Custom RenderObject layout protocol | Yoga (evaluated on C++ thread / shadow tree) | Yoga (evaluated synchronously on main UI thread) |
| **Execution Model** | Separate UI thread for rasterization; Dart thread for logic | Multi-threaded (JS thread, C++ shadow tree, UI thread) | Single-Threaded: Dart VM + Yoga + Native Views on Main Thread |
| **Inter-Thread Bridge** | MethodChannel / BinaryMessenger / FFI | JSI (JavaScript Interface) + C++ Host Objects | Direct Dart FFI to C/C++ platform bindings |
| **Text & Input Controls** | Re-implemented text editing via platform IME channels | Native `UITextField` / `EditText` via Fabric | Native `UITextField` / `EditText` directly driven |
| **System Materials** | Simulated blur/glass filters | Native platform views | Real OS materials (iOS 26 Liquid Glass, Android M3) |

---

## 3. Embedded Dart VM & Flutter Zero Engine Roots

DartNative builds upon **Zero** (Licensor's fork of *Flutter Zero*, originally created by Matej Knopp). Zero strips away Flutter's custom graphics pipeline (Impeller rasterizer, LayerTree, Flutter Scene, DisplayList) while preserving:
- The embedded **Dart VM & AOT Runtime** compiled into the binary.
- Core Dart libraries (`dart:core`, `dart:async`, `dart:ffi`, `dart:math`, `dart:typed_data`).
- The Flutter element reconciliation model (Widget -> Element tree lifecycle).

Instead of sending rendering instructions to a GPU canvas, element mount and update lifecycle methods directly bind to platform view references via direct FFI calls.

---

## 4. Licensing & Sunset Commitment Governance

DartNative is proprietary software owned by **Presence Network Inc.** Subject to the framework license:

### Framework License Terms
- **License Token**: Licensees obtain tokens via `https://dartpub.dev` to build, deploy, and access the private package registry.
- **Continuity for Shipped Applications**: Applications built and shipped while a subscription was active remain permanently licensed to run for end users, even after subscription expiration.
- **Restrictions**: Code modification, reverse engineering, redistribution, or token sharing is prohibited during active commercial distribution.

### Section 4: Sunset Commitment (Open-Source Safety Guarantee)
To guarantee long-term operational safety for developers, Section 4 specifies:
1. **Discontinuation Trigger**: The software is legally deemed "Discontinued" upon formal public announcement or if 12 consecutive months pass without any published update or maintenance statement.
2. **BSD 3-Clause Source Release**: Within 90 days of Discontinuation, Presence Network Inc. is legally obligated to publish the entire current source code of DartNative and all First-Party Plugins under the **BSD 3-Clause License**.
3. **Third-Party Open-Source Attribution**: Components such as Flutter Zero (BSD 3-Clause), Dart SDK (BSD 3-Clause), Yoga (MIT), FlexLayout (MIT), and Skia (BSD 3-Clause) remain under their respective open-source licenses.
