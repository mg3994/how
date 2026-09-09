# 10. Debugging, Logging & Hot Reload Architecture

## 1. Hot Reload & Hot Restart Internal Mechanics

DartNative supports stateful **Hot Reload** and clean **Hot Restart** during development using the `dn run` command.

### Hot Reload Execution Flow

```
┌─────────────────────────┐
│ Developer edits code    │
│ (e.g. lib/main.dart)    │
└────────────┬────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────┐
│ Frontend Compiler (`frontend_server.dart.snapshot`)    │
│  - Identifies modified source AST nodes                │
│  - Compiles incremental Kernel `.dill` diff payload   │
└────────────┬───────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────┐
│ Dart VM Service (WebSocket Connection)                 │
│  - Sends `reloadSources` RPC request to embedded VM    │
│  - Updates class specifications and function pointers  │
└────────────┬───────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────┐
│ Main Thread Re-evaluation                              │
│  - Triggers top-level Element re-build                 │
│  - Re-evaluates Yoga layout for modified view trees    │
│  - Retains widget State instances (`State<T>`)         │
└────────────────────────────────────────────────────────┘
```

### Hot Reload vs Hot Restart
- **Hot Reload (`r`)**: Re-compiles changed Dart source code, injects new method implementations into the active Dart VM, and requests a top-level widget element update. **State is preserved**.
- **Hot Restart (`R`)**: Clears the Dart Isolate memory state, re-executes `main()`, resets state containers, and invokes `DartNativePluginRegistrant.registerAll()`. **State is reset**.

---

## 2. Dart VM Service WebSocket Protocol

When running in debug mode, the embedded Dart VM opens an administrative HTTP/WebSocket server (typically bound to `127.0.0.1:1024+`).

### Key VM Service Protocol Capabilities
1. **Source Inspection & Breakpoints**: IDEs (VS Code, Android Studio) connect to the VM Service WebSocket to set breakpoints, inspect stack frames, and evaluate expressions in context.
2. **Allocation Tracing**: Monitors native memory allocations and Dart object heap usage.
3. **Timeline Event Tracing**: Emits Chrome Trace Events (`Systrace` / `ATrace` format) covering:
   - `Widget.build` duration
   - Yoga Flexbox layout time (`YGNodeCalculateLayout`)
   - Platform FFI call execution times

---

## 3. Platform Logging Pipeline

In DartNative, calls to `print()` or `developer.log()` do not go to a custom raster log stream. Instead, they pass through direct FFI hooks to native platform logging subsystems:

```
                  ┌─────────────────────────────────────┐
                  │      print('User logged in')        │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │    DartNative Core Logging Hook     │
                  └──────────────────┬──────────────────┘
                                     │
                 ┌───────────────────┴───────────────────┐
                 ▼                                       ▼
    ┌───────────────────────────┐           ┌───────────────────────────┐
    │       iOS (UIKit)         │           │        Android            │
    │  - NSLog / os_log         │           │  - android.util.Log       │
    │  - Visible in Xcode Console│           │  - Visible in Logcat      │
    └───────────────────────────┘           └───────────────────────────┘
```

This ensures that Dart logs interleave chronologically with native OS logs (`UIKit`, `AVFoundation`, `CoreData`, `AndroidRuntime`) inside Xcode Console and Android Studio Logcat.

---

## 4. Troubleshooting Common Debug Scenarios

| Symptom | Primary Cause | Recommended Fix |
|---|---|---|
| **White Screen on Launch** | Missing `DartNativePluginRegistrant.registerAll()` or `App(home:)` invalid root usage | Call `registerAll()` as first line of `main()`; pass root screen directly to `runApp()`. |
| **`Setting a message handler before FlutterEngine...` Crash** | Importing legacy `MethodChannel` plugin package | Replace with first-party FFI plugin equivalent (`dartnative_*`). |
| **Hot Reload does not reflect changes** | Change made inside `initState()` or static initializer | Perform a Hot Restart (`R`) to re-initialize state. |
| **Layout Overlap / Truncation** | Unconstrained container bounds inside `Column` / `Row` | Wrap flex children in `Expanded` or `Flexible` to set explicit Yoga flex grow rules. |
