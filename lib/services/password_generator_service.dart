import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Service for generating secure random passwords with configurable options.
class PasswordGeneratorService {
  // Character sets for password generation
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _digits = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  // Ambiguous characters that look similar
  static const String _ambiguousChars = 'il1Lo0O';

  /// Generates a secure random password with configurable options.
  ///
  /// Parameters:
  /// - [length]: Length of the password (8-32 characters, default: 16)
  /// - [uppercase]: Include uppercase letters (default: true)
  /// - [lowercase]: Include lowercase letters (default: true)
  /// - [digits]: Include digits (default: true)
  /// - [symbols]: Include symbols (default: true)
  /// - [excludeAmbiguous]: Exclude ambiguous characters like i, l, 1, L, o, 0, O (default: false)
  ///
  /// Returns a [String] containing the generated password.
  ///
  /// Throws [ArgumentError] if:
  /// - length is less than 8 or greater than 32
  /// - all character type options are disabled
  String generate({
    int length = 16,
    bool uppercase = true,
    bool lowercase = true,
    bool digits = true,
    bool symbols = true,
    bool excludeAmbiguous = false,
  }) {
    // Validate length
    if (length < 8 || length > 32) {
      throw ArgumentError('Password length must be between 8 and 32 characters');
    }

    // Build character set based on options
    String charset = '';

    if (uppercase) {
      charset += _uppercase;
    }
    if (lowercase) {
      charset += _lowercase;
    }
    if (digits) {
      charset += _digits;
    }
    if (symbols) {
      charset += _symbols;
    }

    // Validate that at least one character type is enabled
    if (charset.isEmpty) {
      throw ArgumentError('At least one character type must be enabled');
    }

    // Remove ambiguous characters if requested
    if (excludeAmbiguous) {
      charset = charset.split('').where((char) {
        return !_ambiguousChars.contains(char);
      }).join('');
    }

    // Generate password using cryptographically secure random
    final secureRandom = _createSecureRandom();
    final password = StringBuffer();

    for (int i = 0; i < length; i++) {
      // Generate a random index within the charset range
      // Use rejection sampling to ensure uniform distribution
      int randomIndex;
      do {
        randomIndex = secureRandom.nextUint8();
      } while (randomIndex >= 256 - (256 % charset.length));

      randomIndex = randomIndex % charset.length;
      password.write(charset[randomIndex]);
    }

    return password.toString();
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
