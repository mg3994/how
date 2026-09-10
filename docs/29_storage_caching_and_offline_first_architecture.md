# 29. Storage, Caching & Offline-First Architecture

## 1. Storage & Persistence Tier Architecture

DartNative provides four complementary local storage plugins, each designed for specific data retention scenarios:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Local Storage Pipeline                          │
├────────────────────────────────────────────────────────────────────────┤
│ 1. `dartnative_sqlite`            ──> Relational DB / Complex Queries │
│ 2. `dartnative_hive`              ──> Key-Value NoSQL Cache Store      │
│ 3. `dartnative_shared_preferences`──> Lightweight User Settings        │
│ 4. `dartnative_secure_storage`    ──> Keychain / Keystore Secrets      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Fast NoSQL Caching (`dartnative_hive`)

For local document caching (such as HTTP response payloads or user session state), `dartnative_hive` provides synchronous key-value storage:

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_hive/dartnative_hive.dart';

void main() async {
  DartNativePluginRegistrant.registerAll();

  // Initialize Hive storage directory
  await Hive.initFlutter();

  // Open cache box
  final box = await Hive.openBox<String>('user_cache');

  // Fast synchronous write & read
  box.put('profile_json', '{"name": "Alex", "role": "developer"}');
  final cachedProfile = box.get('profile_json');

  runApp(const MainApp());
}
```

---

## 3. Offline-First Repository Pattern

Combining `dartnative_sqlite` (relational storage) with reactive signals (`signal<T>`) produces robust offline-first synchronization:

```dart
class ArticleRepository {
  final sqliteDb = Sqlite.open('articles.db');
  final articles = signal<List<Article>>([]);

  void loadLocalArticles() {
    // Synchronous local query
    final rows = sqliteDb.select('SELECT * FROM articles ORDER BY created_at DESC');
    articles.value = rows.map((r) => Article.fromMap(r)).toList();
  }

  Future<void> syncWithNetwork() async {
    try {
      final response = await http.get(Uri.parse('https://api.example.com/articles'));
      final remoteArticles = parseArticles(response.body);

      // Save to local SQLite database
      for (final a in remoteArticles) {
        sqliteDb.execute(
          'INSERT OR REPLACE INTO articles (id, title, content) VALUES (?, ?, ?)',
          [a.id, a.title, a.content],
        );
      }

      // Refresh signal value
      loadLocalArticles();
    } catch (e) {
      print('Network unavailable. Serving offline cached articles.');
    }
  }
}
```
