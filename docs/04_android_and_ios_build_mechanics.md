# 04. iOS & Android Platform Mechanics

## 1. iOS Native Architecture & Entry Points

DartNative applications on iOS use standard Apple `UIKit` windowing and scene management architecture.

### Entry Point Lifecycle

```
┌─────────────────────────┐
│     main.m / Swift      │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐      Subclasses      ┌───────────────────────────────┐
│   UIApplicationMain     │─────────────────────>│     DartNativeAppDelegate     │
└────────────┬────────────┘                      │ - Initializes Dart VM Runtime │
             │                                   │ - Handles lifecycle callbacks │
             ▼                                   └───────────────────────────────┘
┌─────────────────────────┐      Subclasses      ┌───────────────────────────────┐
│  UISceneConfiguration   │─────────────────────>│    DartNativeSceneDelegate    │
└─────────────────────────┘                      │ - Creates UIWindow            │
                                                 │ - Mounts Root ViewController  │
                                                 └───────────────────────────────┘
```

#### `AppDelegate.swift`
```swift
import UIKit
import DartNative

@main
class AppDelegate: DartNativeAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

#### `SceneDelegate.swift`
```swift
import UIKit
import DartNative

class SceneDelegate: DartNativeSceneDelegate {
    // Scaffold configures root UIWindow and attaches DartNativeViewController automatically
}
```

---

## 2. CocoaPods Integration (`podhelper.rb`)

iOS plugin dependencies and framework linking are managed through CocoaPods via the SDK helper `~/zero/bin/podhelper.rb`.

### `ios/Podfile` Structure
```ruby
platform :ios, '14.0'

# Load DartNative CocoaPods helper script
podhelper_path = File.expand_path('../../zero/bin/podhelper.rb', __FILE__)
load podhelper_path

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Installs all native Pods required by pubspec dependencies
  dartnative_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

`dartnative_install_all_ios_pods` inspects `pubspec.lock`, finds all `dartnative_*` plugins, and injects their native iOS podspec requirements into the Xcode build configuration automatically.

---

## 3. iOS 26 Liquid Glass Rendering

DartNative provides direct access to iOS 26 frosted translucent glass materials (`UIVisualEffectView` / `CAFilter` private system backdrops) without GPU performance penalties.

```dart
// 1. Translucent AppBar with frosted background
Scaffold(
  appBar: AppBar(
    title: const Text('Glass Header'),
    backgroundColor: Colors.white.withOpacity(0.3), // Alpha < 1 opts into glass pill
  ),
  body: GlassEffectContainer(
    borderRadius: BorderRadius.circular(20),
    tint: Colors.blue.withOpacity(0.1),
    brightness: Brightness.dark,
    interactive: true,
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Frosted Liquid Glass Content'),
    ),
  ),
)
```

- **Fallback Behavior**: Pre-iOS 26 devices and Android fall back seamlessly to semi-transparent solid background fills with standard elevation shadows.

---

## 4. Android Build Mechanics & Material 3

On Android, DartNative integrates with standard Gradle builds and lowers widgets into native `android.view.View` hierarchies.

### Gradle Integration (`android/app/build.gradle`)
```groovy
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'dev.dartnative.draft-gradle-plugin'
}

android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.example.myapp"
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### Material 3 & Dynamic Color (Material You)
On Android 12+ (API level 31+), DartNative extracts dynamic wallpaper color schemes using `DynamicColor.colorScheme(brightness:)`:

```dart
Widget build(BuildContext context) {
  final dynamicTheme = DynamicColor.colorScheme(Brightness.light);

  return App(
    theme: ThemeData(
      colorScheme: dynamicTheme,
    ),
    home: const HomeScreen(),
  );
}
```

---

## 5. IME Keyboard Synchronization (`Scaffold.bottomInputBar`)

In mobile applications, sticky input bars (such as chat text inputs) often suffer from stutter or latency lag when tracking the software keyboard animation curve.

DartNative solves this by binding native input bars directly to the platform IME layout engine.

```dart
Scaffold(
  body: ListView.builder(...),
  // Pinned directly to the native OS keyboard transition
  bottomInputBar: ChatInputBar(
    onSend: (text) => _sendMessage(text),
  ),
)
```

### Keyboard Tracking Architecture
- **iOS**: Attaches a `UIInputAccessoryView` / `keyboardFrameWillChangeNotification` observer. The input bar's Yoga layout constraints update synchronously frame-by-frame inside Apple's native `UIView` animation block.
- **Android**: Listens to `WindowInsetsAnimation.Callback` (Android 11+ / API 30+). Height transitions execute in real time alongside the OS IME inset transition curve without thread hopping or frame lag.
