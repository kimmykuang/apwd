import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apwd/services/database_service.dart';
import 'package:apwd/services/crypto_service.dart';
import 'package:apwd/services/group_service.dart';
import 'package:apwd/services/password_service.dart';
import 'package:apwd/services/export_import_service.dart';
import 'package:apwd/models/group.dart';
import 'package:apwd/models/password_entry.dart';
import 'package:apwd/utils/constants.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  late DatabaseService dbService;
  late CryptoService cryptoService;
  late GroupService groupService;
  late PasswordService passwordService;
  late ExportImportService exportImportService;
  late String testDbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDbPath = '${Directory.systemTemp.path}/test_export_${DateTime.now().millisecondsSinceEpoch}.db';
    dbService = DatabaseService(databaseFactory: databaseFactoryFfi);
    cryptoService = CryptoService();
    groupService = GroupService(dbService);
    passwordService = PasswordService(dbService);
    exportImportService = ExportImportService(
      dbService,
      cryptoService,
      groupService,
      passwordService,
    );

    // Initialize database with dummy key
    final dummyKey = cryptoService.generateSalt();
    await dbService.initialize(testDbPath, dummyKey);
  });

  tearDown(() async {
    await dbService.close();
    try {
      await File(testDbPath).delete();
    } catch (_) {}
  });

  group('ExportImportService - Export', () {
    test('should export data to encrypted JSON', () async {
      // Create test data
      final group = Group(
        name: 'Test Group',
        icon: 'home',
        sortOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final groupId = await groupService.create(group);

      final password = PasswordEntry(
        groupId: groupId,
        title: 'Test Entry',
        username: 'testuser',
        password: 'testpass',
        url: 'https://test.com',
        notes: 'Test notes',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await passwordService.create(password);

      // Export
      final exportData = await exportImportService.exportToJson('export_password');

      // Verify it's valid JSON
      final parsed = json.decode(exportData);
      expect(parsed, isA<Map<String, dynamic>>());
      expect(parsed['version'], equals(AppConstants.exportFormatVersion));
      expect(parsed['salt'], isNotNull);
      expect(parsed['data'], isNotNull);
    });

    test('should include all groups in export', () async {
      // Create multiple groups
      await groupService.create(Group(
        name: 'Group 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await groupService.create(Group(
        name: 'Group 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final exportData = await exportImportService.exportToJson('password');

      // Decrypt and verify
      final parsed = json.decode(exportData);
      final salt = base64.decode(parsed['salt']);
      final derivedKey = await cryptoService.deriveKey('password', salt);
      final encryptionKey = cryptoService.getDatabaseKey(derivedKey);
      final decrypted = cryptoService.decryptText(parsed['data'], encryptionKey);
      final data = json.decode(decrypted);

      expect(data['groups'], hasLength(2));
    });

    test('should include all passwords in export', () async {
      // Create group and passwords
      final groupId = await groupService.create(Group(
        name: 'Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await passwordService.create(PasswordEntry(
        groupId: groupId,
        title: 'Entry 1',
        password: 'pass1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await passwordService.create(PasswordEntry(
        groupId: groupId,
        title: 'Entry 2',
        password: 'pass2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final exportData = await exportImportService.exportToJson('password');

      // Decrypt and verify
      final parsed = json.decode(exportData);
      final salt = base64.decode(parsed['salt']);
      final derivedKey = await cryptoService.deriveKey('password', salt);
      final encryptionKey = cryptoService.getDatabaseKey(derivedKey);
      final decrypted = cryptoService.decryptText(parsed['data'], encryptionKey);
      final data = json.decode(decrypted);

      expect(data['passwords'], hasLength(2));
    });

    test('should include settings in export', () async {
      // Set some settings
      await dbService.setIntSetting(AppConstants.settingAutoLockTimeout, 600);
      await dbService.setBoolSetting(AppConstants.settingBiometricEnabled, true);

      final exportData = await exportImportService.exportToJson('password');

      // Decrypt and verify
      final parsed = json.decode(exportData);
      final salt = base64.decode(parsed['salt']);
      final derivedKey = await cryptoService.deriveKey('password', salt);
      final encryptionKey = cryptoService.getDatabaseKey(derivedKey);
      final decrypted = cryptoService.decryptText(parsed['data'], encryptionKey);
      final data = json.decode(decrypted);

      expect(data['settings']['auto_lock_timeout'], equals(600));
      expect(data['settings']['biometric_enabled'], isTrue);
    });
  });

  group('ExportImportService - Import', () {
    test('should import data from encrypted JSON', () async {
      // Create and export data
      final groupId = await groupService.create(Group(
        name: 'Original Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await passwordService.create(PasswordEntry(
        groupId: groupId,
        title: 'Original Entry',
        password: 'original_pass',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final exportData = await exportImportService.exportToJson('test_password');

      // Clear database
      await dbService.close();
      await File(testDbPath).delete();
      final dummyKey = cryptoService.generateSalt();
      await dbService.initialize(testDbPath, dummyKey);

      // Import
      await exportImportService.importFromJson(exportData, 'test_password');

      // Verify imported data
      final groups = await groupService.getAll();
      expect(groups, hasLength(1));
      expect(groups[0].name, equals('Original Group'));

      final passwords = await passwordService.getAll();
      expect(passwords, hasLength(1));
      expect(passwords[0].title, equals('Original Entry'));
    });

    test('should fail import with wrong password', () async {
      // Create and export data
      final groupId = await groupService.create(Group(
        name: 'Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await passwordService.create(PasswordEntry(
        groupId: groupId,
        title: 'Entry',
        password: 'pass',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final exportData = await exportImportService.exportToJson('correct_password');

      // Clear database
      await dbService.close();
      await File(testDbPath).delete();
      final dummyKey = cryptoService.generateSalt();
      await dbService.initialize(testDbPath, dummyKey);

      // Try to import with wrong password
      expect(
        () => exportImportService.importFromJson(exportData, 'wrong_password'),
        throwsA(isA<ExportImportException>()),
      );
    });

    test('should skip existing entries when overwrite is false', () async {
      // Create initial data
      final group = Group(
        id: 1,
        name: 'Original Name',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await groupService.create(group);

      // Create export with modified name
      final exportGroup = Group(
        id: 1,
        name: 'Modified Name',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Manually create export data
      final salt = cryptoService.generateSalt();
      final derivedKey = await cryptoService.deriveKey('password', salt);
      final encryptionKey = cryptoService.getDatabaseKey(derivedKey);

      final data = {
        'version': AppConstants.exportFormatVersion,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'groups': [exportGroup.toMap()],
        'passwords': [],
        'settings': {},
      };

      final encrypted = cryptoService.encryptText(json.encode(data), encryptionKey);
      final exportData = json.encode({
        'version': AppConstants.exportFormatVersion,
        'salt': base64.encode(salt),
        'data': encrypted,
      });

      // Import without overwrite
      await exportImportService.importFromJson(exportData, 'password', overwrite: false);

      // Verify original name is preserved
      final importedGroup = await groupService.getById(1);
      expect(importedGroup!.name, equals('Original Name'));
    });

    test('should overwrite existing entries when overwrite is true', () async {
      // Create initial data
      final group = Group(
        id: 1,
        name: 'Original Name',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await groupService.create(group);

      // Create export with modified name
      final exportGroup = Group(
        id: 1,
        name: 'Modified Name',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Manually create export data
      final salt = cryptoService.generateSalt();
      final derivedKey = await cryptoService.deriveKey('password', salt);
      final encryptionKey = cryptoService.getDatabaseKey(derivedKey);

      final data = {
        'version': AppConstants.exportFormatVersion,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'groups': [exportGroup.toMap()],
        'passwords': [],
        'settings': {},
      };

      final encrypted = cryptoService.encryptText(json.encode(data), encryptionKey);
      final exportData = json.encode({
        'version': AppConstants.exportFormatVersion,
        'salt': base64.encode(salt),
        'data': encrypted,
      });

      // Import with overwrite
      await exportImportService.importFromJson(exportData, 'password', overwrite: true);

      // Verify name is updated
      final importedGroup = await groupService.getById(1);
      expect(importedGroup!.name, equals('Modified Name'));
    });

    test('should reject invalid JSON format', () async {
      expect(
        () => exportImportService.importFromJson('invalid json', 'password'),
        throwsA(isA<ExportImportException>()),
      );
    });

    test('should reject unsupported version', () async {
      final invalidExport = json.encode({
        'version': '99.0',
        'salt': base64.encode(cryptoService.generateSalt()),
        'data': 'some data',
      });

      expect(
        () => exportImportService.importFromJson(invalidExport, 'password'),
        throwsA(isA<ExportImportException>()),
      );
    });
  });

  group('ExportImportService - Backup/Restore', () {
    test('should create backup file', () async {
      // Create test data
      final groupId = await groupService.create(Group(
        name: 'Backup Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await passwordService.create(PasswordEntry(
        groupId: groupId,
        title: 'Backup Entry',
        password: 'backup_pass',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final backupPath = '${Directory.systemTemp.path}/test_backup_${DateTime.now().millisecondsSinceEpoch}.apwd';

      await exportImportService.createBackup(backupPath, 'backup_password');

      // Verify file exists
      final file = File(backupPath);
      expect(await file.exists(), isTrue);

      // Clean up
      await file.delete();
    });

    test('should restore from backup file', () async {
      // Create and backup data
      final groupId = await groupService.create(Group(
        name: 'Restore Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await passwordService.create(PasswordEntry(
        groupId: groupId,
        title: 'Restore Entry',
        password: 'restore_pass',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final backupPath = '${Directory.systemTemp.path}/test_restore_${DateTime.now().millisecondsSinceEpoch}.apwd';
      await exportImportService.createBackup(backupPath, 'backup_password');

      // Clear database
      await dbService.close();
      await File(testDbPath).delete();
      final dummyKey = cryptoService.generateSalt();
      await dbService.initialize(testDbPath, dummyKey);

      // Restore
      await exportImportService.restoreBackup(backupPath, 'backup_password');

      // Verify restored data
      final groups = await groupService.getAll();
      expect(groups, hasLength(1));
      expect(groups[0].name, equals('Restore Group'));

      final passwords = await passwordService.getAll();
      expect(passwords, hasLength(1));
      expect(passwords[0].title, equals('Restore Entry'));

      // Clean up
      await File(backupPath).delete();
    });

    test('should fail restore if backup file does not exist', () async {
      final nonExistentPath = '${Directory.systemTemp.path}/non_existent_backup.apwd';

      expect(
        () => exportImportService.restoreBackup(nonExistentPath, 'password'),
        throwsA(isA<ExportImportException>()),
      );
    });

    test('should create backup directory if it does not exist', () async {
      final groupId = await groupService.create(Group(
        name: 'Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final backupDir = '${Directory.systemTemp.path}/test_subdir_${DateTime.now().millisecondsSinceEpoch}';
      final backupPath = '$backupDir/backup.apwd';

      await exportImportService.createBackup(backupPath, 'password');

      // Verify file exists
      final file = File(backupPath);
      expect(await file.exists(), isTrue);

      // Clean up
      await Directory(backupDir).delete(recursive: true);
    });
  });
}
