import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart' as crypto_pkg;
import 'package:apwd/utils/constants.dart';

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
