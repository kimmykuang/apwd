import 'dart:math';

/// Service for generating secure random passwords
class GeneratorService {
  final Random _random = Random.secure();

  // Character sets
  static const String _uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String _digitChars = '0123456789';
  static const String _symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  /// Generate a random password with specified characteristics
  String generate({
    required int length,
    required bool uppercase,
    required bool lowercase,
    required bool digits,
    required bool symbols,
  }) {
    // Build character set
    String charset = '';
    if (uppercase) charset += _uppercaseChars;
    if (lowercase) charset += _lowercaseChars;
    if (digits) charset += _digitChars;
    if (symbols) charset += _symbolChars;

    // Return empty if no character types selected
    if (charset.isEmpty) return '';

    // Generate password
    return List.generate(
      length,
      (_) => charset[_random.nextInt(charset.length)],
    ).join();
  }
}
