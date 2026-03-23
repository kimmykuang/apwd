# Testing

APWD uses a comprehensive testing strategy with multiple test layers.

## Test Structure

```
test/
├── models/              # Model serialization tests
├── services/            # Service layer unit tests (24 tests)
├── integration/         # Cross-service integration tests (10 tests)
└── ui/                  # UI end-to-end tests (1 comprehensive test)
```

## Test Types

### Unit Tests (`test/services/`)

**Purpose**: Test individual service methods in isolation

**Coverage:** 24 tests

**Pattern:**
```dart
void main() {
  late ServiceClass service;
  late MockDependency mockDep;

  setUp(() {
    mockDep = MockDependency();
    service = ServiceClass(mockDep);
  });

  test('should do something', () async {
    // Arrange
    when(mockDep.method()).thenReturn(value);

    // Act
    final result = await service.method();

    // Assert
    expect(result, expectedValue);
  });
}
```

**Key Services Tested:**
- `CryptoService` - Encryption/decryption
- `PasswordService` - CRUD operations
- `GroupService` - Group management
- `WebDavService` - Remote sync

---

### Integration Tests (`test/integration/`)

**Purpose**: Test interactions between multiple services

**Coverage:** 10 tests

**Tests:**
- `webdav_integration_test.dart` - WebDAV backup/restore workflows
- `webdav_full_e2e_test.dart` - Complete self-contained scenarios

**Pattern:**
```dart
void main() {
  late DatabaseService dbService;
  late PasswordService passwordService;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.initialize(testPath, testKey);
    passwordService = PasswordService(dbService);
  });

  tearDown() async {
    await dbService.close();
    await File(testDbPath).delete();
  });

  test('complete workflow', () async {
    // Create → Export → Clear → Import → Verify
  });
}
```

---

### UI Tests (`test/ui/`)

**Purpose**: Test complete user workflows on real simulator/device

**Coverage:** 1 comprehensive test (5 scenarios)

**Location:** `test/ui/app_test.dart`

**Scenarios Tested:**
1. First-time master password setup
2. Add password entry (with group validation)
3. View password details
4. Search functionality
5. Group management

**Execution:**
```bash
# Requires real device or simulator
flutter test test/ui/app_test.dart -d <device-id>
```

**Pattern:**
```dart
testWidgets('complete user flow', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Find and interact with widgets
  await tester.enterText(find.byType(TextField), 'password');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify results
  expect(find.text('Success'), findsOneWidget);
});
```

---

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/services/crypto_service_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run UI Tests (Requires Simulator)
```bash
# Start simulator first
open -a Simulator

# Run UI tests
flutter test test/ui/app_test.dart -d <device-id>
```

---

## Test Conventions

### Naming
- Test files: `*_test.dart`
- Integration tests: `*_integration_test.dart`
- UI tests: `*_ui_test.dart` or place in `test/ui/`

### Structure
```dart
void main() {
  group('FeatureName', () {
    test('should do X when Y', () {
      // Test implementation
    });

    test('should throw error when Z', () {
      // Test implementation
    });
  });
}
```

### Assertions
```dart
// Equality
expect(actual, equals(expected));
expect(actual, expected);  // Shorthand

// Types
expect(value, isA<Type>());

// Collections
expect(list, hasLength(3));
expect(list, contains(item));
expect(list, isEmpty);

// Exceptions
expect(() => throwingFunction(), throwsException);
expect(() => throwingFunction(), throwsA(isA<SpecificException>()));

// Async
await expectLater(future, completion(equals(value)));
```

---

## Mocking

### Using Mockito

```bash
# Generate mocks
flutter pub run build_runner build
```

**Define mocks:**
```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([PasswordService, GroupService])
void main() {
  late MockPasswordService mockPasswordService;

  setUp(() {
    mockPasswordService = MockPasswordService();
  });

  test('should call service', () async {
    // Stub
    when(mockPasswordService.getAll())
        .thenAnswer((_) async => []);

    // Execute
    final result = await mockPasswordService.getAll();

    // Verify
    verify(mockPasswordService.getAll()).called(1);
    expect(result, isEmpty);
  });
}
```

---

## Integration Test Patterns

### Database Tests

```dart
setUp(() async {
  testDbPath = '${Directory.systemTemp.path}/test_${DateTime.now().millisecondsSinceEpoch}.db';
  dbService = DatabaseService();
  await dbService.initialize(testDbPath, testKey);
});

tearDown() async {
  await dbService.close();
  try {
    await File(testDbPath).delete();
  } catch (_) {}
});
```

### Encryption Tests

```dart
test('should encrypt and decrypt', () async {
  final plaintext = 'secret password';
  final key = cryptoService.generateSalt();

  final encrypted = cryptoService.encryptText(plaintext, key);
  expect(encrypted, isNot(equals(plaintext)));

  final decrypted = cryptoService.decryptText(encrypted, key);
  expect(decrypted, equals(plaintext));
});
```

### WebDAV Tests (Self-Contained)

```dart
test('complete WebDAV workflow', () async {
  // Phase 1: Create data
  final passwords = [...];
  for (var p in passwords) {
    await passwordService.create(p);
  }

  // Phase 2: Backup (simulate WebDAV)
  final backupPath = await exportService.createTempBackup('password');
  final webdavDir = Directory('${Directory.systemTemp.path}/webdav');
  await backupFile.copy('${webdavDir.path}/backup.apwd');

  // Phase 3: Clear data
  for (var p in passwords) {
    await passwordService.delete(p.id!);
  }

  // Phase 4: Restore
  await exportService.restoreFromFile('${webdavDir.path}/backup.apwd', 'password');

  // Phase 5: Verify
  final restored = await passwordService.getAll();
  expect(restored.length, passwords.length);
});
```

---

## UI Testing

### Finding Widgets

```dart
// By type
find.byType(ElevatedButton)
find.byType(TextField)

// By text
find.text('Save')
find.text('Add Password')

// By key
find.byKey(Key('password-field'))

// By widget
find.byWidget(myWidget)

// Composite
find.widgetWithText(ElevatedButton, 'Save')
find.descendant(
  of: find.byType(Card),
  matching: find.text('Title'),
)
```

### Interactions

```dart
// Tap
await tester.tap(find.text('Button'));
await tester.pumpAndSettle();  // Wait for animations

// Enter text
await tester.enterText(find.byType(TextField), 'input text');

// Scroll
await tester.drag(find.byType(ListView), Offset(0, -200));
await tester.pumpAndSettle();

// Long press
await tester.longPress(find.text('Item'));
```

### Waiting

```dart
// Wait for all animations
await tester.pumpAndSettle();

// Pump specific duration
await tester.pump(Duration(seconds: 2));

// Pump multiple frames
await tester.pump();
await tester.pump();
```

---

## Test Coverage Goals

**Current Coverage:**
- Services: ~90%
- Integration: Key workflows covered
- UI: Complete user flows

**Target:**
- Unit tests: >80%
- Integration tests: All critical paths
- UI tests: Main user scenarios

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v2
```

---

## Debugging Tests

### Run with verbose output
```bash
flutter test --verbose
```

### Run single test
```bash
flutter test test/services/crypto_service_test.dart --name "should encrypt"
```

### Debug in IDE
- VSCode: Click "Debug" above test
- Android Studio: Right-click test → "Debug"

---

## Common Issues

### 1. Database locked
**Problem:** Multiple tests accessing same database

**Solution:** Use unique database file per test
```dart
testDbPath = '${Directory.systemTemp.path}/test_${DateTime.now().millisecondsSinceEpoch}.db';
```

### 2. Async test timeout
**Problem:** Test hangs waiting for Future

**Solution:** Ensure all async operations complete
```dart
test('should complete', () async {
  await someAsyncOperation();  // ← Don't forget await
});
```

### 3. Widget not found
**Problem:** `findsNothing` when widget should exist

**Solution:** Ensure widget is built and visible
```dart
await tester.pumpAndSettle();  // Wait for animations
await tester.pump(Duration(seconds: 2));  // Wait for data load
```

---

## Best Practices

1. **Isolated tests**: Each test should be independent
2. **Clean up**: Always clean up resources in `tearDown()`
3. **Fast tests**: Mock expensive operations
4. **Descriptive names**: `should save password when form is valid`
5. **Arrange-Act-Assert**: Structure tests clearly
6. **Test one thing**: One assertion per test (when possible)
7. **Use setUp/tearDown**: Reduce duplication

---

## Next Steps

- Write tests before or alongside new features (TDD)
- Run tests before committing code
- Monitor coverage and improve weak areas
- Add UI tests for new critical workflows
