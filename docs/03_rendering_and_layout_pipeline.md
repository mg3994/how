# 03. Rendering & Layout Pipeline

## 1. Widget → Element → Platform Native View Lifecycle

DartNative maintains a unified tree structure mapping high-level declarative Dart widgets directly to host platform views.

```
    Dart Declarative Layer              Element Reconciliation            Platform Native Layer
┌───────────────────────────┐         ┌─────────────────────────┐       ┌───────────────────────────┐
│ Widget Tree (Immutable)   │         │ Element Tree (Mutable)  │       │ Platform Native Views     │
│  Container(               │         │  ComponentElement       │       │  UIView / ViewGroup       │
│    child: Text('Hello')   │────────>│    FlexElement          │──────>│  UILabel / TextView       │
│  )                        │         │      TextElement        │       │                           │
└───────────────────────────┘         └─────────────────────────┘       └───────────────────────────┘
```

1. **Widget Tree**: Immutable configuration objects defined by developer code (`Widget`, `StatelessWidget`, `StatefulWidget`).
2. **Element Tree**: The active lifecycle nodes. When widgets rebuild (e.g., via `setState`), the Element tree performs reconciliations ($O(n)$ diffing):
   - If `Widget.canUpdate(oldWidget, newWidget)` returns `true` (matching runtime `type` and `key`), the existing Element is updated with the new Widget properties.
   - If properties changed, the Element mutates the backing platform native view properties via direct FFI bindings.
3. **Platform Native Layer**: Actual `UIView` / `android.view.View` host instances managed directly by the platform OS.

---

## 2. Yoga Flexbox Engine vs Apple Auto Layout

All layout in DartNative is computed using Meta's **Yoga Flexbox** C++ engine.

### Layout Mechanics Comparison

```
Auto Layout (Constraint Solver):
  View A.left = View B.right + 10
  View A.width = View C.width * 0.5   ──> Cassowary Constraint Solver ──> Time Complexity: O(n²)
  View C.top = Superview.top + 20

Yoga Flexbox (Tree Walk):
  Parent Node [FlexDirection: Column]
    ├─ Child Node A [FlexGrow: 1]     ──> Synchronous Tree Walk ──> Time Complexity: O(n)
    └─ Child Node B [Padding: 12]
```

### Why Yoga Outperforms Auto Layout at Scale
- **Cassowary Solver Complexity**: Apple's Auto Layout uses the Cassowary constraint solver. As view hierarchies grow deeper, constraint relationship graphs expand, resulting in $O(n^2)$ worst-case time complexity.
- **Yoga Linear Tree Walk**: Yoga resolves flexbox rules via a recursive tree walk with dirty-flag subtree propagation. Layout evaluation time grows linearly ($O(n)$) with node count.
- **Flutter Sizing Alignment**: Flutter widgets map directly to Flexbox rules:
  - `Column` / `Row` $\rightarrow$ `FlexDirection.Column` / `Row`
  - `Expanded` / `Flexible` $\rightarrow$ `FlexGrow` / `FlexShrink`
  - `Padding` $\rightarrow$ `YGNodeStyleSetPadding`
  - `Align` / `Center` $\rightarrow$ `YGNodeStyleSetJustifyContent` / `AlignItems`

---

## 3. Property Diffing & Layout Invalidation

When state changes occur, DartNative avoids full view hierarchy teardown or re-layout:

1. **Dirty Subtree Flagging**: Calling `setState()` marks the corresponding Element dirty.
2. **Attribute Diffing**: During `update()`, the Element compares new Widget fields against previous values.
3. **Selective Native Calls**: FFI calls are executed ONLY for changed attributes:
   ```dart
   if (oldWidget.textColor != newWidget.textColor) {
     NativeBridge.setLabelTextColor(nativeViewHandle, newWidget.textColor.value);
   }
   ```
4. **Layout Invalidation**: If geometry properties change (padding, margins, flex bounds), the associated Yoga node is marked dirty (`YGNodeMarkDirty`). Yoga recomputes bounds for dirty subtrees during frame assembly, skipping unaffected subtrees.

---

## 4. Native Canvas Painting vs Skia Acceleration

DartNative provides two distinct rendering paths for custom graphics:

### 1. Platform Core Graphics / Android Canvas (`CustomPaint`)
By default, `CustomPaint` widgets route drawing commands directly to host platform drawing contexts:
- **iOS**: Rendered synchronously via UIKit `drawRect:` backed by **CoreGraphics** (`CGContext`).
- **Android**: Rendered via `android.graphics.Canvas` calls on native `View.onDraw()`.
- **Advantage**: Zero memory overhead from external rasterizer libraries; complete integration with platform window compositing.

### 2. Optional Skia GPU Engine (`dartnative_skia`)
For advanced graphics requiring SkSL custom fragment shaders (`RuntimeEffect`), path blending modes, or complex vector animations, applications import `package:dartnative_skia/dartnative_skia.dart`:

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_skia/dartnative_skia.dart';

// Register Skia engine factories at startup
void main() {
  DartNativePluginRegistrant.registerAll();
  registerSkiaFactories();
  runApp(const ShaderDemoScreen());
}

// Render GPU-accelerated SkSL shaders using CanvasSurface
Widget build(BuildContext context) {
  return CanvasSurface(
    painter: SkiaShaderPainter(shader),
  );
}
```

When using `CanvasSurface`, DartNative binds a native `CAEAGLLayer` / `CAMetalLayer` (iOS) or `TextureView` / `SurfaceView` (Android) driven by an embedded Skia GPU context, allowing high-performance custom shader execution alongside native UI views.
