# 22. Testing & CI/CD Automation Pipelines

## 1. Testing Strategy & Framework Support

DartNative provides full testing support across unit testing, reactive state store verification, and headless widget testing.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Testing Hierarchy                               │
├────────────────────────────────────────────────────────────────────────┤
│  1. Unit Tests (`test`)       ──> Tests Dart logic, signals, stores    │
│  2. Element Tests (`dn test`)  ──> Verifies widget tree reconciliation   │
│  3. Integration Tests          ──> Runs on attached physical devices   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Writing Unit & Signal Store Tests

```dart
import 'package:dartnative/dartnative.dart';
import 'package:test/test.dart';

class CounterStore {
  final count = signal<int>(0);
  void increment() => count.value++;
}

void main() {
  group('CounterStore Tests', () {
    test('Initial count should be 0', () {
      final store = CounterStore();
      expect(store.count.value, equals(0));
    });

    test('Increment should update signal value', () {
      final store = CounterStore();
      store.increment();
      expect(store.count.value, equals(1));
    });
  });
}
```

To execute unit tests:
```bash
dn test
```

---

## 3. GitHub Actions CI/CD Pipeline Configuration

Automate build verification, linting, and artifact compilation using GitHub Actions (`.github/workflows/ci.yml`):

```yaml
name: DartNative CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: macos-14

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Install DartNative SDK
        run: |
          curl -fsSL https://cdn.dartnative.com/install.sh | sh
          echo "$HOME/zero/bin" >> $GITHUB_PATH

      - name: Check Environment (`dn doctor`)
        run: dn doctor

      - name: Install Dependencies
        run: dn pub get

      - name: Run Unit Tests
        run: dn test

      - name: Build iOS Application (`dn build ios`)
        run: dn build ios --no-codesign

      - name: Build Android Application (`dn build apk`)
        run: dn build apk
```
