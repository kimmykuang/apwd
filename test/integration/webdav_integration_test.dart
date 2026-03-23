import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apwd/services/database_service.dart';
import 'package:apwd/services/crypto_service.dart';
import 'package:apwd/services/group_service.dart';
import 'package:apwd/services/password_service.dart';
import 'package:apwd/services/export_import_service.dart';
import 'package:apwd/models/group.dart';
import 'package:apwd/models/password_entry.dart';

/// Integration tests for WebDAV backup and restore workflow
///
/// These tests verify the complete end-to-end flow of:
/// 1. Creating test data
/// 2. Exporting to encrypted backup file
/// 3. Clearing local data
/// 4. Importing from backup file
/// 5. Verifying data integrity
///
/// Note: These tests don't require actual WebDAV server connection
/// as they test the file-based backup/restore logic that WebDAV uses.
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
    testDbPath = '${Directory.systemTemp.path}/test_integration_${DateTime.now().millisecondsSinceEpoch}.db';
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

  group('End-to-End WebDAV Backup and Restore Workflow', () {
    test('complete backup and restore cycle preserves all data', () async {
      // === STEP 1: Create test data ===
      print('[E2E] Step 1: Creating test data');

      // Create multiple groups
      final group1 = Group(
        name: 'Personal',
        icon: 'person',
        sortOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final group1Id = await groupService.create(group1);

      final group2 = Group(
        name: 'Work',
        icon: 'work',
        sortOrder: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final group2Id = await groupService.create(group2);

      // Create multiple passwords
      final password1 = PasswordEntry(
        groupId: group1Id,
        title: 'Gmail',
        username: 'user@gmail.com',
        password: 'secure_password_123',
        url: 'https://gmail.com',
        notes: 'Personal email account',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final pass1Id = await passwordService.create(password1);

      final password2 = PasswordEntry(
        groupId: group1Id,
        title: 'Facebook',
        username: 'user123',
        password: 'fb_pass_456',
        url: 'https://facebook.com',
        notes: 'Social media',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final pass2Id = await passwordService.create(password2);

      final password3 = PasswordEntry(
        groupId: group2Id,
        title: 'Company Portal',
        username: 'employee001',
        password: 'work_pass_789',
        url: 'https://company.com',
        notes: 'Work login',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final pass3Id = await passwordService.create(password3);

      // Verify initial data (database creates a default "Default" group)
      final initialGroups = await groupService.getAll();
      final initialPasswords = await passwordService.getAll();
      expect(initialGroups.length, 3); // 2 created + 1 default
      expect(initialPasswords.length, 3);
      print('[E2E] Initial data: ${initialGroups.length} groups (including default), ${initialPasswords.length} passwords');

      // === STEP 2: Create backup (simulating WebDAV upload) ===
      print('[E2E] Step 2: Creating encrypted backup');

      const backupPassword = 'backup_encryption_password';
      final backupPath = await exportImportService.createTempBackup(backupPassword);

      // Verify backup file exists
      final backupFile = File(backupPath);
      expect(await backupFile.exists(), true);
      final backupSize = await backupFile.length();
      expect(backupSize, greaterThan(0));
      print('[E2E] Backup created: $backupPath (${backupSize} bytes)');

      // === STEP 3: Clear local data (simulating data loss) ===
      print('[E2E] Step 3: Clearing local data');

      // Delete all passwords
      await passwordService.delete(pass1Id);
      await passwordService.delete(pass2Id);
      await passwordService.delete(pass3Id);

      // Delete all groups (including default group with ID 1)
      await groupService.delete(1); // Default group
      await groupService.delete(group1Id);
      await groupService.delete(group2Id);

      // Verify data is cleared
      final clearedGroups = await groupService.getAll();
      final clearedPasswords = await passwordService.getAll();
      expect(clearedGroups.length, 0);
      expect(clearedPasswords.length, 0);
      print('[E2E] Data cleared: ${clearedGroups.length} groups, ${clearedPasswords.length} passwords');

      // === STEP 4: Restore from backup (simulating WebDAV download) ===
      print('[E2E] Step 4: Restoring from backup');

      await exportImportService.restoreFromFile(
        backupPath,
        backupPassword,
        overwrite: false,
      );

      // === STEP 5: Verify restored data ===
      print('[E2E] Step 5: Verifying restored data');

      final restoredGroups = await groupService.getAll();
      final restoredPasswords = await passwordService.getAll();

      // Verify counts (including default group)
      expect(restoredGroups.length, 3); // 2 created + 1 default
      expect(restoredPasswords.length, 3);
      print('[E2E] Restored: ${restoredGroups.length} groups (including default), ${restoredPasswords.length} passwords');

      // Verify group data
      final personalGroup = restoredGroups.firstWhere((g) => g.name == 'Personal');
      expect(personalGroup.icon, 'person');
      expect(personalGroup.sortOrder, 1);

      final workGroup = restoredGroups.firstWhere((g) => g.name == 'Work');
      expect(workGroup.icon, 'work');
      expect(workGroup.sortOrder, 2);

      // Verify password data
      final gmailPass = restoredPasswords.firstWhere((p) => p.title == 'Gmail');
      expect(gmailPass.username, 'user@gmail.com');
      expect(gmailPass.password, 'secure_password_123');
      expect(gmailPass.url, 'https://gmail.com');
      expect(gmailPass.notes, 'Personal email account');

      final fbPass = restoredPasswords.firstWhere((p) => p.title == 'Facebook');
      expect(fbPass.username, 'user123');
      expect(fbPass.password, 'fb_pass_456');

      final workPass = restoredPasswords.firstWhere((p) => p.title == 'Company Portal');
      expect(workPass.username, 'employee001');
      expect(workPass.password, 'work_pass_789');

      print('[E2E] ✅ All data verified successfully!');

      // Cleanup backup file
      await backupFile.delete();
    });

    test('backup file has correct format and structure', () async {
      // Create minimal test data
      final group = Group(
        name: 'Test Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await groupService.create(group);

      // Create backup
      const backupPassword = 'test_password';
      final backupPath = await exportImportService.createTempBackup(backupPassword);

      // Verify file exists and is not empty
      final backupFile = File(backupPath);
      expect(await backupFile.exists(), true);
      expect(await backupFile.length(), greaterThan(0));

      // Verify filename format
      final fileName = backupPath.split('/').last;
      expect(fileName, startsWith('apwd_backup_'));
      expect(fileName, endsWith('.apwd'));
      expect(fileName, matches(RegExp(r'apwd_backup_\d{8}_\d{6}\.apwd')));

      print('[E2E] Backup filename: $fileName');

      // Cleanup
      await backupFile.delete();
    });

    test('restore with skip mode preserves existing data', () async {
      // Create initial data
      final group = Group(
        name: 'Original Group',
        icon: 'original',
        sortOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final groupId = await groupService.create(group);

      final password = PasswordEntry(
        groupId: groupId,
        title: 'Original Entry',
        username: 'original_user',
        password: 'original_pass',
        url: 'https://original.com',
        notes: 'Original notes',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await passwordService.create(password);

      // Create backup
      const backupPassword = 'backup_pass';
      final backupPath = await exportImportService.createTempBackup(backupPassword);

      // Modify the existing data
      final modifiedGroup = group.copyWith(
        id: groupId,
        name: 'Modified Group',
        icon: 'modified',
      );
      await groupService.update(modifiedGroup);

      // Restore with skip mode
      await exportImportService.restoreFromFile(
        backupPath,
        backupPassword,
        overwrite: false, // Skip existing
      );

      // Verify that existing data was NOT overwritten
      final restoredGroup = await groupService.getById(groupId);
      expect(restoredGroup!.name, 'Modified Group'); // Should keep modified data
      expect(restoredGroup.icon, 'modified');

      print('[E2E] ✅ Skip mode preserved existing data');

      // Cleanup
      await File(backupPath).delete();
    });

    test('restore with overwrite mode replaces existing data', () async {
      // Create initial data
      final group = Group(
        name: 'Original Group',
        icon: 'original',
        sortOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final groupId = await groupService.create(group);

      // Create backup
      const backupPassword = 'backup_pass';
      final backupPath = await exportImportService.createTempBackup(backupPassword);

      // Modify the existing data
      final modifiedGroup = group.copyWith(
        id: groupId,
        name: 'Modified Group',
        icon: 'modified',
      );
      await groupService.update(modifiedGroup);

      // Verify modification
      final beforeRestore = await groupService.getById(groupId);
      expect(beforeRestore!.name, 'Modified Group');

      // Restore with overwrite mode
      await exportImportService.restoreFromFile(
        backupPath,
        backupPassword,
        overwrite: true, // Overwrite existing
      );

      // Verify that data was restored to original
      final restoredGroup = await groupService.getById(groupId);
      expect(restoredGroup!.name, 'Original Group'); // Should restore original data
      expect(restoredGroup.icon, 'original');

      print('[E2E] ✅ Overwrite mode replaced existing data');

      // Cleanup
      await File(backupPath).delete();
    });

    test('wrong backup password fails to restore', () async {
      // Create test data
      final group = Group(
        name: 'Test Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await groupService.create(group);

      // Create backup with one password
      const correctPassword = 'correct_password';
      final backupPath = await exportImportService.createTempBackup(correctPassword);

      // Try to restore with wrong password
      const wrongPassword = 'wrong_password';
      expect(
        () => exportImportService.restoreFromFile(
          backupPath,
          wrongPassword,
          overwrite: false,
        ),
        throwsException,
      );

      print('[E2E] ✅ Wrong password rejected as expected');

      // Cleanup
      await File(backupPath).delete();
    });

    test('backup with large dataset completes successfully', () async {
      print('[E2E] Creating large dataset for stress test');

      // Create multiple groups
      final groupIds = <int>[];
      for (int i = 0; i < 10; i++) {
        final group = Group(
          name: 'Group $i',
          icon: 'icon_$i',
          sortOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        groupIds.add(await groupService.create(group));
      }

      // Create many passwords
      for (int i = 0; i < 50; i++) {
        final password = PasswordEntry(
          groupId: groupIds[i % groupIds.length],
          title: 'Entry $i',
          username: 'user_$i',
          password: 'password_$i',
          url: 'https://site$i.com',
          notes: 'Notes for entry $i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await passwordService.create(password);
      }

      print('[E2E] Created 10 groups and 50 passwords');

      // Backup
      const backupPassword = 'stress_test_password';
      final stopwatch = Stopwatch()..start();
      final backupPath = await exportImportService.createTempBackup(backupPassword);
      stopwatch.stop();

      print('[E2E] Backup completed in ${stopwatch.elapsedMilliseconds}ms');

      // Verify file size is reasonable
      final backupSize = await File(backupPath).length();
      expect(backupSize, greaterThan(0));
      print('[E2E] Backup size: ${(backupSize / 1024).toStringAsFixed(2)} KB');

      // Clear and restore (also delete default group)
      await groupService.delete(1); // Default group
      for (var id in groupIds) {
        await groupService.delete(id);
      }

      stopwatch.reset();
      stopwatch.start();
      await exportImportService.restoreFromFile(
        backupPath,
        backupPassword,
        overwrite: false,
      );
      stopwatch.stop();

      print('[E2E] Restore completed in ${stopwatch.elapsedMilliseconds}ms');

      // Verify restoration (including default group)
      final restoredGroups = await groupService.getAll();
      final restoredPasswords = await passwordService.getAll();
      expect(restoredGroups.length, 11); // 10 created + 1 default
      expect(restoredPasswords.length, 50);

      print('[E2E] ✅ Large dataset backup/restore successful');

      // Cleanup
      await File(backupPath).delete();
    });
  });
}
