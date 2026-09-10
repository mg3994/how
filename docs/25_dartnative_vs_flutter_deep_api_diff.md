# 25. DartNative vs Flutter: Deep Per-Widget API Diff & Porting Reference

## 1. Core API & Widget Mapping

When porting code or designing apps in DartNative, widgets map onto native platform controls. While most Flutter widgets (`Column`, `Row`, `Expanded`, `SizedBox`, `Padding`, `Center`, `Container`, `Align`, `Text`, `Image`, `GestureDetector`) work unchanged, specific widgets exhibit key behavioral or structural differences:

| Flutter Widget | DartNative Equivalent | Key Architectural & Behavioral Difference |
|---|---|---|
| **`ListView` / `ListView.builder`** | `FastList` | Standard `ListView` instantiates all cells inside a `UIScrollView`. `FastList` uses real native view cell recycling (`UITableView` on iOS, `RecyclerView` on Android). |
| **`GridView`** | `FastGrid` / `MasonryFastGrid` | Backed by `UICollectionView` and `GridLayoutManager` with cell recycling. |
| **`Navigator`** | `Navigator` | `Navigator.push(ctx, PageRoute(builder: (_) => Screen()))`. `PageRoute` requires explicit `RouteTransition` enums (`slideFromRight`, `slideFromBottom`, `fade`) instead of custom `transitionsBuilder` curves. |
| **`showDialog` + `AlertDialog`** | `showAlert(...)` | `showAlert(context:, title:, message:, actions:)` returns a `Future<int>` resolving to the tapped button index via native OS alert controllers. |
| **`TextField`** | `TextField` | Lowered to a true native `UITextField` / `EditText`. Minimal `InputDecoration` padding/hinting; borders and backgrounds should be styled via a wrapping `Container`. |
| **`Scaffold`** | `Scaffold` | Includes native `bottomInputBar` for sticky chat keyboard synchronization and native `brightness: Brightness.dark` trait propagation. |
| **`Offstage`** | `IndexedStack` | ⚠️ In DartNative, an offstage child is UNMOUNTED (state lost). Use `IndexedStack` when state-preserving show/hide is required. |
| **`rootBundle.load(...)`** | `loadAssetBytes(...)` | Synchronous zero-copy asset loading function (`loadAssetBytes('assets/data.json')`) returning `Uint8List?`. |
| **`WidgetsBinding`** | `DartNativePluginRegistrant` | Replace `WidgetsFlutterBinding.ensureInitialized()` with `DartNativePluginRegistrant.registerAll()`. |

---

## 2. Navigation & Route Transitions

In Flutter, route transitions can be constructed using arbitrary custom curves via `PageRouteBuilder` and `transitionsBuilder`.

In DartNative, route transitions map directly to native OS window animation transitions:

```dart
// DartNative Route Transition Example
Navigator.push(
  context,
  PageRoute(
    builder: (context) => const DetailScreen(),
    transition: RouteTransition.slideFromBottom, // Modal detent transition
    duration: const Duration(milliseconds: 300),
    settings: RouteSettings(name: '/detail'),
  ),
);
```

### Supported Native Transitions
- **`RouteTransition.slideFromRight`**: Standard iOS `UINavigationController` push / Android material slide.
- **`RouteTransition.slideFromBottom`**: Native iOS modal presentation style.
- **`RouteTransition.slideFromLeft`**: Reverse lateral slide.
- **`RouteTransition.slideFromTop`**: Top-down notification sheet drop.
- **`RouteTransition.fade`**: Cross-dissolve alpha transition.
