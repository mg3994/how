# 09. Practical App Walkthrough: Real-Time Chat & Media App

## 1. Application Overview & Architecture

This guide walks through the end-to-end architecture and code structure of a production-grade **Real-Time Chat & Media Application** built with DartNative.

The app demonstrates key framework strengths:
- **`FastList`**: High-performance $O(1)$ cell recycling for tens of thousands of chat messages.
- **`Scaffold.bottomInputBar`**: Real-time keyboard curve animation synchronization.
- **iOS 26 Liquid Glass**: Translucent frosted `AppBar` and message bubble overlays.
- **`dartnative_sqlite`**: Local SQLite message persistence via synchronous FFI.
- **`dartnative_supertonic_tts`**: Offline neural text-to-speech audio playback for incoming messages.

```
┌──────────────────────────────────────────────────────────────────┐
│                      ChatScreen UI (Widget)                      │
│   ├── Translucent AppBar (iOS 26 Liquid Glass)                   │
│   ├── FastList (UITableView / RecyclerView Message Recycling)   │
│   └── Scaffold.bottomInputBar (IME Keyboard Frame Synchronized)   │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│                       ChatRepository (Store)                     │
│   ├── messages = signal<List<ChatMessage>>([])                    │
│   └── sendMessage(text) / receiveMessage(text)                   │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
          ┌──────────────────────┴──────────────────────┐
          ▼                                             ▼
┌───────────────────────────┐                 ┌───────────────────────────┐
│   dartnative_sqlite       │                 │ dartnative_supertonic_tts │
│  (Synchronous Local DB)   │                 │   (Offline Neural Speech) │
└───────────────────────────┘                 └───────────────────────────┘
```

---

## 2. Main Entry Point (`lib/main.dart`)

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_sqlite/dartnative_sqlite.dart';
import 'dartnative_plugin_registrant.dart';
import 'screens/chat_screen.dart';

void main() {
  // 1. Register all FFI plugin bindings statically before UI initialization
  DartNativePluginRegistrant.registerAll();

  // 2. Initialize local SQLite database
  Sqlite.ensureInitialized();

  // 3. Register named routes for stack navigation persistence
  registerRoutes({
    '/chat': (_) => const ChatScreen(),
  });

  // 4. Mount root screen directly into runApp
  runApp(const ChatScreen());
}
```

---

## 3. Data Model & SQLite Local Persistence (`lib/models/message.dart`)

```dart
import 'package:dartnative_sqlite/dartnative_sqlite.dart';

class ChatMessage {
  final int id;
  final String sender;
  final String text;
  final bool isUser;
  final int timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sender': sender,
    'text': text,
    'is_user': isUser ? 1 : 0,
    'timestamp': timestamp,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'] as int,
    sender: map['sender'] as String,
    text: map['text'] as String,
    isUser: (map['is_user'] as int) == 1,
    timestamp: map['timestamp'] as int,
  );
}

class ChatDatabase {
  late final Database _db;

  void init() {
    _db = Sqlite.open('chat_app.db');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender TEXT,
        text TEXT,
        is_user INTEGER,
        timestamp INTEGER
      )
    ''');
  }

  void insertMessage(ChatMessage msg) {
    _db.execute(
      'INSERT INTO messages (sender, text, is_user, timestamp) VALUES (?, ?, ?, ?)',
      [msg.sender, msg.text, msg.isUser ? 1 : 0, msg.timestamp],
    );
  }

  List<ChatMessage> fetchAllMessages() {
    final ResultSet results = _db.select('SELECT * FROM messages ORDER BY timestamp ASC');
    return results.map((row) => ChatMessage.fromMap(row)).toList();
  }
}
```

---

## 4. Reactive State Store (`lib/stores/chat_store.dart`)

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_supertonic_tts/dartnative_supertonic_tts.dart';
import '../models/message.dart';

class ChatStore {
  final db = ChatDatabase();
  final messages = signal<List<ChatMessage>>([]);
  final FastListController scrollController = FastListController();

  void init() {
    db.init();
    messages.value = db.fetchAllMessages();
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      sender: 'You',
      text: text,
      isUser: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // Save to local database
    db.insertMessage(newMessage);

    // Update signal value (triggers UI rebuild)
    messages.value = [...messages.value, newMessage];

    // Scroll to new message
    scrollController.scrollToItem(messages.value.length - 1, animated: true);

    // Trigger mock response
    _receiveMockResponse(text);
  }

  void _receiveMockResponse(String userText) async {
    await Future.delayed(const Duration(seconds: 1));
    final reply = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      sender: 'Assistant',
      text: 'Received: "$userText"',
      isUser: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    db.insertMessage(reply);
    messages.value = [...messages.value, reply];
    scrollController.scrollToItem(messages.value.length - 1, animated: true);

    // Read response aloud via offline neural TTS
    SupertonicTts.speak(reply.text, language: 'en-US');
  }
}

final chatStore = ChatStore();
```

---

## 5. UI Implementation (`lib/screens/chat_screen.dart`)

```dart
import 'package:dartnative/dartnative.dart';
import '../stores/chat_store.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    chatStore.init();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when messages signal emits a change
    final messageList = chatStore.messages.watch(context);

    return Scaffold(
      brightness: Brightness.dark,
      // iOS 26 Translucent Liquid Glass Header
      appBar: AppBar(
        title: const Text('DartNative Chat'),
        backgroundColor: Colors.black.withOpacity(0.4),
      ),
      body: FastList(
        controller: chatStore.scrollController,
        itemCount: messageList.length,
        keepAliveCount: 30, // Recycles views outside 30-item sliding window
        itemBuilder: (context, index) {
          final msg = messageList[index];
          return MessageBubble(message: msg);
        },
      ),
      // Synchronized to native IME keyboard animation curve
      bottomInputBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.black12,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                hintText: 'Type a message…',
                minLines: 1,
                maxLines: 4,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                chatStore.sendMessage(_textController.text);
                _textController.clear();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GlassEffectContainer(
        borderRadius: BorderRadius.circular(16),
        tint: isUser ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        interactive: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.sender,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                message.text,
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
