# Code Architecture

APWD follows a clean layered architecture with clear separation of concerns.

## Architecture Layers

```
┌─────────────────────────────────────────┐
│  Screens (UI Layer)                     │
│  - Stateful/Stateless widgets           │
│  - Consumes providers                   │
│  → See screens/CLAUDE.md                │
└─────────────────────────────────────────┘
              ↓ calls
┌─────────────────────────────────────────┐
│  Providers (State Management)           │
│  - ChangeNotifier pattern               │
│  - Manages UI state                     │
│  → See providers/CLAUDE.md              │
└─────────────────────────────────────────┘
              ↓ calls
┌─────────────────────────────────────────┐
│  Services (Business Logic)              │
│  - Pure Dart classes                    │
│  - Database, crypto, network ops        │
│  → See services/CLAUDE.md               │
└─────────────────────────────────────────┘
              ↓ uses
┌─────────────────────────────────────────┐
│  Models (Data Structures)               │
│  - Immutable data classes               │
│  - toMap/fromMap serialization          │
└─────────────────────────────────────────┘
```

## Directory Structure

### `/models`
Data structures used throughout the app.

**Files:**
- `group.dart` - Password group model
- `password_entry.dart` - Password entry model

**Pattern**: Immutable classes with `copyWith()` for updates.

### `/services`
Business logic layer - **stateless**, pure Dart.

Detailed in [services/CLAUDE.md](services/CLAUDE.md).

Key services:
- `DatabaseService` - SQLCipher database operations
- `CryptoService` - Encryption/decryption primitives
- `AuthService` - Master password management
- `PasswordService` - Password CRUD operations
- `WebDavService` - Remote backup

### `/providers`
State management layer using Provider pattern.

Detailed in [providers/CLAUDE.md](providers/CLAUDE.md).

Key providers:
- `AuthProvider` - Auth state, lock/unlock
- `PasswordProvider` - Password list state
- `GroupProvider` - Group list state
- `WebDavProvider` - WebDAV sync state

### `/screens`
UI layer - Flutter widgets.

Detailed in [screens/CLAUDE.md](screens/CLAUDE.md).

Key screens:
- `SetupPasswordScreen` - First-time setup
- `LockScreen` - Master password entry
- `HomeScreen` - Password list
- `PasswordEditScreen` - Add/edit passwords
- `SettingsScreen` - App settings + WebDAV

### `/widgets`
Reusable UI components.

Currently minimal - most UI is in screens.

### `/utils`
Constants and helper functions.

**Files:**
- `constants.dart` - App constants, settings keys

## Data Flow Example

**User adds a password:**

```dart
// 1. Screen calls Provider
await context.read<PasswordProvider>().createPassword(entry);

// 2. Provider calls Service
class PasswordProvider extends ChangeNotifier {
  Future<bool> createPassword(PasswordEntry entry) async {
    final id = await _passwordService.create(entry);  // ← Service call
    await loadPasswords();  // Refresh state
    notifyListeners();       // Update UI
    return id != null;
  }
}

// 3. Service performs database operation
class PasswordService {
  Future<int> create(PasswordEntry entry) async {
    return await _dbService.insertPassword(entry.toMap());
  }
}

// 4. Database service executes SQL
class DatabaseService {
  Future<int> insertPassword(Map<String, dynamic> data) async {
    return await _db.insert('passwords', data);
  }
}
```

## Key Patterns

### 1. Provider Pattern
All UI state managed through ChangeNotifier providers.

```dart
// Providing
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PasswordProvider(...)),
    ChangeNotifierProvider(create: (_) => AuthProvider(...)),
  ],
  child: MyApp(),
)

// Consuming
Consumer<PasswordProvider>(
  builder: (context, provider, child) {
    return ListView(children: provider.passwords.map(...));
  },
)
```

### 2. Service Injection
Services passed to providers at creation.

```dart
ChangeNotifierProvider(
  create: (context) => PasswordProvider(
    context.read<PasswordService>(),  // ← Inject dependency
    context.read<GroupService>(),
  ),
)
```

### 3. Async State Management
Providers handle loading states and errors.

```dart
class PasswordProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> loadPasswords() async {
    _isLoading = true;
    notifyListeners();

    try {
      _passwords = await _passwordService.getAll();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 4. Lifecycle Management
Use `addPostFrameCallback` to avoid calling `notifyListeners` during build.

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();  // Async operation that calls notifyListeners
  });
}
```

## Security Architecture

### Encryption Layers

1. **Database Layer**: SQLCipher encrypts entire database file
2. **Export Layer**: Backup files encrypted with separate password
3. **Transport Layer**: WebDAV sends encrypted files only

### Key Derivation

```
Master Password
      ↓ PBKDF2-HMAC-SHA256 (100k iterations)
Derived Key (64 bytes)
      ↓ split
├─ Database Key (32 bytes) → SQLCipher
└─ Validation Key (32 bytes) → Verify password
```

### Secret Storage

- **Master password**: Never stored, derived on unlock
- **Biometric password**: Stored in Flutter Secure Storage (platform keychain)
- **WebDAV credentials**: Stored in Flutter Secure Storage
- **Database key**: Derived from master password, in-memory only

## Dependencies

### Core
- `sqflite` + `sqflite_sqlcipher_flutter_libs` - Encrypted database
- `provider` - State management
- `crypto` - Cryptographic operations

### Platform
- `flutter_secure_storage` - Keychain/Keystore access
- `local_auth` - Biometric authentication

### Network
- `dio` - HTTP client
- `webdav_client` - WebDAV protocol

### Development
- `flutter_test` - Testing framework
- `mockito` - Mocking for tests
- `integration_test` - UI testing

## Adding New Features

### Step-by-Step Process

1. **Create Model** (if needed)
   - Add to `lib/models/`
   - Implement `toMap()` / `fromMap()`
   - Add `copyWith()` for immutability

2. **Create Service** (if needed)
   - Add to `lib/services/`
   - Inject dependencies in constructor
   - Write unit tests

3. **Create/Update Provider**
   - Add to `lib/providers/`
   - Extend `ChangeNotifier`
   - Inject services
   - Manage loading/error states

4. **Create/Update Screen**
   - Add to `lib/screens/`
   - Use `Consumer` or `context.read/watch`
   - Handle async states (loading, error)

5. **Test**
   - Unit tests for service
   - Integration tests if needed
   - UI tests for critical flows

### Example: Adding a New Field

To add "category" field to passwords:

1. Update `PasswordEntry` model with `category` field
2. Update database schema in `DatabaseService`
3. Update `PasswordService` CRUD operations
4. Update `PasswordProvider` to expose categories
5. Update `PasswordEditScreen` UI to show category selector
6. Write tests for new functionality

## Code Style

### Naming Conventions
- Services: `*Service` (e.g., `AuthService`)
- Providers: `*Provider` (e.g., `AuthProvider`)
- Screens: `*Screen` (e.g., `HomeScreen`)
- Private fields: `_fieldName`

### File Organization
- One class per file
- File name matches class name in snake_case
- Group related functionality in same directory

### Documentation
- Document complex logic with comments
- Use `///` for public API documentation
- Prefer self-documenting code over comments

## Common Gotchas

### 1. Calling `notifyListeners` during build
❌ **Wrong:**
```dart
void initState() {
  super.initState();
  _loadData();  // This might call notifyListeners
}
```

✅ **Right:**
```dart
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();
  });
}
```

### 2. Not checking `mounted` after async
❌ **Wrong:**
```dart
Future<void> _save() async {
  await someAsyncOp();
  Navigator.pop(context);  // Widget might be disposed
}
```

✅ **Right:**
```dart
Future<void> _save() async {
  await someAsyncOp();
  if (!mounted) return;
  Navigator.pop(context);
}
```

### 3. Forgetting to dispose controllers
❌ **Wrong:**
```dart
final _controller = TextEditingController();
// No dispose method
```

✅ **Right:**
```dart
final _controller = TextEditingController();

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

## Performance Considerations

- Use `const` constructors where possible
- Avoid rebuilding entire widget tree (use `Consumer` selectively)
- Implement `==` and `hashCode` for models used in lists
- Cache expensive computations in providers
- Use `ListView.builder` for long lists

## Next Steps

- Read [services/CLAUDE.md](services/CLAUDE.md) for service layer details
- Read [providers/CLAUDE.md](providers/CLAUDE.md) for state management
- Read [screens/CLAUDE.md](screens/CLAUDE.md) for UI patterns
