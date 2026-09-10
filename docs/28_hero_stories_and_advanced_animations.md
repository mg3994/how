# 28. Hero Stories & Native Shared Element Animations

## 1. Hero Shared Element View Transitions

In DartNative, `Hero` animations create fluid shared element view transitions when navigating between screens (e.g. tapping an image thumbnail in a `FastGrid` to expand into a full-screen photo viewer).

Because backing views are native `UIView` / `android.view.View` instances, shared element transitions animate the actual host views across screen route boundaries:

```
Screen A (Grid Thumbnail)                                 Screen B (Expanded Photo)
┌─────────────────────────┐                            ┌─────────────────────────┐
│  Hero(tag: 'photo_1')   │──── Shared Element ───────>│  Hero(tag: 'photo_1')   │
│   Image(...)            │     Native Transition      │   Image(...)            │
└─────────────────────────┘                            └─────────────────────────┘
```

```dart
// Screen A: Thumbnail in Grid
Hero(
  tag: 'photo_101',
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(photo.thumbnailUrl),
  ),
)

// Screen B: Expanded Detail Screen
Hero(
  tag: 'photo_101',
  child: Image.network(photo.fullUrl),
)
```

---

## 2. Collapsing Large Titles (`AppBar.largeTitle`)

iOS-style collapsing large titles and Android Material 3 collapsing top app bars are natively supported via `AppBar.largeTitle`:

```dart
Scaffold(
  appBar: AppBar(
    title: const Text('Messages'),
    largeTitle: const Text('Inbox Messages'), // Collapses into title on scroll
  ),
  body: FastList(
    itemCount: messages.length,
    itemBuilder: (context, index) => MessageTile(messages[index]),
  ),
)
```

### Native Collapsing Choreography
- **iOS**: Drives `UINavigationBar.prefersLargeTitles = true`. The large title text shrinks and moves into the compact navigation bar during scroll view content offset translation.
- **Android**: Drives Material 3 `CollapsingToolbarLayout` transitions natively.

---

## 3. Native Search App Bar Choreography

`AppBar.searchBar` integrates system search bar transitions (iOS 26 search pill animation and Android M3 search view):

```dart
AppBar(
  title: const Text('Explore'),
  searchBar: SearchBar(
    hintText: 'Search photos or users…',
    onQueryChanged: (query) {
      filterResults(query);
    },
  ),
)
```
