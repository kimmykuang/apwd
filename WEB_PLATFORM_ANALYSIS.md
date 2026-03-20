# Web Platform Compatibility Analysis

## 🚨 Root Cause of Web UI Error

### Issue
When attempting to set up the master password in the Web version, the app crashes with an error.

**Location**: `lib/screens/setup_password_screen.dart` line 41-44
```dart
final success = await authProvider.setupMasterPassword(dbPath, _passwordController.text);
```

### Technical Root Cause

The app uses **sqflite_sqlcipher** which is **NOT compatible with Web platform**.

**Chain of failure**:
1. User enters master password → `setup_password_screen.dart:41`
2. Calls `authProvider.setupMasterPassword()` → `auth_provider.dart:19`
3. Calls `_authService.setupMasterPassword()` → `auth_service.dart:34`
4. Calls `_dbService.initialize(dbPath, dbKey)` → `auth_service.dart:68`
5. **FAILS**: Executes SQLCipher PRAGMA command → `database_service.dart:61`

```dart
// This line FAILS on Web platform
await db.rawQuery("PRAGMA key = \"x'$keyHex'\"");
```

**Why it fails**:
- Web browsers don't have SQLite
- `sqflite_sqlcipher` only works on native platforms (iOS, Android, macOS, Linux, Windows)
- Web uses IndexedDB for local storage, not SQLite
- SQLCipher encryption is not available on Web

---

## 📊 Platform Compatibility Matrix

| Component | iOS | Android | macOS | Windows | Linux | Web |
|-----------|-----|---------|-------|---------|-------|-----|
| **sqflite_sqlcipher** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **path_provider** | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ Limited |
| **flutter_secure_storage** | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ Browser storage |
| **local_auth** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **crypto (PBKDF2/AES)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **pointycastle** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**Legend**:
- ✅ Fully supported
- ⚠️ Limited/different functionality
- ❌ Not supported

---

## 🔍 Affected Files

### Core Database Layer (❌ Web Incompatible)
1. **lib/services/database_service.dart**
   - Line 2: `import 'package:sqflite_sqlcipher/sqflite.dart'`
   - Line 61: `await db.rawQuery("PRAGMA key = \"x'$keyHex'\"")`
   - Uses SQLCipher for encryption

2. **lib/services/auth_service.dart**
   - Line 68: Calls `_dbService.initialize(dbPath, dbKey)`
   - Line 76-78: Uses `flutter_secure_storage` (limited on Web)

3. **lib/screens/splash_screen.dart**
   - Line 35-36: Uses `path_provider` to get database path
   - Line 39: Checks if database file exists (Web uses IndexedDB, not files)

### Services Using Database (⚠️ Indirect Impact)
- `lib/services/password_service.dart` - All CRUD operations
- `lib/services/group_service.dart` - All group operations
- `lib/services/export_import_service.dart` - Backup/restore with file operations

### Providers (⚠️ Indirect Impact)
- `lib/providers/auth_provider.dart`
- `lib/providers/password_provider.dart`
- `lib/providers/group_provider.dart`
- `lib/providers/settings_provider.dart`

---

## 💡 Solution Options

### Option 1: Document Web as Unsupported (Quick Fix)
**Effort**: 1 hour
**Impact**: Users get clear error message instead of crash

**Changes**:
1. Add platform check in `main.dart`:
```dart
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  if (kIsWeb) {
    runApp(const UnsupportedPlatformApp());
    return;
  }
  runApp(const MyApp());
}
```

2. Create `UnsupportedPlatformApp` widget with explanation
3. Update README.md with platform requirements

**Pros**:
- Quick to implement
- Clear user communication
- No risk of data loss

**Cons**:
- No Web support

---

### Option 2: Implement Web-Specific Storage (Recommended)
**Effort**: 2-3 days
**Impact**: Full Web support with proper encryption

**Approach**: Use **drift** package (formerly moor)
- ✅ Cross-platform: Works on ALL platforms including Web
- ✅ Web support: Uses IndexedDB on Web, SQLite on native
- ✅ Encryption: Supports encrypted databases
- ✅ Type-safe queries
- ✅ Migration support

**Implementation steps**:
1. Add dependencies:
```yaml
dependencies:
  drift: ^2.14.0
  drift_web: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0

dev_dependencies:
  drift_dev: ^2.14.0
```

2. Create drift database schema:
```dart
@DriftDatabase(tables: [Groups, PasswordEntries, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);
}
```

3. Implement Web-specific initialization:
```dart
QueryExecutor _openConnection() {
  if (kIsWeb) {
    return WebDatabase('apwd_db');
  }
  // Native platforms...
}
```

4. Add Web encryption layer using Web Crypto API:
```dart
import 'dart:html' show window;
import 'package:web/web.dart';

// Use SubtleCrypto for encryption on Web
final crypto = window.crypto!.subtle;
```

**Pros**:
- Full cross-platform support
- Modern, maintained package
- Better developer experience
- Type-safe queries

**Cons**:
- Significant refactoring required
- Need to test all platforms
- Migration path for existing data

---

### Option 3: Hybrid Approach (Balanced)
**Effort**: 1-2 days
**Impact**: Limited Web support for demo/testing

**Approach**:
1. Keep SQLCipher for native platforms
2. Add platform detection
3. Implement simple Web storage using:
   - `shared_preferences` for settings
   - `indexed_db` package for encrypted data
   - Manual encryption using `crypto` package

**Implementation**:
```dart
abstract class StorageService {
  Future<void> initialize(String dbPath, Uint8List key);
  // ... other methods
}

class SqliteStorageService implements StorageService {
  // Current implementation using sqflite_sqlcipher
}

class WebStorageService implements StorageService {
  // IndexedDB + manual encryption
}

StorageService createStorageService() {
  if (kIsWeb) {
    return WebStorageService();
  }
  return SqliteStorageService();
}
```

**Pros**:
- Moderate effort
- Keeps existing native code
- Provides basic Web functionality

**Cons**:
- Two codebases to maintain
- Web version less feature-complete
- Potential divergence over time

---

## 🎯 Recommended Action Plan

### Immediate (Today)
1. **Add clear error message** for Web users
2. **Update documentation** with platform requirements
3. **Add platform check** to prevent crashes

### Short-term (This Week)
1. **Evaluate drift package** thoroughly
2. **Create proof-of-concept** with drift
3. **Test on all platforms**

### Long-term (Next Sprint)
1. **Migrate to drift** if POC successful
2. **Implement Web-specific encryption**
3. **Add platform-specific integration tests**
4. **Update deployment documentation**

---

## 📝 Current Workaround

For immediate testing, **use native platforms only**:

```bash
# iOS (requires Xcode)
flutter run -d <ios-simulator-id>

# Android (requires Android Studio)
flutter run -d <android-emulator-id>

# macOS (requires Xcode)
flutter run -d macos

# DO NOT USE
flutter run -d chrome  # ❌ WILL FAIL
```

---

## 🔗 References

- [drift package](https://pub.dev/packages/drift)
- [drift Web support](https://drift.simonbinder.eu/web/)
- [sqflite_sqlcipher limitations](https://pub.dev/packages/sqflite_sqlcipher)
- [Flutter platform detection](https://api.flutter.dev/flutter/foundation/kIsWeb-constant.html)

---

**Last Updated**: 2026-03-20
**Status**: Web platform currently NOT supported due to SQLCipher incompatibility
