# 14. Internal FFI Bridge & Memory Management

## 1. Low-Level C/C++ FFI Pointer Mechanics

DartNative replaces traditional IPC/MethodChannel message serialization with direct C-ABI Foreign Function Interface (FFI) pointer calls.

When Dart elements create or update native UI components, Dart calls exported C functions passing opaque native handles (`Pointer<Void>`):

```
┌─────────────────────────┐                            ┌─────────────────────────┐
│     Dart Element Tree   │                            │   Native Platform View  │
│  Pointer<Void> handle   │──── Direct FFI Pointer ───>│  UIView* (iOS)          │
│                         │        Call                │  android.view.View (Android)│
└─────────────────────────┘                            └─────────────────────────┘
```

### C-ABI Export Interface Example

```c
// Native C-ABI function exported by DartNative C++ engine
__attribute__((visibility("default"))) __attribute__((used))
void DN_View_SetFrame(void* viewHandle, float x, float y, float width, float height) {
    #if defined(__APPLE__)
    UIView* view = (__bridge UIView*)viewHandle;
    view.frame = CGRectMake(x, y, width, height);
    #elif defined(__ANDROID__)
    // JNI or direct C++ view pointer manipulation
    #endif
}
```

On the Dart side:
```dart
typedef ViewSetFrameC = Void Function(Pointer<Void> handle, Float x, Float y, Float width, Float height);
typedef ViewSetFrameDart = void Function(Pointer<Void> handle, double x, double y, double width, double height);

final ViewSetFrameDart _setViewFrame = nativeLib
    .lookup<NativeFunction<ViewSetFrameC>>('DN_View_SetFrame')
    .asFunction<ViewSetFrameDart>();
```

---

## 2. Memory Lifecycle: Dart GC vs Native Reference Counting

Managing objects across managed garbage collection (Dart GC) and ARC / Reference Counting (`UIKit` / Android JNI) requires strict lifecycle synchronization:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Memory Lifecycle Lifecycle                      │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Element Mount     ──> Allocates Native View                         │
│                          Increments ARC ref count (`CFRetain` / ARC)  │
│                          Stores `Pointer<Void>` in Element handle      │
│                                                                        │
│ 2. Element Rebuild   ──> Passes `Pointer<Void>` handle in FFI calls     │
│                          Zero garbage collection overhead              │
│                                                                        │
│ 3. Element Unmount   ──> Calls C-ABI release function (`DN_View_Destroy`)│
│                          Decrements ARC ref count (`CFRelease`)        │
│                          Frees Yoga node pointer                       │
└────────────────────────────────────────────────────────────────────────┘
```

### Finalizer Safety
To prevent native memory leaks if a Dart element is unexpectedly garbage-collected before unmounting, DartNative registers a `NativeFinalizer`:

```dart
final NativeFinalizer _viewFinalizer = NativeFinalizer(
  nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>('DN_View_Destroy_Finalizer'),
);

// Attached when native view handle is created
_viewFinalizer.attach(elementInstance, nativeViewHandle, externalAllocationSize: 1024);
```

---

## 3. Zero-Copy Buffer Passing

For high-throughput data transfers (such as image pixel buffers, audio PCM streams, or database query results), DartNative utilizes direct memory pointer borrowing (`Pointer<Uint8>`) rather than copying data across memory spaces:

```dart
// Accessing raw byte buffers without memory duplication
Pointer<Uint8> bufferPtr = rawData.addressOf;
nativeAudioStreamWrite(streamHandle, bufferPtr, rawData.length);
```

This guarantees 0% CPU overhead from data serialization and memory copying.
