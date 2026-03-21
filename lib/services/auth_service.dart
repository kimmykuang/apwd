import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'crypto_service.dart';
import 'database_service.dart';
import '../utils/constants.dart';

/// Service for authentication and session management
class AuthService {
  final DatabaseService _dbService;
  final CryptoService _cryptoService;
  final LocalAuthentication? _localAuth;
  final FlutterSecureStorage? _secureStorage;

  bool _isUnlocked = false;
  Uint8List? _currentDbKey;
  DateTime? _lastActivityTime;
  Timer? _autoLockTimer;

  AuthService(
    this._dbService,
    this._cryptoService, {
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  bool get isUnlocked => _isUnlocked;
  DateTime? get lastActivityTime => _lastActivityTime;

  /// Setup master password for first time use
  Future<void> setupMasterPassword(String dbPath, String masterPassword) async {
    // Check if database is already initialized
    bool alreadyInitialized = false;
    try {
      final db = _dbService.database;
      if (db.isOpen) {
        alreadyInitialized = true;
      }
    } catch (e) {
      // Database not initialized, which is expected for first setup
      alreadyInitialized = false;
    }

    if (alreadyInitialized) {
      throw StateError('Database already initialized');
    }

    // Clear any old salt from secure storage (in case of reinstall)
    if (_secureStorage != null) {
      try {
        await _secureStorage!.delete(key: 'password_salt');
        print('[AUTH] Cleared old salt from secure storage');
      } catch (e) {
        // Ignore errors when clearing old data
        print('[AUTH] Error clearing old salt: $e');
      }
    }

    // Generate salt
    final salt = _cryptoService.generateSalt();
    final saltBase64 = base64.encode(salt);
    print('[AUTH] Generated new salt: ${saltBase64.substring(0, 10)}...');

    // Derive key from password
    final derivedKey = await _cryptoService.deriveKey(masterPassword, salt);
    final dbKey = _cryptoService.getDatabaseKey(derivedKey);
    final authKey = _cryptoService.getAuthKey(derivedKey);

    // Compute auth hash for verification
    final authHash = _cryptoService.computeAuthHash(authKey);
    final authHashBase64 = base64.encode(authHash);
    print('[AUTH] Computed auth hash: ${authHashBase64.substring(0, 10)}...');

    // Convert dbKey to hex string for SQLCipher
    final dbKeyHex = dbKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // Initialize database with encryption
    await _dbService.initialize(dbPath, dbKey);
    print('[AUTH] Database initialized');

    // Store salt and hash in database
    await _dbService.setSetting(AppConstants.settingPasswordSalt, saltBase64);
    await _dbService.setSetting(AppConstants.settingMasterPasswordHash, authHashBase64);
    await _dbService.setBoolSetting(AppConstants.settingFirstLaunchCompleted, true);
    print('[AUTH] Salt and hash stored in database');

    // CRITICAL: Store salt in secure storage for access when database is locked
    if (_secureStorage != null) {
      try {
        print('[AUTH] Attempting to store salt in secure storage...');
        await _secureStorage!.write(
          key: 'password_salt',
          value: saltBase64,
          aOptions: const AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );
        // Verify it was stored
        final readBack = await _secureStorage!.read(key: 'password_salt');
        print('[AUTH] Salt stored and verified in secure storage: ${readBack != null}');
        if (readBack == null) {
          throw Exception('Salt storage verification failed - secure storage may not be working');
        }
      } catch (e) {
        print('[AUTH] CRITICAL ERROR storing salt in secure storage: $e');
        // This is critical - we must not continue without the salt
        throw Exception('Failed to store salt in secure storage: $e');
      }
    } else {
      throw Exception('Secure storage is not available');
    }

    // Mark as unlocked
    _isUnlocked = true;
    _currentDbKey = dbKey;
    _lastActivityTime = DateTime.now();
  }

  /// Verify master password against stored hash
  Future<bool> verifyMasterPassword(String password) async {
    // Get stored salt and hash
    final saltBase64 = await _dbService.getSetting(AppConstants.settingPasswordSalt);
    final storedHashBase64 = await _dbService.getSetting(AppConstants.settingMasterPasswordHash);

    print('[AUTH] verifyMasterPassword - saltBase64 from DB: ${saltBase64 != null ? saltBase64.substring(0, 10) + "..." : "null"}');
    print('[AUTH] verifyMasterPassword - storedHashBase64 from DB: ${storedHashBase64 != null ? storedHashBase64.substring(0, 10) + "..." : "null"}');

    if (saltBase64 == null || storedHashBase64 == null) {
      throw StateError('Master password not set up');
    }

    final salt = base64.decode(saltBase64);
    final storedHash = base64.decode(storedHashBase64);

    // Derive key from provided password
    final derivedKey = await _cryptoService.deriveKey(password, salt);
    final authKey = _cryptoService.getAuthKey(derivedKey);

    // Compute hash and compare
    final computedHash = _cryptoService.computeAuthHash(authKey);

    print('[AUTH] Hash comparison - computed: ${base64.encode(computedHash).substring(0, 10)}..., stored: ${storedHashBase64.substring(0, 10)}...');

    return _bytesEqual(computedHash, storedHash);
  }

  /// Get database key from password
  Future<Uint8List> getDatabaseKey(String password) async {
    final saltBase64 = await _dbService.getSetting(AppConstants.settingPasswordSalt);
    if (saltBase64 == null) {
      throw StateError('Master password not set up');
    }

    final salt = base64.decode(saltBase64);
    final derivedKey = await _cryptoService.deriveKey(password, salt);
    return _cryptoService.getDatabaseKey(derivedKey);
  }

  /// Check if biometric authentication is available on this device
  Future<bool> checkBiometric() async {
    if (_localAuth == null) return false;

    try {
      final canAuthenticateWithBiometrics = await _localAuth!.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth!.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate using biometric (fingerprint, face ID, etc.)
  Future<bool> authenticateWithBiometric() async {
    if (_localAuth == null) {
      print('[AUTH] LocalAuthentication not available');
      return false;
    }

    try {
      print('[AUTH] Checking if biometric is available...');
      final isAvailable = await checkBiometric();
      if (!isAvailable) {
        print('[AUTH] Biometric not available');
        return false;
      }

      print('[AUTH] Calling authenticate...');
      final result = await _localAuth!.authenticate(
        localizedReason: 'Please authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );
      print('[AUTH] Authentication result: $result');
      return result;
    } catch (e) {
      print('[AUTH] Error in authenticateWithBiometric: $e');
      return false;
    }
  }

  /// Store biometric preference in settings
  Future<void> setBiometricEnabled(bool enabled) async {
    // Store in database
    await _dbService.setBoolSetting(AppConstants.settingBiometricEnabled, enabled);

    // Also store in secure storage so we can access it when database is locked
    if (_secureStorage != null) {
      await _secureStorage!.write(
        key: 'biometric_enabled',
        value: enabled.toString(),
      );
      print('[AUTH] Biometric enabled status stored: $enabled');
    }
  }

  /// Get biometric preference from settings
  /// Checks secure storage first (works when DB is locked), falls back to database
  Future<bool> getBiometricEnabled() async {
    // Try secure storage first (works when database is locked)
    if (_secureStorage != null) {
      try {
        final value = await _secureStorage!.read(key: 'biometric_enabled');
        if (value != null) {
          print('[AUTH] Biometric enabled from secure storage: $value');
          return value.toLowerCase() == 'true';
        }
      } catch (e) {
        print('[AUTH] Error reading biometric enabled from secure storage: $e');
      }
    }

    // Fall back to database only if unlocked
    if (_isUnlocked) {
      try {
        final enabled = await _dbService.getBoolSetting(
          AppConstants.settingBiometricEnabled,
          defaultValue: false,
        ) ?? false;
        print('[AUTH] Biometric enabled from database: $enabled');
        return enabled;
      } catch (e) {
        print('[AUTH] Error reading biometric enabled from database: $e');
      }
    } else {
      print('[AUTH] Database locked, cannot read from database');
    }

    return false;
  }

  /// Store encrypted master password for biometric unlock
  /// This should only be called when biometric is enabled
  Future<void> storeBiometricPassword(String masterPassword) async {
    print('[AUTH] storeBiometricPassword called');
    if (_secureStorage == null) {
      print('[AUTH] Secure storage is null, cannot store password');
      return;
    }

    // For simplicity, we store the password encrypted with a device-specific key
    // In production, you might want to use Android Keystore/iOS Keychain with biometric requirement
    try {
      print('[AUTH] Writing password to secure storage...');
      await _secureStorage!.write(
        key: 'biometric_password',
        value: masterPassword,
        aOptions: const AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
        ),
      );
      print('[AUTH] Password stored successfully');

      // Verify password was stored correctly
      final storedPassword = await _secureStorage!.read(key: 'biometric_password');
      print('[AUTH] Verification read: ${storedPassword != null ? "SUCCESS" : "FAILED"}');
    } catch (e) {
      print('[AUTH] Error storing biometric password: $e');
      rethrow;
    }
  }

  /// Retrieve stored master password for biometric unlock
  Future<String?> getBiometricPassword() async {
    if (_secureStorage == null) return null;

    try {
      return await _secureStorage!.read(key: 'biometric_password');
    } catch (e) {
      print('[AUTH] Error reading biometric password: $e');
      return null;
    }
  }

  /// Delete stored biometric password
  Future<void> deleteBiometricPassword() async {
    if (_secureStorage == null) return;

    try {
      await _secureStorage!.delete(key: 'biometric_password');
      // Also delete the enabled flag
      await _secureStorage!.delete(key: 'biometric_enabled');
      print('[AUTH] Biometric password and enabled flag deleted');
    } catch (e) {
      print('[AUTH] Error deleting biometric password: $e');
    }
  }

  /// Unlock with biometric authentication
  /// Returns true if unlocked successfully, false otherwise
  Future<bool> unlockWithBiometric(String dbPath) async {
    try {
      // First check if biometric is enabled
      final biometricEnabled = await getBiometricEnabled();
      if (!biometricEnabled) {
        print('[AUTH] Biometric not enabled');
        return false;
      }

      // Authenticate with biometric
      final authenticated = await authenticateWithBiometric();
      if (!authenticated) {
        print('[AUTH] Biometric authentication failed');
        return false;
      }

      // Get stored password
      final password = await getBiometricPassword();
      if (password == null) {
        print('[AUTH] No biometric password stored');
        return false;
      }

      // Unlock with the stored password
      return await unlock(dbPath, password);
    } catch (e) {
      print('[AUTH] Error in unlockWithBiometric: $e');
      return false;
    }
  }

  /// Start auto-lock timer with configured timeout
  Future<void> startAutoLockTimer(Function() onLock) async {
    _autoLockTimer?.cancel();
    _lastActivityTime = DateTime.now();

    final timeout = await _dbService.getIntSetting(
      AppConstants.settingAutoLockTimeout,
      defaultValue: AppConstants.defaultAutoLockTimeout,
    ) ?? AppConstants.defaultAutoLockTimeout;

    if (timeout > 0) {
      _autoLockTimer = Timer(Duration(seconds: timeout), () {
        lock();
        onLock();
      });
    }
  }

  /// Reset auto-lock timer (call on user activity)
  Future<void> resetAutoLockTimer(Function() onLock) async {
    _lastActivityTime = DateTime.now();
    await startAutoLockTimer(onLock);
  }

  /// Stop auto-lock timer
  void stopAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
  }

  /// Unlock database with master password
  /// Note: Salt is retrieved from secure storage or database
  Future<bool> unlock(String dbPath, String masterPassword) async {
    try {
      // First, try to get salt from secure storage (available before DB is open)
      String? saltBase64;
      if (_secureStorage != null) {
        saltBase64 = await _secureStorage!.read(key: 'password_salt');
        print('[AUTH] Salt from secure storage: ${saltBase64 != null ? "found (${saltBase64.substring(0, 10)}...)" : "null"}');
      }

      // If not in secure storage, we cannot proceed (circular dependency)
      if (saltBase64 == null) {
        print('[AUTH] CRITICAL: Salt not found in secure storage');
        print('[AUTH] This likely means the app was reinstalled or secure storage was cleared');
        throw StateError(
          'Password salt not found in secure storage. '
          'This typically happens after app reinstall. '
          'Please reinstall the app and set up a new master password.'
        );
      }

      print('[AUTH] Using salt: ${saltBase64.substring(0, 10)}...');

      // Derive the actual key from master password and salt
      final salt = base64.decode(saltBase64);
      final derivedKey = await _cryptoService.deriveKey(masterPassword, salt);
      final dbKey = _cryptoService.getDatabaseKey(derivedKey);

      print('[AUTH] Opening database with derived key...');
      // Open database with the derived key
      await _dbService.initialize(dbPath, dbKey);

      print('[AUTH] Database opened, verifying password...');
      // Verify password using stored hash
      final isValid = await verifyMasterPassword(masterPassword);
      print('[AUTH] Password verification result: $isValid');
      if (!isValid) {
        await _dbService.close();
        _isUnlocked = false;
        return false;
      }

      _isUnlocked = true;
      _currentDbKey = dbKey;
      _lastActivityTime = DateTime.now();
      print('[AUTH] Unlock successful!');
      return true;
    } catch (e) {
      print('[AUTH] Unlock failed with exception: $e');
      print('[AUTH] Exception stacktrace: ${StackTrace.current}');
      try {
        await _dbService.close();
      } catch (_) {}
      _isUnlocked = false;
      return false;
    }
  }

  /// Lock the application
  Future<void> lock() async {
    print('[AUTH] Locking application...');
    _isUnlocked = false;
    _currentDbKey = null;
    _lastActivityTime = null;
    stopAutoLockTimer();

    // Close database connection when locking
    try {
      await _dbService.close();
      print('[AUTH] Database closed successfully');
    } catch (e) {
      // Ignore errors when closing - database might already be closed
      print('[AUTH] Error closing database: $e');
    }
  }

  /// Compare two byte arrays
  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
