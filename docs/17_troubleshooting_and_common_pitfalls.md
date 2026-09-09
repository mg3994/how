# 17. Troubleshooting Guide & Common Pitfalls

## 1. Master Troubleshooting Matrix

This guide provides instant diagnosis and resolution playbooks for common development, build, and runtime issues in DartNative.

| Symptom / Error Message | Primary Root Cause | Resolution Playbook |
|---|---|---|
| **App launches to a persistent White Screen (No Crash)** | 1. `DartNativePluginRegistrant.registerAll()` omitted or not executed as the first line of `main()`. <br> 2. `App(home: Screen())` used as root instead of passing screen directly to `runApp()`. | 1. Add `DartNativePluginRegistrant.registerAll();` at line 1 of `main()`. <br> 2. Pass root screen directly: `runApp(const HomeScreen());`. |
| **`NSInternalInconsistencyException: Setting a message handler before the FlutterEngine has been run`** | 1. Importing legacy `MethodChannel` Flutter package. <br> 2. `UIMainStoryboardFile` key still present in `Info.plist`. | 1. Replace legacy plugin with `dartnative_*` FFI equivalent. <br> 2. Delete `UIMainStoryboardFile` key from `Info.plist`. |
| **`Failed to lookup symbol 'XYZ': dlsym(...) symbol not found`** | Dynamic library failed to link or symbol name mismatch in C-ABI exports. | 1. For iOS: Ensure function carries `__attribute__((visibility("default"))) __attribute__((used))` in Objective-C/C. <br> 2. For Android: Ensure dynamic library is listed in CMakeLists.txt and loaded via `DynamicLibrary.open('libxyz.so')`. |
| **Keyboard overlaps chat input or causes stutter** | Chat input declared inside body flex layout or placed inside `bottomNavigationBar`. | Move chat input widget to `Scaffold.bottomInputBar`. It automatically binds to native IME frame transition curves. |
| **`Podfile` pod installation or deployment target warnings** | `IPHONEOS_DEPLOYMENT_TARGET` set below 14.0 or missing `podhelper.rb` installation block. | Set `platform :ios, '14.0'` in `Podfile` and invoke `dartnative_install_all_ios_pods` in Runner target. |
| **`FastList` or grid scrolling stutters or consumes high RAM** | 1. Creating full-resolution `Image` controls inside list cells. <br> 2. Unbound cell state retention. | 1. Pass `cacheWidth` and `cacheHeight` on `Image` controls to downscale decode buffer. <br> 2. Set `keepAliveCount: 20` on `FastList`. |

---

## 2. White Screen Diagnostics

When an app builds successfully but displays a white screen on launch without throwing an exception, execute these diagnostic checks:

```
                  White Screen Diagnostic Flow
                               │
            Is `registerAll()` called first in `main()`?
                               │
                      ┌────────┴────────┐
                      │ No              │ Yes
                      ▼                 ▼
             Add `registerAll()`    Is `runApp` receiving screen directly?
             as first line             ┌────────┴────────┐
                                       │ No              │ Yes
                                       ▼                 ▼
                              Replace `App(home:)`    Run `dn clean`
                              with `runApp(Screen())` and `dn run`
```

---

## 3. iOS Project Surgery (In-Place Port Checklist)

When converting an existing Flutter iOS project in-place:
1. **Delegate Surgery**: Replace `FlutterAppDelegate` in `Runner/AppDelegate.swift` with `DartNativeAppDelegate`. Subclass `DartNativeSceneDelegate` in `Runner/SceneDelegate.swift`.
2. **`Info.plist` Cleanup**: Remove `UIMainStoryboardFile` entry. Keep `UIApplicationSceneManifest` and `UILaunchStoryboardName`.
3. **Podfile Update**: Replace Podfile content with the `podhelper.rb` template:
   ```ruby
   platform :ios, '14.0'
   podhelper_path = File.expand_path('../../zero/bin/podhelper.rb', __FILE__)
   load podhelper_path

   target 'Runner' do
     use_frameworks!
     use_modular_headers!
     dartnative_install_all_ios_pods File.dirname(File.realpath(__FILE__))
   end
   ```
4. **Clean & Run**: Execute `dn clean && dn pub get && dn run`.
