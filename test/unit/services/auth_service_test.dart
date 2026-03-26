import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apwd/services/database_service.dart';
import 'package:apwd/services/crypto_service.dart';
import 'package:apwd/services/auth_service.dart';
import 'package:apwd/utils/constants.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:io';
import 'dart:convert';

// Generate mocks
@GenerateMocks([LocalAuthentication, FlutterSecureStorage])
import 'auth_service_test.mocks.dart';

void main() {
  late DatabaseService dbService;
  late CryptoService cryptoService;
  late AuthService authService;
  late String testDbPath;
  late MockLocalAuthentication mockLocalAuth;
  late MockFlutterSecureStorage mockSecureStorage;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDbPath = '${Directory.systemTemp.path}/test_auth_${DateTime.now().millisecondsSinceEpoch}.db';
    dbService = DatabaseService(databaseFactory: databaseFactoryFfi);
    cryptoService = CryptoService();
    mockLocalAuth = MockLocalAuthentication();
    mockSecureStorage = MockFlutterSecureStorage();
    authService = AuthService(
      dbService,
      cryptoService,
      localAuth: mockLocalAuth,
      secureStorage: mockSecureStorage,
    );
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

      // Get the salt that was stored
      final saltBase64 = await dbService.getSetting(AppConstants.settingPasswordSalt);

      await dbService.close();

      // Mock secure storage to return the salt
      when(mockSecureStorage.read(key: 'password_salt')).thenAnswer((_) async => saltBase64);

      // Reopen with correct password
      final success = await authService.unlock(testDbPath, 'test_password');

      expect(success, isTrue);
      expect(authService.isUnlocked, isTrue);
    });

    test('should fail to unlock with wrong password', () async {
      await authService.setupMasterPassword(testDbPath, 'correct_password');

      // Get the salt that was stored
      final saltBase64 = await dbService.getSetting(AppConstants.settingPasswordSalt);

      await dbService.close();

      // Mock secure storage to return the salt
      when(mockSecureStorage.read(key: 'password_salt')).thenAnswer((_) async => saltBase64);

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

  group('AuthService - Biometric', () {
    test('should check if biometric is available', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);

      final isAvailable = await authService.checkBiometric();

      expect(isAvailable, isTrue);
      verify(mockLocalAuth.canCheckBiometrics).called(1);
    });

    test('should return false if biometric not available', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final isAvailable = await authService.checkBiometric();

      expect(isAvailable, isFalse);
    });

    test('should authenticate with biometric successfully', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => true);

      final success = await authService.authenticateWithBiometric();

      expect(success, isTrue);
      verify(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).called(1);
    });

    test('should fail authentication if biometric not available', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final success = await authService.authenticateWithBiometric();

      expect(success, isFalse);
      verifyNever(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      ));
    });

    test('should store and retrieve biometric preference', () async {
      await authService.setupMasterPassword(testDbPath, 'password');

      await authService.setBiometricEnabled(true);
      final enabled = await authService.getBiometricEnabled();

      expect(enabled, isTrue);
    });
  });

  group('AuthService - Auto-lock', () {
    test('should track last activity time when unlocking', () async {
      await authService.setupMasterPassword(testDbPath, 'test_password');

      expect(authService.lastActivityTime, isNotNull);
    });

    test('should start auto-lock timer', () async {
      await authService.setupMasterPassword(testDbPath, 'test_password');

      bool lockCalled = false;
      await authService.startAutoLockTimer(() {
        lockCalled = true;
      });

      expect(authService.lastActivityTime, isNotNull);
      // Timer is set but not expired yet
      expect(lockCalled, isFalse);
    });

    test('should reset auto-lock timer on activity', () async {
      await authService.setupMasterPassword(testDbPath, 'test_password');

      final firstTime = authService.lastActivityTime;
      await Future.delayed(Duration(milliseconds: 100));

      await authService.resetAutoLockTimer(() {});

      expect(authService.lastActivityTime, isNot(equals(firstTime)));
    });

    test('should stop auto-lock timer', () async {
      await authService.setupMasterPassword(testDbPath, 'test_password');

      bool lockCalled = false;
      await authService.startAutoLockTimer(() {
        lockCalled = true;
      });

      authService.stopAutoLockTimer();

      // Wait a bit to ensure timer doesn't fire
      await Future.delayed(Duration(milliseconds: 100));
      expect(lockCalled, isFalse);
    });

    test('should clear activity time when locking', () async {
      await authService.setupMasterPassword(testDbPath, 'test_password');

      expect(authService.lastActivityTime, isNotNull);

      authService.lock();

      expect(authService.lastActivityTime, isNull);
      expect(authService.isUnlocked, isFalse);
    });
  });
}
