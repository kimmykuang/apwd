import 'package:flutter_test/flutter_test.dart';
import 'package:apwd/models/group.dart';

void main() {
  group('Group Model Tests', () {
    test('1. Create Group with all fields', () {
      final now = DateTime.now();
      final group = Group(
        id: 1,
        name: 'Personal',
        icon: 'home',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(group.id, 1);
      expect(group.name, 'Personal');
      expect(group.icon, 'home');
      expect(group.sortOrder, 0);
      expect(group.createdAt, now);
      expect(group.updatedAt, now);
    });

    test('2. Create Group without optional id', () {
      final now = DateTime.now();
      final group = Group(
        name: 'Work',
        icon: 'work',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      expect(group.id, isNull);
      expect(group.name, 'Work');
      expect(group.icon, 'work');
      expect(group.sortOrder, 1);
      expect(group.createdAt, now);
      expect(group.updatedAt, now);
    });

    test('3. Convert Group to Map', () {
      final createdAt = DateTime(2026, 3, 19, 10, 0, 0);
      final updatedAt = DateTime(2026, 3, 19, 11, 0, 0);
      final group = Group(
        id: 1,
        name: 'Personal',
        icon: 'home',
        sortOrder: 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = group.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Personal');
      expect(map['icon'], 'home');
      expect(map['sort_order'], 0);
      expect(map['created_at'], createdAt.millisecondsSinceEpoch);
      expect(map['updated_at'], updatedAt.millisecondsSinceEpoch);
    });

    test('4. Create Group from Map', () {
      final createdAt = DateTime(2026, 3, 19, 10, 0, 0);
      final updatedAt = DateTime(2026, 3, 19, 11, 0, 0);
      final map = {
        'id': 1,
        'name': 'Personal',
        'icon': 'home',
        'sort_order': 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

      final group = Group.fromMap(map);

      expect(group.id, 1);
      expect(group.name, 'Personal');
      expect(group.icon, 'home');
      expect(group.sortOrder, 0);
      expect(group.createdAt, createdAt);
      expect(group.updatedAt, updatedAt);
    });

    test('5. Create copy with updated fields', () {
      final now = DateTime.now();
      final original = Group(
        id: 1,
        name: 'Personal',
        icon: 'home',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );

      final later = DateTime.now().add(Duration(hours: 1));
      final copy = original.copyWith(
        name: 'Updated Personal',
        icon: 'star',
        updatedAt: later,
      );

      // Changed fields
      expect(copy.name, 'Updated Personal');
      expect(copy.icon, 'star');
      expect(copy.updatedAt, later);

      // Unchanged fields
      expect(copy.id, 1);
      expect(copy.sortOrder, 0);
      expect(copy.createdAt, now);
    });

    test('6. Handle null icon in toMap', () {
      final now = DateTime.now();
      final group = Group(
        id: 1,
        name: 'Personal',
        icon: null,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );

      final map = group.toMap();

      expect(map['icon'], isNull);
      expect(map['name'], 'Personal');
    });

    test('7. Handle null icon in fromMap', () {
      final createdAt = DateTime(2026, 3, 19, 10, 0, 0);
      final updatedAt = DateTime(2026, 3, 19, 11, 0, 0);
      final map = {
        'id': 1,
        'name': 'Personal',
        'icon': null,
        'sort_order': 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

      final group = Group.fromMap(map);

      expect(group.icon, isNull);
      expect(group.name, 'Personal');
      expect(group.id, 1);
    });
  });
}
