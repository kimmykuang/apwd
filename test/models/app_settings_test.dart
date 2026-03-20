import 'package:flutter_test/flutter_test.dart';
import 'package:apwd/models/app_settings.dart';

void main() {
  group('AppSettings Model Tests', () {
    test('1. Create AppSettings with default values', () {
      final now = DateTime.now();
      final settings = AppSettings(
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.id, isNull);
      expect(settings.autoLockTimeout, 300);
      expect(settings.biometricEnabled, false);
      expect(settings.masterPasswordHash, isNull);
      expect(settings.passwordSalt, isNull);
      expect(settings.clipboardClearTimeout, 30);
      expect(settings.firstLaunchCompleted, false);
      expect(settings.createdAt, now);
      expect(settings.updatedAt, now);
    });

    test('2. Create AppSettings with custom values', () {
      final now = DateTime.now();
      final settings = AppSettings(
        id: 1,
        autoLockTimeout: 600,
        biometricEnabled: true,
        masterPasswordHash: 'hash123',
        passwordSalt: 'salt456',
        clipboardClearTimeout: 60,
        firstLaunchCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(settings.id, 1);
      expect(settings.autoLockTimeout, 600);
      expect(settings.biometricEnabled, true);
      expect(settings.masterPasswordHash, 'hash123');
      expect(settings.passwordSalt, 'salt456');
      expect(settings.clipboardClearTimeout, 60);
      expect(settings.firstLaunchCompleted, true);
      expect(settings.createdAt, now);
      expect(settings.updatedAt, now);
    });

    test('3. Convert AppSettings to Map', () {
      final createdAt = DateTime(2026, 3, 20, 10, 0, 0);
      final updatedAt = DateTime(2026, 3, 20, 11, 0, 0);
      final settings = AppSettings(
        id: 1,
        autoLockTimeout: 600,
        biometricEnabled: true,
        masterPasswordHash: 'hash123',
        passwordSalt: 'salt456',
        clipboardClearTimeout: 60,
        firstLaunchCompleted: true,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = settings.toMap();

      expect(map['id'], 1);
      expect(map['auto_lock_timeout'], 600);
      expect(map['biometric_enabled'], 1);
      expect(map['master_password_hash'], 'hash123');
      expect(map['password_salt'], 'salt456');
      expect(map['clipboard_clear_timeout'], 60);
      expect(map['first_launch_completed'], 1);
      expect(map['created_at'], createdAt.millisecondsSinceEpoch);
      expect(map['updated_at'], updatedAt.millisecondsSinceEpoch);
    });

    test('4. Create AppSettings from Map', () {
      final createdAt = DateTime(2026, 3, 20, 10, 0, 0);
      final updatedAt = DateTime(2026, 3, 20, 11, 0, 0);
      final map = {
        'id': 1,
        'auto_lock_timeout': 600,
        'biometric_enabled': 1,
        'master_password_hash': 'hash123',
        'password_salt': 'salt456',
        'clipboard_clear_timeout': 60,
        'first_launch_completed': 1,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

      final settings = AppSettings.fromMap(map);

      expect(settings.id, 1);
      expect(settings.autoLockTimeout, 600);
      expect(settings.biometricEnabled, true);
      expect(settings.masterPasswordHash, 'hash123');
      expect(settings.passwordSalt, 'salt456');
      expect(settings.clipboardClearTimeout, 60);
      expect(settings.firstLaunchCompleted, true);
      expect(settings.createdAt, createdAt);
      expect(settings.updatedAt, updatedAt);
    });

    test('5. Create copy with updated fields', () {
      final now = DateTime.now();
      final original = AppSettings(
        id: 1,
        autoLockTimeout: 300,
        biometricEnabled: false,
        masterPasswordHash: 'hash123',
        passwordSalt: 'salt456',
        clipboardClearTimeout: 30,
        firstLaunchCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      final later = DateTime.now().add(Duration(hours: 1));
      final copy = original.copyWith(
        autoLockTimeout: 600,
        biometricEnabled: true,
        firstLaunchCompleted: true,
        updatedAt: later,
      );

      // Changed fields
      expect(copy.autoLockTimeout, 600);
      expect(copy.biometricEnabled, true);
      expect(copy.firstLaunchCompleted, true);
      expect(copy.updatedAt, later);

      // Unchanged fields
      expect(copy.id, 1);
      expect(copy.masterPasswordHash, 'hash123');
      expect(copy.passwordSalt, 'salt456');
      expect(copy.clipboardClearTimeout, 30);
      expect(copy.createdAt, now);
    });

    test('6. Handle null optional fields correctly', () {
      final createdAt = DateTime(2026, 3, 20, 10, 0, 0);
      final updatedAt = DateTime(2026, 3, 20, 11, 0, 0);
      final settings = AppSettings(
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = settings.toMap();

      expect(map['id'], isNull);
      expect(map['master_password_hash'], isNull);
      expect(map['password_salt'], isNull);
      expect(map['auto_lock_timeout'], 300);
      expect(map['biometric_enabled'], 0);
      expect(map['clipboard_clear_timeout'], 30);
      expect(map['first_launch_completed'], 0);

      final recreated = AppSettings.fromMap(map);

      expect(recreated.id, isNull);
      expect(recreated.masterPasswordHash, isNull);
      expect(recreated.passwordSalt, isNull);
      expect(recreated.autoLockTimeout, 300);
      expect(recreated.biometricEnabled, false);
      expect(recreated.clipboardClearTimeout, 30);
      expect(recreated.firstLaunchCompleted, false);
    });

    test('7. Equality comparison works correctly', () {
      final now = DateTime(2026, 3, 20, 10, 0, 0);
      final settings1 = AppSettings(
        id: 1,
        autoLockTimeout: 300,
        biometricEnabled: true,
        masterPasswordHash: 'hash123',
        passwordSalt: 'salt456',
        clipboardClearTimeout: 30,
        firstLaunchCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      final settings2 = AppSettings(
        id: 1,
        autoLockTimeout: 300,
        biometricEnabled: true,
        masterPasswordHash: 'hash123',
        passwordSalt: 'salt456',
        clipboardClearTimeout: 30,
        firstLaunchCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      final settings3 = AppSettings(
        id: 1,
        autoLockTimeout: 600,
        biometricEnabled: true,
        masterPasswordHash: 'hash123',
        passwordSalt: 'salt456',
        clipboardClearTimeout: 30,
        firstLaunchCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(settings1, equals(settings2));
      expect(settings1, isNot(equals(settings3)));
      expect(settings1.hashCode, equals(settings2.hashCode));
    });
  });
}
