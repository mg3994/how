# 21. Custom Native Views & Platform View Embedding

## 1. Native View Embedding Architecture

In traditional Flutter, embedding native platform views (`UIKitView` / `AndroidView`) requires hybrid composition or virtual display textures, introducing composition latency and touch event forwarding complexities.

In DartNative, **every widget is already a platform view**. Embedding a custom `UIView` (iOS) or `android.view.View` (Android) requires zero composition layers or texture copies. The native view instance is inserted directly into the host view hierarchy as a Yoga flexbox node.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Yoga Flexbox Tree                              │
├────────────────────────────────────────────────────────────────────────┤
│  Parent Container Node                                                 │
│   ├── Native UILabel Node (Text Widget)                                │
│   ├── Custom Platform View Node (Native UIView / android.view.View)    │
│   └── Native UIButton Node (ElevatedButton Widget)                     │
└────────────────────────────────────────────────────────────────────────┘
          ▲ ALL NODES ARE EQUAL CITIZENS IN THE NATIVE VIEW TREE ▲
```

---

## 2. Implementing a Custom Platform View

### Step 1: Write Native View Factory (iOS Objective-C / Swift)

```swift
import UIKit
import DartNative

class CustomNativeViewFactory: NSObject {
    static func createView(viewType: String, creationParams: [String: Any]?) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBlue

        let label = UILabel()
        label.text = creationParams?["text"] as? String ?? "Custom Native View"
        label.textColor = .white
        label.textAlignment = .center
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(label)
        return view
    }
}
```

### Step 2: Register Factory in Plugin Registration

```swift
@objc class CustomViewPlugin: NSObject {
    @objc static func registerWith() {
        DartNativeViewRegistry.registerViewFactory(
            viewType: "com.example.custom_view",
            factory: CustomNativeViewFactory.createView
        )
    }
}
```

### Step 3: Embed Platform View in Dart

```dart
import 'package:dartnative/dartnative.dart';

class CustomViewWidget extends StatelessWidget {
  final String title;

  const CustomViewWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: PlatformView(
        viewType: 'com.example.custom_view',
        creationParams: {
          'text': title,
        },
      ),
    );
  }
}
```

---

## 3. Touch Event Routing & Gesture Handling

Because embedded platform views are real host OS views inside the native view hierarchy:
1. **Direct Touch Dispatch**: Hit testing and touch event propagation (`touchesBegan`, `MotionEvent`) are processed directly by the host OS window without requiring gesture recognizer forwarders or event serialization.
2. **Keyboard Focus**: Text inputs inside embedded platform views acquire system keyboard focus natively.
