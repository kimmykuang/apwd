# Providers Layer

Providers manage UI state using the `ChangeNotifier` pattern from the `provider` package.

## Provider Responsibilities

Providers handle:
- ✅ UI state management
- ✅ Loading and error states
- ✅ Calling service methods
- ✅ Notifying UI of changes

Providers do NOT:
- ❌ Perform business logic (delegate to services)
- ❌ Direct database access
- ❌ Cryptographic operations
- ❌ Network calls

## Provider Catalog

### AuthProvider
**Purpose**: Authentication state and session management

**State:**
```dart
bool _isAuthenticated = false;
bool _isBiometricAvailable = false;
bool _isBiometricEnabled = false;
int _autoLockTimeout = 300;  // seconds
DateTime? _lastActiveTime;
```

**Key Methods:**
```dart
Future<bool> setupMasterPassword(String password)
Future<bool> unlock(String password)
Future<bool> unlockWithBiometric()
void lock()
Future<void> loadSettings()
Future<void> updateAutoLockTimeout(int seconds)
Future<bool> enableBiometric()
void recordActivity()  // Reset auto-lock timer
```

**Usage Example:**
```dart
// Check if authenticated
if (context.watch<AuthProvider>().isAuthenticated) {
  return HomeScreen();
} else {
  return LockScreen();
}

// Unlock
await context.read<AuthProvider>().unlock(password);
```

**Auto-lock Logic:**
```dart
// Call recordActivity() on user interaction
void recordActivity() {
  _lastActiveTime = DateTime.now();
  notifyListeners();
}

// Check periodically if should auto-lock
bool get shouldLock {
  if (_lastActiveTime == null) return false;
  final elapsed = DateTime.now().difference(_lastActiveTime!).inSeconds;
  return elapsed > _autoLockTimeout;
}
```

---

### PasswordProvider
**Purpose**: Password list state and operations

**State:**
```dart
List<PasswordEntry> _passwords = [];
PasswordEntry? _selectedPassword;
bool _isLoading = false;
String? _errorMessage;
String _searchQuery = '';
```

**Key Methods:**
```dart
Future<void> loadPasswords()
Future<void> selectPassword(int id)
Future<bool> createPassword(PasswordEntry entry)
Future<bool> updatePassword(PasswordEntry entry)
Future<bool> deletePassword(int id)
void searchPasswords(String query)
```

**Computed Properties:**
```dart
List<PasswordEntry> get filteredPasswords {
  if (_searchQuery.isEmpty) return _passwords;
  return _passwords.where((p) =>
    p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
    (p.username?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
  ).toList();
}

Map<int, List<PasswordEntry>> get passwordsByGroup {
  final grouped = <int, List<PasswordEntry>>{};
  for (var password in _passwords) {
    grouped.putIfAbsent(password.groupId, () => []).add(password);
  }
  return grouped;
}
```

**Usage Example:**
```dart
// Display passwords
Consumer<PasswordProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    return ListView(
      children: provider.filteredPasswords.map((p) => PasswordTile(p)).toList(),
    );
  },
)

// Create password
await context.read<PasswordProvider>().createPassword(newEntry);
```

---

### GroupProvider
**Purpose**: Password group list state

**State:**
```dart
List<Group> _groups = [];
Group? _selectedGroup;
bool _isLoading = false;
String? _errorMessage;
```

**Key Methods:**
```dart
Future<void> loadGroups()
Future<bool> createGroup(Group group)
Future<bool> updateGroup(Group group)
Future<bool> deleteGroup(int id)
Future<void> reorderGroups(List<Group> reordered)
```

**Usage Example:**
```dart
// Display groups
Consumer<GroupProvider>(
  builder: (context, provider, child) {
    return DropdownButton<int>(
      items: provider.groups.map((g) =>
        DropdownMenuItem(value: g.id, child: Text(g.name))
      ).toList(),
      onChanged: (id) => setState(() => _selectedGroupId = id),
    );
  },
)
```

---

### SettingsProvider
**Purpose**: App settings state

**State:**
```dart
int _clipboardClearTimeout = 30;  // seconds
bool _isDarkMode = false;
String _appVersion = '';
```

**Key Methods:**
```dart
Future<void> loadSettings()
Future<void> updateClipboardTimeout(int seconds)
Future<void> setDarkMode(bool enabled)
```

---

### WebDavProvider
**Purpose**: WebDAV sync state and operations

**State:**
```dart
String? webdavUrl;
String? webdavUsername;
String? webdavRemotePath;
bool webdavEnabled = false;
DateTime? lastBackupTime;
bool isConnected = false;
bool isUploading = false;
bool isDownloading = false;
double uploadProgress = 0.0;
double downloadProgress = 0.0;
```

**Key Methods:**
```dart
Future<bool> testConnection({String? url, String? username, String? password})
Future<void> saveSettings({String? url, String? username, String? password})
Future<void> loadSettings()
Future<void> backupToWebDAV(String password)
Future<void> restoreFromWebDAV(String remoteFile, String password, bool overwrite)
```

**Usage Example:**
```dart
// Test connection
ElevatedButton(
  onPressed: () async {
    final success = await context.read<WebDavProvider>().testConnection(
      url: urlController.text,
      username: usernameController.text,
      password: passwordController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Connected!' : 'Failed')),
    );
  },
  child: Text('Test Connection'),
)

// Backup
ElevatedButton(
  onPressed: () async {
    await context.read<WebDavProvider>().backupToWebDAV('backup_password');
  },
  child: Text('Backup Now'),
)
```

---

## Provider Lifecycle

### 1. Registration

Providers registered in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(authService, dbService)),
    ChangeNotifierProvider(create: (context) => PasswordProvider(
      context.read<PasswordService>(),
      context.read<GroupService>(),
    )),
    ChangeNotifierProvider(create: (context) => GroupProvider(
      context.read<GroupService>(),
    )),
    ChangeNotifierProvider(create: (context) => WebDavProvider(
      context.read<WebDavService>(),
      context.read<ExportImportService>(),
      context.read<DatabaseService>(),
    )),
  ],
  child: MyApp(),
)
```

### 2. Consumption

**Option A: `Consumer` widget** (rebuilds on change)
```dart
Consumer<PasswordProvider>(
  builder: (context, provider, child) {
    return Text('${provider.passwords.length} passwords');
  },
)
```

**Option B: `context.watch<T>()` (rebuilds on change)
```dart
Widget build(BuildContext context) {
  final passwordCount = context.watch<PasswordProvider>().passwords.length;
  return Text('$passwordCount passwords');
}
```

**Option C: `context.read<T>()` (no rebuild, for calling methods)
```dart
ElevatedButton(
  onPressed: () {
    context.read<PasswordProvider>().createPassword(entry);
  },
  child: Text('Save'),
)
```

**Option D: `context.select<T, R>()` (rebuild only on specific property)
```dart
final isLoading = context.select<PasswordProvider, bool>((p) => p.isLoading);
if (isLoading) return CircularProgressIndicator();
```

## Common Patterns

### Loading State

```dart
class PasswordProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadPasswords() async {
    _isLoading = true;
    notifyListeners();  // Show loading spinner

    try {
      _passwords = await _passwordService.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();  // Hide loading spinner
    }
  }
}
```

### Error Handling

```dart
class PasswordProvider extends ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> createPassword(PasswordEntry entry) async {
    try {
      await _passwordService.create(entry);
      _errorMessage = null;
      await loadPasswords();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
```

### Optimistic Updates

```dart
Future<bool> deletePassword(int id) async {
  // Optimistic: remove from UI immediately
  _passwords.removeWhere((p) => p.id == id);
  notifyListeners();

  try {
    final success = await _passwordService.delete(id);
    if (!success) {
      // Rollback on failure
      await loadPasswords();
    }
    return success;
  } catch (e) {
    // Rollback on error
    await loadPasswords();
    return false;
  }
}
```

### Debouncing Search

```dart
import 'dart:async';

class PasswordProvider extends ChangeNotifier {
  Timer? _searchDebounce;

  void searchPasswords(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
```

## Testing Providers

### Unit Test Example

```dart
void main() {
  late PasswordProvider provider;
  late MockPasswordService mockService;

  setUp(() {
    mockService = MockPasswordService();
    provider = PasswordProvider(mockService, MockGroupService());
  });

  test('should load passwords', () async {
    // Arrange
    final mockPasswords = [
      PasswordEntry(id: 1, title: 'Test', password: 'pass', groupId: 1),
    ];
    when(mockService.getAll()).thenAnswer((_) async => mockPasswords);

    // Act
    await provider.loadPasswords();

    // Assert
    expect(provider.passwords, mockPasswords);
    expect(provider.isLoading, false);
    verify(mockService.getAll()).called(1);
  });

  test('should handle errors', () async {
    // Arrange
    when(mockService.getAll()).thenThrow(Exception('Database error'));

    // Act
    await provider.loadPasswords();

    // Assert
    expect(provider.errorMessage, isNotNull);
    expect(provider.passwords, isEmpty);
  });
}
```

## Common Gotchas

### 1. Calling `notifyListeners` during build

❌ **Wrong:**
```dart
class MyScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    context.read<PasswordProvider>().loadPasswords();  // Might call notifyListeners
  }
}
```

✅ **Right:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<PasswordProvider>().loadPasswords();
  });
}
```

### 2. Memory Leaks

Always dispose resources:

```dart
class PasswordProvider extends ChangeNotifier {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```

### 3. Provider Context Issues

❌ **Wrong:** Using BuildContext after async gap
```dart
Future<void> _save() async {
  await provider.savePassword();
  Navigator.pop(context);  // Context might be invalid
}
```

✅ **Right:** Check `mounted` or get provider before async
```dart
Future<void> _save() async {
  final provider = context.read<PasswordProvider>();
  await provider.savePassword();
  if (!mounted) return;
  Navigator.pop(context);
}
```

## Performance Tips

1. **Use `select` for specific properties**
   ```dart
   final count = context.select<PasswordProvider, int>((p) => p.passwords.length);
   ```

2. **Use `Consumer` for targeted rebuilds**
   ```dart
   Consumer<PasswordProvider>(
     builder: (context, provider, child) {
       return Text(provider.errorMessage ?? '');
     },
   )
   ```

3. **Avoid unnecessary `notifyListeners()`**
   ```dart
   // ❌ Bad: notifies even if value didn't change
   void setLoading(bool value) {
     _isLoading = value;
     notifyListeners();
   }

   // ✅ Good: only notifies if changed
   void setLoading(bool value) {
     if (_isLoading == value) return;
     _isLoading = value;
     notifyListeners();
   }
   ```

## Next Steps

- See [../services/CLAUDE.md](../services/CLAUDE.md) for service layer details
- See [../screens/CLAUDE.md](../screens/CLAUDE.md) for how screens consume providers
