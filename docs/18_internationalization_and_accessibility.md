# 18. Native Accessibility & Internationalization (l10n)

## 1. Native Accessibility Lowering

Unlike Flutter—which maintains a custom virtual accessibility tree (`SemanticsNode`) mapped via platform channels—DartNative automatically inherits the native accessibility capabilities of host views.

```
DartNative Element                       Platform Native View           System Screen Reader
┌───────────────────────────┐         ┌───────────────────────────┐    ┌───────────────────────────┐
│ Text('Submit',            │──────-->│ UILabel (iOS) /           │--->│ VoiceOver (iOS) /         │
│   semanticsLabel: 'Save') │         │ TextView (Android)        │    │ TalkBack (Android)        │
└───────────────────────────┘         └───────────────────────────┘    └───────────────────────────┘
                                       Directly exposes accessibility   Native OS reads labels
                                       traits and dynamic type fonts    without virtual bridge
```

### Key Accessibility Advantages
1. **Zero Virtual Bridge Overhead**: Platform screen readers (VoiceOver on iOS, TalkBack on Android) traverse native `UIView` / `View` nodes directly.
2. **Native Focus & Traversal Order**: Swipe-to-next element navigation follows native platform windowing order automatically.
3. **Dynamic Type Font Scaling**: Native `Text` controls respect OS system font scaling preferences (`UIFontMetrics` / Android SP scaling) automatically without requiring layout re-calculations.

---

## 2. Localization & Internationalization Pipeline (`dartnative_intl`)

Applications manage multi-language translations using `dartnative_intl`:

### Step 1: Define Translation ARB Files (`lib/l10n/app_en.arb`)

```json
{
  "@@locale": "en",
  "appTitle": "DartNative Chat",
  "welcomeMessage": "Welcome back, {username}!",
  "@welcomeMessage": {
    "placeholders": {
      "username": {
        "type": "String"
      }
    }
  }
}
```

### Step 2: Use Translations in Widget Code

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_intl/dartnative_intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: Center(
        child: Text(l10n.welcomeMessage('Alex')),
      ),
    );
  }
}
```

---

## 3. Dynamic Font Registration

To bundle custom icon fonts or TTF/OTF brand typefaces without Flutter's asset bundler overhead, register font assets at startup using `DartNativeFontRegistrant`:

```dart
import 'package:dartnative/dartnative.dart';

void main() {
  DartNativePluginRegistrant.registerAll();

  // Register custom fonts natively with OS CoreText / FontManager
  DartNativeFontRegistrant.registerFont('assets/fonts/Inter-Regular.ttf');
  DartNativeFontRegistrant.registerFont('assets/fonts/CustomIcons.ttf');

  runApp(const HomeScreen());
}
```
