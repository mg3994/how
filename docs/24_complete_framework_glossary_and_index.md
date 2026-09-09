# 24. Framework Technical Glossary & Master Index

## 1. Technical Glossary

| Term / Identifier | Definition & Technical Role |
|---|---|
| **`dn` CLI** | The primary command-line tool wrapper (`~/zero/bin/dn`) for managing, building, and running DartNative projects. |
| **Flutter Zero** | The underlying engine fork created by Matej Knopp and developed by Presence Network Inc. Strips Flutter's GPU rasterizers while retaining the embedded Dart VM and reconciliation tree. |
| **Yoga Flexbox** | Meta's C++ CSS Flexbox layout engine used by DartNative to compute $O(n)$ linear layouts synchronously on the main thread. |
| **`FastList`** | High-performance scrolling list backed by native `UITableView` (iOS) and `RecyclerView` (Android) with cell view recycling. |
| **`keepAliveCount`** | Sliding window parameter on `FastList` / `FastGrid` restricting active cell state retention during fast scrolling. |
| **`Scaffold.bottomInputBar`** | Sticky input bar property bound directly to native platform IME software keyboard animation curves. |
| **`signal<T>`** | Fine-grained observable state primitive built into DartNative core. |
| **`DartNativePluginRegistrant`** | Auto-generated registration class (`lib/dartnative_plugin_registrant.dart`) invoking static native FFI plugin bindings. |
| **`Pointer<Void>`** | Low-level C-ABI pointer handle representing an underlying native `UIView` / `android.view.View` instance. |
| **`CanvasSurface`** | Embedded Skia GPU surface (`dartnative_skia`) used for custom SkSL fragment shader execution (`RuntimeEffect`). |
| **Sunset Commitment** | Section 4 license guarantee obligating Presence Network Inc. to release the source code under BSD 3-Clause within 90 days if discontinued. |
