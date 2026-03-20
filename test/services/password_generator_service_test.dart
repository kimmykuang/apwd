import 'package:flutter_test/flutter_test.dart';
import 'package:apwd/services/password_generator_service.dart';

void main() {
  late PasswordGeneratorService passwordGenerator;

  setUp(() {
    passwordGenerator = PasswordGeneratorService();
  });

  group('PasswordGeneratorService - Basic Generation', () {
    test('should generate password with default length of 16 characters', () {
      // Act
      final password = passwordGenerator.generate();

      // Assert
      expect(password.length, equals(16));
    });

    test('should generate password with custom length', () {
      // Act
      final password8 = passwordGenerator.generate(length: 8);
      final password20 = passwordGenerator.generate(length: 20);
      final password32 = passwordGenerator.generate(length: 32);

      // Assert
      expect(password8.length, equals(8));
      expect(password20.length, equals(20));
      expect(password32.length, equals(32));
    });

    test('should enforce minimum password length of 8 characters', () {
      // Act & Assert
      expect(
        () => passwordGenerator.generate(length: 4),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => passwordGenerator.generate(length: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should enforce maximum password length of 32 characters', () {
      // Act & Assert
      expect(
        () => passwordGenerator.generate(length: 40),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => passwordGenerator.generate(length: 100),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should generate different passwords each time', () {
      // Act
      final password1 = passwordGenerator.generate();
      final password2 = passwordGenerator.generate();
      final password3 = passwordGenerator.generate();

      // Assert
      expect(password1, isNot(equals(password2)));
      expect(password2, isNot(equals(password3)));
      expect(password1, isNot(equals(password3)));
    });
  });

  group('PasswordGeneratorService - Character Types', () {
    test('should include uppercase letters by default', () {
      // Act
      final password = passwordGenerator.generate(length: 32);

      // Assert
      final hasUppercase = password.split('').any((char) {
        return char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90;
      });
      expect(hasUppercase, isTrue);
    });

    test('should include lowercase letters by default', () {
      // Act
      final password = passwordGenerator.generate(length: 32);

      // Assert
      final hasLowercase = password.split('').any((char) {
        return char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122;
      });
      expect(hasLowercase, isTrue);
    });

    test('should include digits by default', () {
      // Act
      final password = passwordGenerator.generate(length: 32);

      // Assert
      final hasDigit = password.split('').any((char) {
        return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      });
      expect(hasDigit, isTrue);
    });

    test('should include symbols by default', () {
      // Act
      final password = passwordGenerator.generate(length: 32);

      // Assert
      final hasSymbol = password.split('').any((char) {
        return '!@#\$%^&*()_+-=[]{}|;:,.<>?'.contains(char);
      });
      expect(hasSymbol, isTrue);
    });

    test('should generate password with only uppercase when other types disabled', () {
      // Act
      final password = passwordGenerator.generate(
        length: 20,
        lowercase: false,
        digits: false,
        symbols: false,
      );

      // Assert
      final allUppercase = password.split('').every((char) {
        return char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90;
      });
      expect(allUppercase, isTrue);
    });

    test('should generate password with only lowercase when other types disabled', () {
      // Act
      final password = passwordGenerator.generate(
        length: 20,
        uppercase: false,
        digits: false,
        symbols: false,
      );

      // Assert
      final allLowercase = password.split('').every((char) {
        return char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122;
      });
      expect(allLowercase, isTrue);
    });

    test('should generate password with only digits when other types disabled', () {
      // Act
      final password = passwordGenerator.generate(
        length: 20,
        uppercase: false,
        lowercase: false,
        symbols: false,
      );

      // Assert
      final allDigits = password.split('').every((char) {
        return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      });
      expect(allDigits, isTrue);
    });

    test('should generate password with only symbols when other types disabled', () {
      // Act
      final password = passwordGenerator.generate(
        length: 20,
        uppercase: false,
        lowercase: false,
        digits: false,
      );

      // Assert
      final allSymbols = password.split('').every((char) {
        return '!@#\$%^&*()_+-=[]{}|;:,.<>?'.contains(char);
      });
      expect(allSymbols, isTrue);
    });

    test('should throw error when no character types are enabled', () {
      // Act & Assert
      expect(
        () => passwordGenerator.generate(
          uppercase: false,
          lowercase: false,
          digits: false,
          symbols: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should generate password with mixed character types', () {
      // Act
      final password = passwordGenerator.generate(
        length: 32,
        uppercase: true,
        lowercase: true,
        digits: true,
        symbols: false,
      );

      // Assert
      final hasUppercase = password.split('').any((char) {
        return char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90;
      });
      final hasLowercase = password.split('').any((char) {
        return char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122;
      });
      final hasDigit = password.split('').any((char) {
        return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      });
      final hasSymbol = password.split('').any((char) {
        return '!@#\$%^&*()_+-=[]{}|;:,.<>?'.contains(char);
      });

      expect(hasUppercase, isTrue);
      expect(hasLowercase, isTrue);
      expect(hasDigit, isTrue);
      expect(hasSymbol, isFalse);
    });
  });

  group('PasswordGeneratorService - Ambiguous Characters', () {
    test('should exclude ambiguous characters when excludeAmbiguous is true', () {
      // Arrange
      const ambiguousChars = 'il1Lo0O';

      // Act - Generate multiple passwords to increase likelihood of catching issue
      final passwords = List.generate(
        10,
        (_) => passwordGenerator.generate(
          length: 32,
          excludeAmbiguous: true,
        ),
      );

      // Assert
      for (final password in passwords) {
        final hasAmbiguous = password.split('').any((char) {
          return ambiguousChars.contains(char);
        });
        expect(hasAmbiguous, isFalse);
      }
    });

    test('should include ambiguous characters by default', () {
      // Arrange
      const ambiguousChars = 'il1Lo0O';

      // Act - Generate multiple passwords to increase likelihood
      final passwords = List.generate(
        20,
        (_) => passwordGenerator.generate(length: 32),
      );

      // Assert - At least one password should contain ambiguous chars
      final someHaveAmbiguous = passwords.any((password) {
        return password.split('').any((char) {
          return ambiguousChars.contains(char);
        });
      });
      expect(someHaveAmbiguous, isTrue);
    });
  });

  group('PasswordGeneratorService - Security', () {
    test('should use cryptographically secure random generation', () {
      // Act - Generate many passwords and check for distribution patterns
      final passwords = <String>{};
      for (int i = 0; i < 100; i++) {
        passwords.add(passwordGenerator.generate(length: 16));
      }

      // Assert - All passwords should be unique (extremely high probability with secure random)
      expect(passwords.length, equals(100));
    });

    test('should have good character distribution in long password', () {
      // Act
      final password = passwordGenerator.generate(length: 32);

      // Assert - Password should use characters from multiple types
      final charTypes = <String, bool>{
        'uppercase': false,
        'lowercase': false,
        'digit': false,
        'symbol': false,
      };

      for (final char in password.split('')) {
        final code = char.codeUnitAt(0);
        if (code >= 65 && code <= 90) charTypes['uppercase'] = true;
        if (code >= 97 && code <= 122) charTypes['lowercase'] = true;
        if (code >= 48 && code <= 57) charTypes['digit'] = true;
        if ('!@#\$%^&*()_+-=[]{}|;:,.<>?'.contains(char)) {
          charTypes['symbol'] = true;
        }
      }

      final enabledTypes = charTypes.values.where((v) => v).length;
      // With length 32 and all types enabled, we should have at least 3 types
      expect(enabledTypes, greaterThanOrEqualTo(3));
    });
  });
}
