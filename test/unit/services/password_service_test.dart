import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apwd/services/database_service.dart';
import 'package:apwd/services/password_service.dart';
import 'package:apwd/models/password_entry.dart';
import 'dart:io';
import 'dart:typed_data';

void main() {
  late DatabaseService dbService;
  late PasswordService passwordService;
  late String testDbPath;
  late Uint8List testDatabaseKey;
  late int testGroupId;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDbPath = '${Directory.systemTemp.path}/test_passwords_${DateTime.now().millisecondsSinceEpoch}.db';
    testDatabaseKey = Uint8List.fromList(List.generate(32, (i) => i));
    dbService = DatabaseService(databaseFactory: databaseFactoryFfi);
    await dbService.initialize(testDbPath, testDatabaseKey);
    passwordService = PasswordService(dbService);

    // Create a test group for testing
    final result = await dbService.database.insert('groups', {
      'name': 'Test Group',
      'icon': 'test',
      'sort_order': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    testGroupId = result;
  });

  tearDown(() async {
    await dbService.close();
    try {
      await File(testDbPath).delete();
    } catch (_) {}
  });

  group('PasswordService - CRUD', () {
    test('should create a new password entry', () async {
      final now = DateTime.now();
      final entry = PasswordEntry(
        groupId: testGroupId,
        title: 'GitHub',
        url: 'https://github.com',
        username: 'test@example.com',
        password: 'encrypted_password',
        notes: 'Test notes',
        createdAt: now,
        updatedAt: now,
      );

      final id = await passwordService.create(entry);

      expect(id, greaterThan(0));
    });

    test('should retrieve password entry by id', () async {
      final now = DateTime.now();
      final entry = PasswordEntry(
        groupId: testGroupId,
        title: 'Test Entry',
        password: 'pass123',
        createdAt: now,
        updatedAt: now,
      );

      final id = await passwordService.create(entry);
      final retrieved = await passwordService.getById(id);

      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Test Entry');
      expect(retrieved.password, 'pass123');
      expect(retrieved.groupId, testGroupId);
    });

    test('should return null for non-existent entry', () async {
      final retrieved = await passwordService.getById(99999);

      expect(retrieved, isNull);
    });

    test('should get all entries for a group', () async {
      final now = DateTime.now();

      // Create multiple entries
      await passwordService.create(PasswordEntry(
        groupId: testGroupId,
        title: 'Entry 1',
        password: 'pass1',
        createdAt: now,
        updatedAt: now,
      ));
      await passwordService.create(PasswordEntry(
        groupId: testGroupId,
        title: 'Entry 2',
        password: 'pass2',
        createdAt: now,
        updatedAt: now,
      ));

      final entries = await passwordService.getByGroupId(testGroupId);

      expect(entries.length, greaterThanOrEqualTo(2));
    });

    test('should update password entry', () async {
      final now = DateTime.now();
      final entry = PasswordEntry(
        groupId: testGroupId,
        title: 'Original',
        password: 'original_pass',
        createdAt: now,
        updatedAt: now,
      );

      final id = await passwordService.create(entry);
      final updated = entry.copyWith(
        id: id,
        title: 'Updated',
        password: 'updated_pass',
        updatedAt: DateTime.now(),
      );

      await passwordService.update(updated);
      final retrieved = await passwordService.getById(id);

      expect(retrieved!.title, 'Updated');
      expect(retrieved.password, 'updated_pass');
    });

    test('should delete password entry', () async {
      final now = DateTime.now();
      final entry = PasswordEntry(
        groupId: testGroupId,
        title: 'To Delete',
        password: 'pass',
        createdAt: now,
        updatedAt: now,
      );

      final id = await passwordService.create(entry);
      await passwordService.delete(id);
      final retrieved = await passwordService.getById(id);

      expect(retrieved, isNull);
    });

    test('should search entries by keyword', () async {
      final now = DateTime.now();

      await passwordService.create(PasswordEntry(
        groupId: testGroupId,
        title: 'GitHub Account',
        username: 'user@github.com',
        password: 'pass',
        createdAt: now,
        updatedAt: now,
      ));
      await passwordService.create(PasswordEntry(
        groupId: testGroupId,
        title: 'GitLab Account',
        username: 'user@gitlab.com',
        password: 'pass',
        createdAt: now,
        updatedAt: now,
      ));

      final results = await passwordService.search('git');

      expect(results.length, greaterThanOrEqualTo(2));
      expect(results.any((e) => e.title.contains('GitHub')), isTrue);
      expect(results.any((e) => e.title.contains('GitLab')), isTrue);
    });
  });
}
