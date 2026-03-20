import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart' as crypto_pkg;
import 'package:apwd/utils/constants.dart';

/// Exception thrown when crypto operations fail
class CryptoException implements Exception {
  final String message;
  CryptoException(this.message);

  @override
  String toString() => 'CryptoException: $message';
}

/// Service for cryptographic operations including key derivation and encryption.
class CryptoService {
  /// Generates a cryptographically secure random salt.
  ///
  /// Returns a [Uint8List] of [AppConstants.saltLength] (32) random bytes.
  Uint8List generateSalt() {
    final secureRandom = _createSecureRandom();
    final salt = Uint8List(AppConstants.saltLength);

    for (int i = 0; i < salt.length; i++) {
      salt[i] = secureRandom.nextUint8();
    }

    return salt;
  }

  /// Derives a cryptographic key from a password and salt using PBKDF2.
  ///
  /// Uses PBKDF2 with HMAC-SHA256, [AppConstants.pbkdf2Iterations] (100,000) iterations,
  /// and produces a [AppConstants.keyLength] (64) byte key.
  ///
  /// [password] - The master password to derive the key from
  /// [salt] - The salt to use for key derivation
  ///
  /// Returns a [Future<Uint8List>] containing the derived key.
  Future<Uint8List> deriveKey(String password, Uint8List salt) async {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));

    final params = Pbkdf2Parameters(
      salt,
      AppConstants.pbkdf2Iterations,
      AppConstants.keyLength,
    );

    derivator.init(params);

    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    final key = derivator.process(passwordBytes);

    return key;
  }

  /// Extract database encryption key from derived key.
  ///
  /// Returns the first 32 bytes of the derived key for database encryption.
  ///
  /// [derivedKey] - The 64-byte derived key from PBKDF2
  ///
  /// Returns a [Uint8List] containing the 32-byte database key.
  Uint8List getDatabaseKey(Uint8List derivedKey) {
    return Uint8List.fromList(derivedKey.sublist(0, 32));
  }

  /// Extract authentication key from derived key.
  ///
  /// Returns the last 32 bytes of the derived key for authentication.
  ///
  /// [derivedKey] - The 64-byte derived key from PBKDF2
  ///
  /// Returns a [Uint8List] containing the 32-byte authentication key.
  Uint8List getAuthKey(Uint8List derivedKey) {
    return Uint8List.fromList(derivedKey.sublist(32, 64));
  }

  /// Compute SHA-256 hash of auth key for storage.
  ///
  /// Computes a SHA-256 hash of the authentication key for secure storage.
  ///
  /// [authKey] - The 32-byte authentication key
  ///
  /// Returns a [Uint8List] containing the 32-byte SHA-256 hash.
  Uint8List computeAuthHash(Uint8List authKey) {
    return Uint8List.fromList(crypto_pkg.sha256.convert(authKey).bytes);
  }

  /// Encrypts plaintext using AES-256-CBC encryption.
  ///
  /// Uses AES-256 in CBC mode with PKCS7 padding. A random 16-byte IV is
  /// generated for each encryption and prepended to the ciphertext.
  ///
  /// [plaintext] - The text to encrypt
  /// [key] - The 32-byte encryption key
  ///
  /// Returns a [String] containing the base64 encoded IV+ciphertext.
  String encryptText(String plaintext, Uint8List key) {
    if (key.length != 32) {
      throw ArgumentError('Key must be 32 bytes for AES-256');
    }

    // Generate random 16-byte IV
    final iv = _generateIV();

    // Convert plaintext to bytes
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

    // Handle empty plaintext - just return IV + empty ciphertext
    if (plaintextBytes.isEmpty) {
      final output = Uint8List(iv.length + 16); // IV + one padded block
      output.setRange(0, iv.length, iv);

      // Encrypt a block of padding (16 bytes of 0x10 per PKCS7)
      final cipher = CBCBlockCipher(AESEngine());
      cipher.init(true, ParametersWithIV(KeyParameter(key), iv));

      final paddingBlock = Uint8List(16);
      for (int i = 0; i < 16; i++) {
        paddingBlock[i] = 16; // PKCS7 padding for empty input
      }

      final encryptedPadding = Uint8List(16);
      cipher.processBlock(paddingBlock, 0, encryptedPadding, 0);

      output.setRange(iv.length, output.length, encryptedPadding);
      return base64.encode(output);
    }

    // Initialize AES cipher
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    );

    cipher.init(true, params); // true = encrypt

    // Encrypt the data
    final ciphertextBytes = cipher.process(plaintextBytes);

    // Prepend IV to ciphertext
    final output = Uint8List(iv.length + ciphertextBytes.length);
    output.setRange(0, iv.length, iv);
    output.setRange(iv.length, output.length, ciphertextBytes);

    // Return base64 encoded result
    return base64.encode(output);
  }

  /// Decrypts ciphertext using AES-256-CBC decryption.
  ///
  /// Uses AES-256 in CBC mode with PKCS7 padding. The IV is expected to be
  /// prepended to the ciphertext.
  ///
  /// [ciphertext] - The base64 encoded IV+ciphertext to decrypt
  /// [key] - The 32-byte encryption key
  ///
  /// Returns a [String] containing the decrypted plaintext.
  /// Throws [CryptoException] if decryption fails (e.g., wrong key, corrupted data).
  String decryptText(String ciphertext, Uint8List key) {
    if (key.length != 32) {
      throw ArgumentError('Key must be 32 bytes for AES-256');
    }

    try {
      // Decode base64
      final data = base64.decode(ciphertext);

      if (data.length < 16) {
        throw CryptoException('Invalid ciphertext: too short');
      }

      // Extract IV and ciphertext
      final iv = data.sublist(0, 16);
      final ciphertextBytes = data.sublist(16);

      // Initialize AES cipher
      final cipher = PaddedBlockCipherImpl(
        PKCS7Padding(),
        CBCBlockCipher(AESEngine()),
      );

      final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      );

      cipher.init(false, params); // false = decrypt

      // Decrypt the data
      final plaintextBytes = cipher.process(ciphertextBytes);

      // Convert bytes to string
      return utf8.decode(plaintextBytes);
    } catch (e) {
      throw CryptoException('Decryption failed: ${e.toString()}');
    }
  }

  /// Generates a random 16-byte IV for AES encryption.
  ///
  /// Returns a [Uint8List] of 16 random bytes.
  Uint8List _generateIV() {
    final secureRandom = _createSecureRandom();
    final iv = Uint8List(16);

    for (int i = 0; i < iv.length; i++) {
      iv[i] = secureRandom.nextUint8();
    }

    return iv;
  }

  /// Creates a cryptographically secure random number generator.
  ///
  /// Uses Fortuna PRNG seeded with random data from the platform's secure random source.
  SecureRandom _createSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = <int>[];

    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(256));
    }

    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom;
  }
}
