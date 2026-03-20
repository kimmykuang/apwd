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

    // Generate salt
    final salt = _cryptoService.generateSalt();
    final saltBase64 = base64.encode(salt);

    // Derive key from password
    final derivedKey = await _cryptoService.deriveKey(masterPassword, salt);
    final dbKey = _cryptoService.getDatabaseKey(derivedKey);
    final authKey = _cryptoService.getAuthKey(derivedKey);

    // Compute auth hash for verification
    final authHash = _cryptoService.computeAuthHash(authKey);
    final authHashBase64 = base64.encode(authHash);

    // Convert dbKey to hex string for SQLCipher
    final dbKeyHex = dbKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    // Initialize database with encryption
    await _dbService.initialize(dbPath, dbKey);

    // Store salt and hash in database
    await _dbService.setSetting(AppConstants.settingPasswordSalt, saltBase64);
    await _dbService.setSetting(AppConstants.settingMasterPasswordHash, authHashBase64);
    await _dbService.setBoolSetting(AppConstants.settingFirstLaunchCompleted, true);

    // Also store salt in secure storage for access before database is unlocked
    if (_secureStorage != null) {
      await _secureStorage!.write(key: 'password_salt', value: saltBase64);
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
    if (_localAuth == null) return false;

    try {
      final isAvailable = await checkBiometric();
      if (!isAvailable) return false;

      return await _localAuth!.authenticate(
        localizedReason: 'Please authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Store biometric preference in settings
  Future<void> setBiometricEnabled(bool enabled) async {
    await _dbService.setBoolSetting(AppConstants.settingBiometricEnabled, enabled);
  }

  /// Get biometric preference from settings
  Future<bool> getBiometricEnabled() async {
    return await _dbService.getBoolSetting(
      AppConstants.settingBiometricEnabled,
      defaultValue: false,
    ) ?? false;
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
      }

      // If not in secure storage, try opening with dummy key to read from database
      if (saltBase64 == null) {
        // Use a temporary key to open the database and read salt
        final tempSalt = _cryptoService.generateSalt();
        final tempDerivedKey = await _cryptoService.deriveKey('temp', tempSalt);
        final tempDbKey = _cryptoService.getDatabaseKey(tempDerivedKey);

        try {
          await _dbService.initialize(dbPath, tempDbKey);
          saltBase64 = await _dbService.getSetting(AppConstants.settingPasswordSalt);
          await _dbService.close();
        } catch (e) {
          // Failed to read salt from database
          await _dbService.close().catchError((_) {});
          throw StateError('Password salt not found');
        }
      }

      if (saltBase64 == null) {
        throw StateError('Password salt not found');
      }

      // Derive the actual key from master password and salt
      final salt = base64.decode(saltBase64);
      final derivedKey = await _cryptoService.deriveKey(masterPassword, salt);
      final dbKey = _cryptoService.getDatabaseKey(derivedKey);

      // Open database with the derived key
      await _dbService.initialize(dbPath, dbKey);

      // Verify password using stored hash
      final isValid = await verifyMasterPassword(masterPassword);
      if (!isValid) {
        await _dbService.close();
        _isUnlocked = false;
        return false;
      }

      _isUnlocked = true;
      _currentDbKey = dbKey;
      _lastActivityTime = DateTime.now();
      return true;
    } catch (e) {
      try {
        await _dbService.close();
      } catch (_) {}
      _isUnlocked = false;
      return false;
    }
  }

  /// Lock the application
  void lock() {
    _isUnlocked = false;
    _currentDbKey = null;
    _lastActivityTime = null;
    stopAutoLockTimer();
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
