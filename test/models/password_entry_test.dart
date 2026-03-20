import 'package:flutter_test/flutter_test.dart';
import 'package:apwd/models/password_entry.dart';

void main() {
  group('PasswordEntry Model Tests', () {
    test('1. Create PasswordEntry with required fields', () {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id: 1,
        groupId: 1,
        title: 'Gmail',
        url: 'https://gmail.com',
        username: 'user@example.com',
        password: 'encrypted_password_123',
        notes: 'My personal email',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry.id, 1);
      expect(entry.groupId, 1);
      expect(entry.title, 'Gmail');
      expect(entry.url, 'https://gmail.com');
      expect(entry.username, 'user@example.com');
      expect(entry.password, 'encrypted_password_123');
      expect(entry.notes, 'My personal email');
      expect(entry.createdAt, now);
      expect(entry.updatedAt, now);
    });

    test('2. Create PasswordEntry without optional fields', () {
      final now = DateTime.now();
      final entry = PasswordEntry(
        groupId: 2,
        title: 'Database Login',
        password: 'encrypted_db_pass',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry.id, isNull);
      expect(entry.groupId, 2);
      expect(entry.title, 'Database Login');
      expect(entry.url, isNull);
      expect(entry.username, isNull);
      expect(entry.password, 'encrypted_db_pass');
      expect(entry.notes, isNull);
      expect(entry.createdAt, now);
      expect(entry.updatedAt, now);
    });

    test('3. Convert PasswordEntry to Map', () {
      final createdAt = DateTime(2026, 3, 20, 10, 0, 0);
      final updatedAt = DateTime(2026, 3, 20, 11, 0, 0);
      final entry = PasswordEntry(
        id: 1,
        groupId: 1,
        title: 'Gmail',
        url: 'https://gmail.com',
        username: 'user@example.com',
        password: 'encrypted_password_123',
        notes: 'My personal email',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = entry.toMap();

      expect(map['id'], 1);
      expect(map['group_id'], 1);
      expect(map['title'], 'Gmail');
      expect(map['url'], 'https://gmail.com');
      expect(map['username'], 'user@example.com');
      expect(map['password'], 'encrypted_password_123');
      expect(map['notes'], 'My personal email');
      expect(map['created_at'], createdAt.millisecondsSinceEpoch);
      expect(map['updated_at'], updatedAt.millisecondsSinceEpoch);
    });

    test('4. Create PasswordEntry from Map', () {
      final createdAt = DateTime(2026, 3, 20, 10, 0, 0);
      final updatedAt = DateTime(2026, 3, 20, 11, 0, 0);
      final map = {
        'id': 1,
        'group_id': 1,
        'title': 'Gmail',
        'url': 'https://gmail.com',
        'username': 'user@example.com',
        'password': 'encrypted_password_123',
        'notes': 'My personal email',
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

      final entry = PasswordEntry.fromMap(map);

      expect(entry.id, 1);
      expect(entry.groupId, 1);
      expect(entry.title, 'Gmail');
      expect(entry.url, 'https://gmail.com');
      expect(entry.username, 'user@example.com');
      expect(entry.password, 'encrypted_password_123');
      expect(entry.notes, 'My personal email');
      expect(entry.createdAt, createdAt);
      expect(entry.updatedAt, updatedAt);
    });

    test('5. Create copy with updated fields', () {
      final now = DateTime.now();
      final original = PasswordEntry(
        id: 1,
        groupId: 1,
        title: 'Gmail',
        url: 'https://gmail.com',
        username: 'user@example.com',
        password: 'encrypted_password_123',
        notes: 'My personal email',
        createdAt: now,
        updatedAt: now,
      );

      final later = DateTime.now().add(Duration(hours: 1));
      final copy = original.copyWith(
        title: 'Gmail Work',
        username: 'work@example.com',
        password: 'new_encrypted_password',
        updatedAt: later,
      );

      // Changed fields
      expect(copy.title, 'Gmail Work');
      expect(copy.username, 'work@example.com');
      expect(copy.password, 'new_encrypted_password');
      expect(copy.updatedAt, later);

      // Unchanged fields
      expect(copy.id, 1);
      expect(copy.groupId, 1);
      expect(copy.url, 'https://gmail.com');
      expect(copy.notes, 'My personal email');
      expect(copy.createdAt, now);
    });

    test('6. Handle null optional fields in toMap and fromMap', () {
      final createdAt = DateTime(2026, 3, 20, 10, 0, 0);
      final updatedAt = DateTime(2026, 3, 20, 11, 0, 0);
      final entry = PasswordEntry(
        groupId: 1,
        title: 'Simple Entry',
        password: 'encrypted_pass',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = entry.toMap();

      expect(map['id'], isNull);
      expect(map['url'], isNull);
      expect(map['username'], isNull);
      expect(map['notes'], isNull);
      expect(map['title'], 'Simple Entry');

      final recreated = PasswordEntry.fromMap(map);

      expect(recreated.id, isNull);
      expect(recreated.url, isNull);
      expect(recreated.username, isNull);
      expect(recreated.notes, isNull);
      expect(recreated.title, 'Simple Entry');
    });

    test('7. Equality comparison works correctly', () {
      final now = DateTime(2026, 3, 20, 10, 0, 0);
      final entry1 = PasswordEntry(
        id: 1,
        groupId: 1,
        title: 'Gmail',
        url: 'https://gmail.com',
        username: 'user@example.com',
        password: 'encrypted_password_123',
        notes: 'My personal email',
        createdAt: now,
        updatedAt: now,
      );

      final entry2 = PasswordEntry(
        id: 1,
        groupId: 1,
        title: 'Gmail',
        url: 'https://gmail.com',
        username: 'user@example.com',
        password: 'encrypted_password_123',
        notes: 'My personal email',
        createdAt: now,
        updatedAt: now,
      );

      final entry3 = PasswordEntry(
        id: 2,
        groupId: 1,
        title: 'Gmail',
        url: 'https://gmail.com',
        username: 'user@example.com',
        password: 'encrypted_password_123',
        notes: 'My personal email',
        createdAt: now,
        updatedAt: now,
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
      expect(entry1.hashCode, equals(entry2.hashCode));
    });
  });
}
