import 'package:flutter_test/flutter_test.dart';
import 'package:apwd/services/generator_service.dart';

void main() {
  group('GeneratorService', () {
    late GeneratorService service;

    setUp(() {
      service = GeneratorService();
    });

    test('should generate password with specified length', () {
      final password = service.generate(
        length: 16,
        uppercase: true,
        lowercase: true,
        digits: true,
        symbols: true,
      );

      expect(password.length, 16);
    });

    test('should generate password with only lowercase letters', () {
      final password = service.generate(
        length: 20,
        uppercase: false,
        lowercase: true,
        digits: false,
        symbols: false,
      );

      expect(password.length, 20);
      expect(password, matches(RegExp(r'^[a-z]+$')));
    });

    test('should generate password with uppercase and digits', () {
      final password = service.generate(
        length: 15,
        uppercase: true,
        lowercase: false,
        digits: true,
        symbols: false,
      );

      expect(password.length, 15);
      expect(password, matches(RegExp(r'^[A-Z0-9]+$')));
    });

    test('should include all character types when requested', () {
      final password = service.generate(
        length: 100,
        uppercase: true,
        lowercase: true,
        digits: true,
        symbols: true,
      );

      expect(password, matches(RegExp(r'[A-Z]'))); // Has uppercase
      expect(password, matches(RegExp(r'[a-z]'))); // Has lowercase
      expect(password, matches(RegExp(r'[0-9]'))); // Has digits
      expect(password, matches(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))); // Has symbols
    });

    test('should generate different passwords each time', () {
      final password1 = service.generate(
        length: 20,
        uppercase: true,
        lowercase: true,
        digits: true,
        symbols: true,
      );
      final password2 = service.generate(
        length: 20,
        uppercase: true,
        lowercase: true,
        digits: true,
        symbols: true,
      );

      expect(password1, isNot(equals(password2)));
    });

    test('should return empty string when no character types selected', () {
      final password = service.generate(
        length: 20,
        uppercase: false,
        lowercase: false,
        digits: false,
        symbols: false,
      );

      expect(password, isEmpty);
    });

    test('should handle minimum length', () {
      final password = service.generate(
        length: 1,
        uppercase: true,
        lowercase: false,
        digits: false,
        symbols: false,
      );

      expect(password.length, 1);
      expect(password, matches(RegExp(r'[A-Z]')));
    });

    test('should handle maximum length', () {
      final password = service.generate(
        length: 128,
        uppercase: true,
        lowercase: true,
        digits: true,
        symbols: true,
      );

      expect(password.length, 128);
    });
  });
}
