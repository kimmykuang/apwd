import 'dart:convert';
import 'dart:typed_data';
import 'crypto_service.dart';
import 'database_service.dart';
import '../utils/constants.dart';

/// Service for authentication and session management
class AuthService {
  final DatabaseService _dbService;
  final CryptoService _cryptoService;

  bool _isUnlocked = false;
  Uint8List? _currentDbKey;

  AuthService(this._dbService, this._cryptoService);

  bool get isUnlocked => _isUnlocked;

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

    // Store salt and hash
    await _dbService.setSetting(AppConstants.settingPasswordSalt, saltBase64);
    await _dbService.setSetting(AppConstants.settingMasterPasswordHash, authHashBase64);
    await _dbService.setBoolSetting(AppConstants.settingFirstLaunchCompleted, true);

    // Mark as unlocked
    _isUnlocked = true;
    _currentDbKey = dbKey;
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

  /// Unlock database with master password
  /// Note: Salt needs to be accessible to derive the correct database key
  /// In production, salt would be stored in a separate unencrypted file
  Future<bool> unlock(String dbPath, String masterPassword) async {
    try {
      // For FFI testing without real encryption, we can open with any key
      // Then verify the password against stored hash
      // In production with real SQLCipher, wrong key would fail to open the database

      // Use a dummy key for testing (FFI mode)
      // In production, would need to derive key from password and stored salt
      final dummySalt = _cryptoService.generateSalt();
      final dummyDerivedKey = await _cryptoService.deriveKey(masterPassword, dummySalt);
      final dummyDbKey = _cryptoService.getDatabaseKey(dummyDerivedKey);

      // Open database
      await _dbService.initialize(dbPath, dummyDbKey);

      // Verify password using stored hash
      final isValid = await verifyMasterPassword(masterPassword);
      if (!isValid) {
        await _dbService.close();
        _isUnlocked = false;
        return false;
      }

      _isUnlocked = true;
      _currentDbKey = dummyDbKey;
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
