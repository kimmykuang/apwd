import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apwd/services/database_service.dart';
import 'package:apwd/services/group_service.dart';
import 'package:apwd/models/group.dart';
import 'dart:io';
import 'dart:typed_data';

void main() {
  late DatabaseService dbService;
  late GroupService groupService;
  late String testDbPath;
  late Uint8List testDatabaseKey;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDbPath = '${Directory.systemTemp.path}/test_groups_${DateTime.now().millisecondsSinceEpoch}.db';
    testDatabaseKey = Uint8List.fromList(List.generate(32, (i) => i));
    dbService = DatabaseService(databaseFactory: databaseFactoryFfi);
    await dbService.initialize(testDbPath, testDatabaseKey);
    groupService = GroupService(dbService);
  });

  tearDown(() async {
    await dbService.close();
    try {
      await File(testDbPath).delete();
    } catch (_) {}
  });

  group('GroupService - CRUD', () {
    test('should create a new group', () async {
      final now = DateTime.now();
      final group = Group(
        name: 'Test Group',
        icon: 'test_icon',
        sortOrder: 10,
        createdAt: now,
        updatedAt: now,
      );

      final id = await groupService.create(group);

      expect(id, greaterThan(0));
    });

    test('should retrieve group by id', () async {
      final now = DateTime.now();
      final group = Group(
        name: 'My Group',
        icon: 'icon_name',
        sortOrder: 5,
        createdAt: now,
        updatedAt: now,
      );

      final id = await groupService.create(group);
      final retrieved = await groupService.getById(id);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'My Group');
      expect(retrieved.icon, 'icon_name');
      expect(retrieved.sortOrder, 5);
    });

    test('should return null for non-existent group', () async {
      final retrieved = await groupService.getById(99999);

      expect(retrieved, isNull);
    });

    test('should get all groups ordered by sort order', () async {
      final now = DateTime.now();

      // Create multiple groups with different sort orders
      await groupService.create(Group(
        name: 'Group C',
        sortOrder: 30,
        createdAt: now,
        updatedAt: now,
      ));
      await groupService.create(Group(
        name: 'Group A',
        sortOrder: 10,
        createdAt: now,
        updatedAt: now,
      ));
      await groupService.create(Group(
        name: 'Group B',
        sortOrder: 20,
        createdAt: now,
        updatedAt: now,
      ));

      final groups = await groupService.getAll();

      // Should include default groups plus our 3
      expect(groups.length, greaterThanOrEqualTo(3));

      // Find our custom groups
      final customGroups = groups.where((g) => ['Group A', 'Group B', 'Group C'].contains(g.name)).toList();
      expect(customGroups.length, 3);

      // Verify ordering
      expect(customGroups[0].name, 'Group A');
      expect(customGroups[1].name, 'Group B');
      expect(customGroups[2].name, 'Group C');
    });

    test('should update a group', () async {
      final now = DateTime.now();
      final group = Group(
        name: 'Original Name',
        sortOrder: 10,
        createdAt: now,
        updatedAt: now,
      );

      final id = await groupService.create(group);
      final updated = group.copyWith(
        id: id,
        name: 'Updated Name',
        sortOrder: 20,
        updatedAt: DateTime.now(),
      );

      await groupService.update(updated);
      final retrieved = await groupService.getById(id);

      expect(retrieved!.name, 'Updated Name');
      expect(retrieved.sortOrder, 20);
    });

    test('should delete a group', () async {
      final now = DateTime.now();
      final group = Group(
        name: 'To Delete',
        sortOrder: 10,
        createdAt: now,
        updatedAt: now,
      );

      final id = await groupService.create(group);
      await groupService.delete(id);
      final retrieved = await groupService.getById(id);

      expect(retrieved, isNull);
    });

    test('should get password count for a group', () async {
      // Create a test group
      final now = DateTime.now();
      final group = Group(
        name: 'Test Group',
        sortOrder: 10,
        createdAt: now,
        updatedAt: now,
      );
      final groupId = await groupService.create(group);

      final count = await groupService.getPasswordCount(groupId);

      expect(count, greaterThanOrEqualTo(0));
    });

    test('should return 0 for password count when group has no passwords', () async {
      final now = DateTime.now();
      final group = Group(
        name: 'Empty Group',
        sortOrder: 10,
        createdAt: now,
        updatedAt: now,
      );

      final id = await groupService.create(group);
      final count = await groupService.getPasswordCount(id);

      expect(count, 0);
    });
  });
}
