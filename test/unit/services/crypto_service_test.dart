import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:apwd/services/crypto_service.dart';
import 'package:apwd/utils/constants.dart';

void main() {
  late CryptoService cryptoService;

  setUp(() {
    cryptoService = CryptoService();
  });

  group('CryptoService - PBKDF2 Key Derivation', () {
    test('generateSalt returns Uint8List of correct length (32 bytes)', () {
      // Act
      final salt = cryptoService.generateSalt();

      // Assert
      expect(salt, isA<Uint8List>());
      expect(salt.length, equals(AppConstants.saltLength));
      expect(salt.length, equals(32));
    });

    test('generateSalt returns different salts each time', () {
      // Act
      final salt1 = cryptoService.generateSalt();
      final salt2 = cryptoService.generateSalt();
      final salt3 = cryptoService.generateSalt();

      // Assert
      expect(salt1, isNot(equals(salt2)));
      expect(salt2, isNot(equals(salt3)));
      expect(salt1, isNot(equals(salt3)));
    });

    test('deriveKey returns deterministic key from password and salt',
        () async {
      // Arrange
      const password = 'testPassword123!';
      final salt = cryptoService.generateSalt();

      // Act
      final key1 = await cryptoService.deriveKey(password, salt);
      final key2 = await cryptoService.deriveKey(password, salt);

      // Assert
      expect(key1, isA<Uint8List>());
      expect(key1.length, equals(AppConstants.keyLength));
      expect(key1.length, equals(64));
      expect(key1, equals(key2)); // Same password + salt = same key
    });

    test('deriveKey returns different keys for different passwords', () async {
      // Arrange
      const password1 = 'testPassword123!';
      const password2 = 'differentPassword456!';
      final salt = cryptoService.generateSalt();

      // Act
      final key1 = await cryptoService.deriveKey(password1, salt);
      final key2 = await cryptoService.deriveKey(password2, salt);

      // Assert
      expect(key1, isNot(equals(key2)));
    });

    test('deriveKey returns different keys for different salts', () async {
      // Arrange
      const password = 'testPassword123!';
      final salt1 = cryptoService.generateSalt();
      final salt2 = cryptoService.generateSalt();

      // Act
      final key1 = await cryptoService.deriveKey(password, salt1);
      final key2 = await cryptoService.deriveKey(password, salt2);

      // Assert
      expect(key1, isNot(equals(key2)));
    });

    test('deriveKey uses correct PBKDF2 parameters', () async {
      // Arrange
      const password = 'testPassword123!';
      final salt = cryptoService.generateSalt();

      // Act
      final key = await cryptoService.deriveKey(password, salt);

      // Assert
      // Verify key length is 64 bytes (512 bits)
      expect(key.length, equals(64));

      // Verify that the derived key is not all zeros
      final isNotAllZeros = key.any((byte) => byte != 0);
      expect(isNotAllZeros, isTrue);
    });

    test('should split derived key into db key and auth key', () async {
      // Arrange
      const password = 'test_password';
      final salt = cryptoService.generateSalt();

      // Act
      final derivedKey = await cryptoService.deriveKey(password, salt);
      final dbKey = cryptoService.getDatabaseKey(derivedKey);
      final authKey = cryptoService.getAuthKey(derivedKey);

      // Assert
      expect(dbKey.length, 32);
      expect(authKey.length, 32);
      expect(dbKey, equals(derivedKey.sublist(0, 32)));
      expect(authKey, equals(derivedKey.sublist(32, 64)));
    });

    test('should compute auth hash from auth key', () {
      // Arrange
      final authKey = Uint8List.fromList(List.generate(32, (i) => i));

      // Act
      final hash1 = cryptoService.computeAuthHash(authKey);
      final hash2 = cryptoService.computeAuthHash(authKey);

      // Assert
      expect(hash1, equals(hash2));
      expect(hash1.length, 32); // SHA-256 output
    });
  });

  group('CryptoService - AES Encryption', () {
    test('should encrypt and decrypt text successfully', () {
      // Arrange
      const plaintext = 'my_secret_password_123';
      final key = Uint8List.fromList(List.generate(32, (i) => i));

      // Act
      final encrypted = cryptoService.encryptText(plaintext, key);
      final decrypted = cryptoService.decryptText(encrypted, key);

      // Assert
      expect(encrypted, isNot(equals(plaintext)));
      expect(decrypted, equals(plaintext));
    });

    test('should produce different ciphertext for same plaintext', () {
      // Arrange
      const plaintext = 'Hello, World!';
      final key = Uint8List.fromList(List.generate(32, (i) => i));

      // Act
      final ciphertext1 = cryptoService.encryptText(plaintext, key);
      final ciphertext2 = cryptoService.encryptText(plaintext, key);

      // Assert
      expect(ciphertext1, isNot(equals(ciphertext2)));
      // But both should decrypt to the same plaintext
      final decrypted1 = cryptoService.decryptText(ciphertext1, key);
      final decrypted2 = cryptoService.decryptText(ciphertext2, key);
      expect(decrypted1, equals(plaintext));
      expect(decrypted2, equals(plaintext));
    });

    test('should fail to decrypt with wrong key', () {
      // Arrange
      const plaintext = 'Hello, World!';
      final key1 = Uint8List.fromList(List.generate(32, (i) => i));
      final key2 = Uint8List.fromList(List.generate(32, (i) => i + 1));

      // Act
      final ciphertext = cryptoService.encryptText(plaintext, key1);

      // Assert
      expect(
        () => cryptoService.decryptText(ciphertext, key2),
        throwsA(isA<CryptoException>()),
      );
    });

    test('should handle empty string encryption', () {
      // Arrange
      const plaintext = '';
      final key = Uint8List.fromList(List.generate(32, (i) => i));

      // Act
      final ciphertext = cryptoService.encryptText(plaintext, key);
      final decrypted = cryptoService.decryptText(ciphertext, key);

      // Assert
      expect(decrypted, equals(plaintext));
    });

    test('should handle unicode characters', () {
      // Arrange
      const plaintext = '密码测试 🔐 Пароль';
      final key = Uint8List.fromList(List.generate(32, (i) => i));

      // Act
      final ciphertext = cryptoService.encryptText(plaintext, key);
      final decrypted = cryptoService.decryptText(ciphertext, key);

      // Assert
      expect(decrypted, equals(plaintext));
    });

    test('should handle long text', () {
      // Arrange
      final plaintext = 'A' * 10000; // 10,000 characters
      final key = Uint8List.fromList(List.generate(32, (i) => i));

      // Act
      final ciphertext = cryptoService.encryptText(plaintext, key);
      final decrypted = cryptoService.decryptText(ciphertext, key);

      // Assert
      expect(decrypted, equals(plaintext));
    });

    test('encrypted text should be base64 encoded', () {
      // Arrange
      const plaintext = 'Test';
      final key = Uint8List.fromList(List.generate(32, (i) => i));

      // Act
      final ciphertext = cryptoService.encryptText(plaintext, key);

      // Assert
      expect(ciphertext, isA<String>());
      // Should be valid base64 (no exception when decoding)
      expect(() => base64Decode(ciphertext), returnsNormally);
    });
  });
}
