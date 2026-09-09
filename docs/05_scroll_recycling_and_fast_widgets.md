# 05. High-Performance Scroll Recycling & Fast Widgets

## 1. `ListView` vs `FastList` (`UITableView` / `RecyclerView`)

DartNative offers two distinct scrolling strategies based on application performance requirements:

| Dimension | Standard `ListView` | `FastList` / `FastGrid` |
|---|---|---|
| **Underlying Native Component** | `UIScrollView` (iOS) / `ScrollView` (Android) | `UITableView` (iOS) / `RecyclerView` (Android) |
| **Cell Memory Model** | All child elements/views instantiated in memory | Cell View recycling & reuse as items scroll off-screen |
| **Ideal Use Case** | Short or fixed-length layouts (< 50 items) | Long, infinite, or image-heavy feeds (100+ to 1,000,000+ items) |
| **Windowing Control** | Managed by Flutter viewport bounds | `keepAliveCount` explicit sliding window |
| **Programmatic Scrolling** | Scroll position offset translation | `FastListController.scrollToItem(index)` native jump |

---

## 2. Cell Recycling Mechanics & `keepAliveCount`

In `FastList`, cells that exit the visible viewport are detached from their current data item and placed into a native cell recycling queue.

```
                           Scrolling Downward
                                  │
                                  ▼
      ┌────────────────────────────────────────────────────────┐
      │ Recycled Cell Pool (UITableViewCell / ViewHolder)       │
      └───────────────────────────┬────────────────────────────┘
                                  │
                                  ▼ Re-bound with new item data
      ┌────────────────────────────────────────────────────────┐
      │ Visible Viewport                                       │
      │  ┌──────────────────────────────────────────────────┐  │
      │  │ Item [Index 10]                                  │  │
      │  ├──────────────────────────────────────────────────┤  │
      │  │ Item [Index 11]                                  │  │
      │  └──────────────────────────────────────────────────┘  │
      └────────────────────────────────────────────────────────┘
```

### The `keepAliveCount` Sliding Window

By default, DartNative retains built cell states during list scrolling. For very large feeds, set `keepAliveCount` to restrict active widget state memory to a sliding window centered around the visible viewport:

```dart
FastList(
  itemCount: 50000,
  keepAliveCount: 20, // Retains 20 cells around viewport; recycles remaining states
  itemBuilder: (context, index) {
    final item = items[index];
    return ListTile(
      leading: Image.network(
        item.imageUrl,
        cacheWidth: 100, // Downscale image decode dimensions to match cell size
        cacheHeight: 100,
      ),
      title: Text(item.title),
    );
  },
)
```

---

## 3. Image Decode Memory Optimization

When displaying high-resolution images inside scrolling feeds, raw image bitmap decoding can exhaust GPU memory.

DartNative `Image` widgets support downsampled native decoding via `cacheWidth` and `cacheHeight`:
- The platform image loader (`SDWebImage` / `Glide`) decodes the source JPEG/PNG directly into a downscaled bitmap buffer matching the specified logical pixel dimensions before uploading to GPU textures.
- This reduces memory footprint by up to 90% compared to full-resolution decoding.

---

## 4. `FastGrid` & `MasonryFastGrid`

For two-dimensional collection feeds, DartNative provides:

- **`FastGrid`**: Backed by `UICollectionView` (iOS) and `RecyclerView` with `GridLayoutManager` (Android) for uniform grid column layouts.
- **`MasonryFastGrid`**: Backed by custom staggered collection views for Pinterest-style variable-height layouts.

```dart
MasonryFastGrid(
  crossAxisCount: 2,
  mainAxisSpacing: 8.0,
  crossAxisSpacing: 8.0,
  itemCount: photos.length,
  itemBuilder: (context, index) {
    final photo = photos[index];
    return AspectRatio(
      aspectRatio: photo.width / photo.height,
      child: Image.network(photo.url),
    );
  },
)
```

---

## 5. Programmatic Scrolling via `FastListController`

Scrolling programmatically to a specific index in a 100,000-item list in standard web/canvas frameworks requires evaluating all intermediate item heights.

In DartNative, `FastListController` executes index scrolling in a single C/C++ FFI call directly to the native `UITableView.scrollToRow` / `RecyclerView.scrollToPosition`:

```dart
final FastListController controller = FastListController();

// Inside widget tree
FastList(
  controller: controller,
  itemCount: messages.length,
  itemBuilder: (context, index) => MessageBubble(messages[index]),
);

// Smooth scroll to target message index
void scrollToLatestMessage() {
  controller.scrollToItem(
    messages.length - 1,
    animated: true,
  );
}

// Instant jump (no animation)
void jumpToTop() {
  controller.jumpToItem(0);
}
```
