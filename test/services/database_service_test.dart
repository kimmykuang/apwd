import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apwd/services/database_service.dart';
import 'package:apwd/models/group.dart';
import 'package:apwd/models/password_entry.dart';
import 'package:apwd/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('DatabaseService', () {
    late DatabaseService dbService;
    late String testDbPath;
    late Uint8List testDatabaseKey;

    setUp(() async {
      // Create a test database key (32 bytes)
      testDatabaseKey = Uint8List.fromList(List.generate(32, (i) => i));

      // Create a unique test database path
      testDbPath = '${Directory.systemTemp.path}/test_apwd_${DateTime.now().millisecondsSinceEpoch}.db';

      // Initialize database service with FFI factory for testing
      dbService = DatabaseService(databaseFactory: databaseFactoryFfi);
    });

    tearDown(() async {
      // Close database
      await dbService.close();

      // Clean up test database file
      final file = File(testDbPath);
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('initialize creates database file', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final file = File(testDbPath);
      expect(await file.exists(), true);
    });

    test('initialize creates groups table', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      // Query the groups table to verify it exists
      final db = dbService.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='groups'",
      );

      expect(result.isNotEmpty, true);
      expect(result.first['name'], 'groups');
    });

    test('initialize creates password_entries table', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='password_entries'",
      );

      expect(result.isNotEmpty, true);
      expect(result.first['name'], 'password_entries');
    });

    test('initialize creates settings table', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'",
      );

      expect(result.isNotEmpty, true);
      expect(result.first['name'], 'settings');
    });

    test('groups table has correct schema', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery("PRAGMA table_info(groups)");

      // Extract column names
      final columns = result.map((col) => col['name'] as String).toList();

      expect(columns.contains('id'), true);
      expect(columns.contains('name'), true);
      expect(columns.contains('icon'), true);
      expect(columns.contains('sort_order'), true);
      expect(columns.contains('created_at'), true);
      expect(columns.contains('updated_at'), true);
    });

    test('password_entries table has correct schema', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery("PRAGMA table_info(password_entries)");

      final columns = result.map((col) => col['name'] as String).toList();

      expect(columns.contains('id'), true);
      expect(columns.contains('group_id'), true);
      expect(columns.contains('title'), true);
      expect(columns.contains('url'), true);
      expect(columns.contains('username'), true);
      expect(columns.contains('password'), true);
      expect(columns.contains('notes'), true);
      expect(columns.contains('created_at'), true);
      expect(columns.contains('updated_at'), true);
    });

    test('settings table has correct schema', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery("PRAGMA table_info(settings)");

      final columns = result.map((col) => col['name'] as String).toList();

      expect(columns.contains('id'), true);
      expect(columns.contains('auto_lock_timeout'), true);
      expect(columns.contains('biometric_enabled'), true);
      expect(columns.contains('clipboard_clear_timeout'), true);
    });

    test('password_entries table has foreign key to groups', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery("PRAGMA foreign_key_list(password_entries)");

      expect(result.isNotEmpty, true);
      expect(result.first['table'], 'groups');
      expect(result.first['from'], 'group_id');
      expect(result.first['to'], 'id');
    });

    test('groups table has index on name', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='groups' AND name='idx_groups_name'",
      );

      expect(result.isNotEmpty, true);
    });

    test('password_entries table has index on group_id', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='password_entries' AND name='idx_password_entries_group_id'",
      );

      expect(result.isNotEmpty, true);
    });

    test('password_entries table has index on title', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='password_entries' AND name='idx_password_entries_title'",
      );

      expect(result.isNotEmpty, true);
    });

    test('initialize inserts default settings', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.query('settings');

      expect(result.length, 1);
      expect(result.first['auto_lock_timeout'], 300);
      expect(result.first['biometric_enabled'], 0);
      expect(result.first['clipboard_clear_timeout'], 30);
    });

    test('initialize can be called multiple times safely', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      // This should not throw an error
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      expect(db.isOpen, true);
    });

    test('database property throws StateError if not initialized', () {
      expect(() => dbService.database, throwsStateError);
    });

    test('close closes the database', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      await dbService.close();

      // Accessing database after close should throw
      expect(() => dbService.database, throwsStateError);
    });

    test('foreign keys are enabled', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;
      final result = await db.rawQuery('PRAGMA foreign_keys');

      expect(result.first['foreign_keys'], 1);
    });

    test('can insert data into tables after initialization', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;

      // Insert a group
      final now = DateTime.now();
      final group = Group(
        name: 'Test Group',
        icon: 'test_icon',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      );

      final groupId = await db.insert('groups', group.toMap());
      expect(groupId, greaterThan(0));

      // Insert a password entry
      final entry = PasswordEntry(
        groupId: groupId,
        title: 'Test Entry',
        url: 'https://test.com',
        username: 'testuser',
        password: 'encrypted_password',
        notes: 'Test notes',
        createdAt: now,
        updatedAt: now,
      );

      final entryId = await db.insert('password_entries', entry.toMap());
      expect(entryId, greaterThan(0));

      // Insert settings
      final settings = AppSettings(
        autoLockTimeout: 600,
        biometricEnabled: true,
        clipboardClearTimeout: 60,
      );

      final settingsId = await db.insert('settings', settings.toMap());
      expect(settingsId, greaterThan(0));
    });

    test('foreign key constraint prevents orphan password entries', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final db = dbService.database;

      // Try to insert a password entry with non-existent group_id
      final now = DateTime.now();
      final entry = PasswordEntry(
        groupId: 999, // Non-existent group
        title: 'Test Entry',
        password: 'encrypted_password',
        createdAt: now,
        updatedAt: now,
      );

      // This should fail due to foreign key constraint
      expect(
        () => db.insert('password_entries', entry.toMap()),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('DatabaseService - Settings', () {
    late DatabaseService dbService;
    late String testDbPath;
    late Uint8List testDatabaseKey;

    setUp(() async {
      // Create a test database key (32 bytes)
      testDatabaseKey = Uint8List.fromList(List.generate(32, (i) => i));

      // Create a unique test database path
      testDbPath = '${Directory.systemTemp.path}/test_apwd_settings_${DateTime.now().millisecondsSinceEpoch}.db';

      // Initialize database service with FFI factory for testing
      dbService = DatabaseService(databaseFactory: databaseFactoryFfi);
    });

    tearDown(() async {
      // Close database
      await dbService.close();

      // Clean up test database file
      final file = File(testDbPath);
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('should save and retrieve string setting', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      await dbService.setSetting('test_key', 'test_value');
      final value = await dbService.getSetting('test_key');

      expect(value, 'test_value');
    });

    test('should return null for non-existent setting', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      final value = await dbService.getSetting('non_existent');

      expect(value, isNull);
    });

    test('should update existing setting', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      await dbService.setSetting('key', 'value1');
      await dbService.setSetting('key', 'value2');
      final value = await dbService.getSetting('key');

      expect(value, 'value2');
    });

    test('should save and retrieve int setting', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      await dbService.setIntSetting('timeout', 300);
      final value = await dbService.getIntSetting('timeout');

      expect(value, 300);
    });

    test('should save and retrieve bool setting', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      await dbService.setBoolSetting('enabled', true);
      final value = await dbService.getBoolSetting('enabled');

      expect(value, true);
    });

    test('should return default values for missing typed settings', () async {
      await dbService.initialize(testDbPath, testDatabaseKey);

      expect(await dbService.getIntSetting('missing', defaultValue: 42), 42);
      expect(await dbService.getBoolSetting('missing', defaultValue: false), false);
    });
  });
}
