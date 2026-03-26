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

---

## E2E Testing with Claude AI

### Purpose

APWD includes a comprehensive **End-to-End (E2E) testing system** that uses Claude AI to drive real iOS simulator interactions. Unlike traditional UI tests, E2E tests verify complete user workflows on an actual simulator, testing the full stack from UI to encrypted database.

### Location

```
tests/e2e/
├── README.md              # Complete E2E documentation
├── config.yaml            # Global test configuration
├── run_tests.sh           # Interactive test launcher
├── scenarios/             # Test scenario definitions (YAML)
├── utils/                 # State preparation scripts (Python)
└── reports/               # Test execution reports & screenshots
```

### Test Types

#### 1. Scenario Tests
**Purpose**: Declarative test definitions in YAML format

**Examples**:
- `search_test.yaml` - Search functionality
- `password_crud_test.yaml` - Password lifecycle
- `groups_test.yaml` - Group management
- `webdav_test.yaml` - Remote backup/restore
- `export_import_test.yaml` - File export/import

**Pattern**:
```yaml
name: "Search Test"
description: "Verify search across passwords"
type: "test"

depends_on:
  - standard_state

steps:
  - id: "step1"
    action: "tap_search_icon"
    description: "Open search screen"
    expected:
      screen: "SearchScreen"

  - id: "step2"
    action: "enter_text"
    description: "Search for 'GitHub'"
    params:
      text: "GitHub"
    expected:
      results_count: 1
```

#### 2. Visual Tests
**Purpose**: Screenshot-based verification at each step

**Features**:
- Automatic screenshot capture on every action
- Visual debugging trail for failed tests
- Stored in `tests/e2e/reports/screenshots/`

#### 3. Cross-Functional Tests
**Purpose**: Test interactions between multiple features

**Examples**:
- Create password → Backup via WebDAV → Restore
- Create group → Assign passwords → Export → Import → Verify

### Execution

#### Quick Start
```bash
# Interactive menu
cd tests/e2e
./run_tests.sh

# Direct execution
claude -p "Execute E2E test: tests/e2e/scenarios/search_test.yaml"

# Full test suite
claude -p "Run complete APWD E2E test suite"
```

#### Prerequisites
- Claude CLI installed and configured
- iOS Simulator running
- mobile-mcp server installed
- APWD built for simulator

### Architecture

**3-Layer System**:

```
Claude AI Agent
    ↓ (reads YAML scenarios, adapts to UI)
Python Orchestration
    ↓ (prepares state, generates configs)
Mobile Automation (mobile-mcp + xcrun simctl)
    ↓ (drives simulator, captures screenshots)
iOS Simulator
```

**Key Differences from Traditional UI Tests**:
- **No hardcoded element locators** - Claude finds elements dynamically
- **Natural language scenarios** - Tests read like user stories
- **Adaptive to UI changes** - AI handles minor variations
- **Real device testing** - Not mocked, runs on actual simulator
- **Encrypted database safe** - Python doesn't need decryption keys

### Test Coverage

**7 Comprehensive Scenarios**:
1. **base_setup** - First-time master password setup
2. **standard_state** - Prepare test data (3 passwords, 2 groups)
3. **search_test** - Search by title, username, group
4. **password_crud_test** - Create, view, edit, delete passwords
5. **groups_test** - Create, edit, delete groups
6. **webdav_test** - Backup to WebDAV, restore from remote
7. **export_import_test** - Export .apwd file, import and verify

### Test Comparison

| Feature                    | Unit Tests | Integration Tests | UI Tests (Flutter) | E2E Tests (Claude AI) |
|---------------------------|------------|-------------------|--------------------|-----------------------|
| **Scope**                 | Single method | Multiple services | Widget interactions | Complete workflows |
| **Environment**           | Isolated | Test database | Widget tester | Real simulator |
| **Speed**                 | Fast (<1s) | Medium (1-5s) | Medium (2-10s) | Slow (30-120s) |
| **Database**              | Mocked | Real (test) | Real (test) | Real (production-like) |
| **UI Verification**       | ❌ None | ❌ None | ✅ Widget tree | ✅ Visual screenshots |
| **Encryption Tested**     | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes (full stack) |
| **WebDAV Tested**         | ⚠️ Mocked | ✅ Simulated | ⚠️ Mocked | ✅ Real server |
| **Maintenance**           | Low | Medium | High (brittle) | Low (AI adapts) |
| **Debugging**             | Stack traces | Logs | Widget tree | Screenshots + logs |
| **CI/CD Friendly**        | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Requires simulator |
| **Test Definition**       | Dart code | Dart code | Dart code | YAML + AI |
| **Human Readable**        | ⚠️ Code | ⚠️ Code | ⚠️ Code | ✅ Natural language |
| **Handles UI Changes**    | N/A | N/A | ❌ Breaks easily | ✅ Adapts dynamically |

### When to Use Each Test Type

**Unit Tests** (`test/services/`, `test/models/`):
- Testing service methods in isolation
- Verifying encryption/decryption logic
- Testing business rules

**Integration Tests** (`test/integration/`):
- Testing service interactions
- Verifying database operations
- Testing WebDAV workflows (simulated)

**UI Tests** (`test/ui/`):
- Testing widget rendering
- Verifying navigation flows
- Testing form validations

**E2E Tests** (`tests/e2e/`):
- Verifying complete user workflows
- Testing real simulator behavior
- Regression testing critical paths
- Acceptance testing before releases

### Reports

E2E tests generate comprehensive reports:

```
tests/e2e/reports/
├── search_test_20260323_143022.md
├── screenshots/
│   ├── search_test_step1_20260323_143025.png
│   ├── search_test_step2_20260323_143030.png
│   └── search_test_step3_20260323_143035.png
```

**Report Contents**:
- Test scenario details
- Step-by-step execution log
- Screenshots at each step
- Pass/fail status per step
- Total execution time
- Error messages (if any)

### Best Practices

1. **Start with base_setup**: Always begin E2E test runs from clean state
2. **Use standard_state**: Leverage prepared test data for consistent tests
3. **Review screenshots**: Visual debugging is most effective
4. **Test critical paths**: Focus on user workflows that matter most
5. **Run before releases**: E2E tests catch integration issues missed by unit tests
6. **Keep scenarios declarative**: Let Claude handle the implementation details

### Example: Running Search Test

```bash
# 1. Start simulator
open -a Simulator

# 2. Build and install app
flutter build ios --simulator
xcrun simctl install booted build/ios/iphonesimulator/Runner.app

# 3. Run test
cd tests/e2e
./run_tests.sh
# Select: 1 (search_test)

# 4. View results
cat reports/search_test_*.md
open reports/screenshots/
```

### Troubleshooting

See [E2E README](../tests/e2e/README.md#troubleshooting) for detailed solutions to:
- Simulator not running
- App not installed
- Database state corruption
- WebDAV connection issues
- Claude element finding failures

---

For complete E2E documentation, see [tests/e2e/README.md](../tests/e2e/README.md)
