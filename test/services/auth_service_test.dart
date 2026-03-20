import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apwd/services/database_service.dart';
import 'package:apwd/services/crypto_service.dart';
import 'package:apwd/services/auth_service.dart';
import 'package:apwd/utils/constants.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  late DatabaseService dbService;
  late CryptoService cryptoService;
  late AuthService authService;
  late String testDbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDbPath = '${Directory.systemTemp.path}/test_auth_${DateTime.now().millisecondsSinceEpoch}.db';
    dbService = DatabaseService(databaseFactory: databaseFactoryFfi);
    cryptoService = CryptoService();
    authService = AuthService(dbService, cryptoService);
  });

  tearDown(() async {
    await dbService.close();
    try {
      await File(testDbPath).delete();
    } catch (_) {}
  });

  group('AuthService - Setup', () {
    test('should setup master password successfully', () async {
      await authService.setupMasterPassword(testDbPath, 'my_secure_password');

      // Verify database is initialized
      expect(dbService.database, isNotNull);

      // Verify salt is stored
      final salt = await dbService.getSetting(AppConstants.settingPasswordSalt);
      expect(salt, isNotNull);

      // Verify hash is stored
      final hash = await dbService.getSetting(AppConstants.settingMasterPasswordHash);
      expect(hash, isNotNull);
    });

    test('should verify correct master password', () async {
      await authService.setupMasterPassword(testDbPath, 'correct_password');

      final isValid = await authService.verifyMasterPassword('correct_password');

      expect(isValid, isTrue);
    });

    test('should reject incorrect master password', () async {
      await authService.setupMasterPassword(testDbPath, 'correct_password');

      final isValid = await authService.verifyMasterPassword('wrong_password');

      expect(isValid, isFalse);
    });

    test('should derive consistent database key from password', () async {
      await authService.setupMasterPassword(testDbPath, 'my_password');

      final key1 = await authService.getDatabaseKey('my_password');
      final key2 = await authService.getDatabaseKey('my_password');

      expect(key1, equals(key2));
    });

    test('should prevent setup when already initialized', () async {
      await authService.setupMasterPassword(testDbPath, 'password');

      expect(
        () => authService.setupMasterPassword(testDbPath, 'password'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AuthService - Unlock', () {
    test('should unlock with correct password', () async {
      await authService.setupMasterPassword(testDbPath, 'test_password');
      await dbService.close();

      // Reopen with correct password
      final success = await authService.unlock(testDbPath, 'test_password');

      expect(success, isTrue);
      expect(authService.isUnlocked, isTrue);
    });

    test('should fail to unlock with wrong password', () async {
      await authService.setupMasterPassword(testDbPath, 'correct_password');
      await dbService.close();

      final success = await authService.unlock(testDbPath, 'wrong_password');

      expect(success, isFalse);
      expect(authService.isUnlocked, isFalse);
    });

    test('should lock and clear sensitive data', () async {
      await authService.setupMasterPassword(testDbPath, 'password');

      authService.lock();

      expect(authService.isUnlocked, isFalse);
    });
  });
}
