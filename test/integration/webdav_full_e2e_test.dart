import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:apwd/services/database_service.dart';
import 'package:apwd/services/crypto_service.dart';
import 'package:apwd/services/group_service.dart';
import 'package:apwd/services/password_service.dart';
import 'package:apwd/services/export_import_service.dart';
import 'package:apwd/services/webdav_service.dart';
import 'package:apwd/providers/webdav_provider.dart';
import 'package:apwd/models/group.dart';
import 'package:apwd/models/password_entry.dart';

/// Full self-contained end-to-end test for WebDAV backup and restore
///
/// This test simulates the complete user workflow:
/// 1. Create password entries
/// 2. Configure WebDAV (simulated with local file system)
/// 3. Backup to WebDAV
/// 4. Clear local data
/// 5. Restore from WebDAV
/// 6. Verify data integrity
///
/// Note: Uses local file system to simulate WebDAV storage for self-contained testing
void main() {
  late DatabaseService dbService;
  late CryptoService cryptoService;
  late GroupService groupService;
  late PasswordService passwordService;
  late ExportImportService exportImportService;
  late WebDavService webdavService;
  late WebDavProvider webdavProvider;
  late String testDbPath;
  late Directory testWebDavDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Setup database
    testDbPath = '${Directory.systemTemp.path}/test_full_e2e_${DateTime.now().millisecondsSinceEpoch}.db';
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
    webdavService = WebDavService();
    webdavProvider = WebDavProvider(
      webdavService,
      exportImportService,
      dbService,
    );

    // Initialize database
    final dummyKey = cryptoService.generateSalt();
    await dbService.initialize(testDbPath, dummyKey);

    // Setup simulated WebDAV directory
    testWebDavDir = Directory('${Directory.systemTemp.path}/test_webdav_${DateTime.now().millisecondsSinceEpoch}');
    await testWebDavDir.create();
  });

  tearDown(() async {
    await dbService.close();
    try {
      await File(testDbPath).delete();
      await testWebDavDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Full WebDAV Workflow Self-Contained Test', () {
    test('complete workflow: create → backup → clear → restore → verify', () async {
      print('\n=== PHASE 1: Create Test Data ===');

      // Create groups
      final personalGroup = Group(
        name: 'Personal',
        icon: 'person',
        sortOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final personalGroupId = await groupService.create(personalGroup);
      print('✓ Created group: Personal (ID: $personalGroupId)');

      final workGroup = Group(
        name: 'Work',
        icon: 'work',
        sortOrder: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final workGroupId = await groupService.create(workGroup);
      print('✓ Created group: Work (ID: $workGroupId)');

      // Create passwords
      final passwords = [
        PasswordEntry(
          groupId: personalGroupId,
          title: 'Gmail Account',
          username: 'test@gmail.com',
          password: 'SecurePass123!',
          url: 'https://gmail.com',
          notes: 'Personal email',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PasswordEntry(
          groupId: personalGroupId,
          title: 'GitHub',
          username: 'testuser',
          password: 'GitHubPass456!',
          url: 'https://github.com',
          notes: 'Dev account',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PasswordEntry(
          groupId: workGroupId,
          title: 'Company Portal',
          username: 'employee001',
          password: 'WorkPass789!',
          url: 'https://company.com/portal',
          notes: 'Internal system',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (var password in passwords) {
        final id = await passwordService.create(password);
        print('✓ Created password: ${password.title} (ID: $id)');
      }

      // Verify initial state
      final initialGroups = await groupService.getAll();
      final initialPasswords = await passwordService.getAll();
      expect(initialGroups.length, greaterThanOrEqualTo(2));
      expect(initialPasswords.length, 3);
      print('✓ Initial state verified: ${initialGroups.length} groups, ${initialPasswords.length} passwords\n');

      print('=== PHASE 2: Backup to WebDAV (Simulated) ===');

      // Create backup file
      const backupPassword = 'MyBackupPassword123!';
      final backupPath = await exportImportService.createTempBackup(backupPassword);
      print('✓ Created encrypted backup: $backupPath');

      // Verify backup file
      final backupFile = File(backupPath);
      final backupSize = await backupFile.length();
      expect(await backupFile.exists(), true);
      expect(backupSize, greaterThan(0));
      print('✓ Backup file verified: ${(backupSize / 1024).toStringAsFixed(2)} KB');

      // Simulate WebDAV upload by copying to simulated WebDAV directory
      final fileName = exportImportService.generateBackupFileName();
      final webdavBackupPath = '${testWebDavDir.path}/$fileName';
      await backupFile.copy(webdavBackupPath);
      await backupFile.delete();
      print('✓ Backup uploaded to WebDAV: $fileName\n');

      print('=== PHASE 3: Simulate Data Loss ===');

      // Record what we had before clearing
      final beforeClearGroups = await groupService.getAll();
      final beforeClearPasswords = await passwordService.getAll();
      final personalGroupBeforeClear = beforeClearGroups.firstWhere((g) => g.name == 'Personal');
      final workGroupBeforeClear = beforeClearGroups.firstWhere((g) => g.name == 'Work');

      print('Recording data before clear:');
      for (var group in beforeClearGroups) {
        print('  Group: ${group.name} (ID: ${group.id})');
      }
      for (var password in beforeClearPasswords) {
        print('  Password: ${password.title} (Group ID: ${password.groupId})');
      }

      // Delete all passwords
      for (var password in beforeClearPasswords) {
        if (password.id != null) {
          await passwordService.delete(password.id!);
          print('✓ Deleted password: ${password.title}');
        }
      }

      // Delete all user groups (keep default group)
      for (var group in beforeClearGroups) {
        if (group.id != null && group.id != 1) {
          await groupService.delete(group.id!);
          print('✓ Deleted group: ${group.name}');
        }
      }

      // Verify data cleared
      final afterClearGroups = await groupService.getAll();
      final afterClearPasswords = await passwordService.getAll();
      expect(afterClearPasswords.length, 0);
      print('✓ Data cleared: ${afterClearGroups.length} groups (default only), ${afterClearPasswords.length} passwords\n');

      print('=== PHASE 4: Restore from WebDAV ===');

      // Simulate WebDAV download
      final downloadPath = '${Directory.systemTemp.path}/downloaded_$fileName';
      await File(webdavBackupPath).copy(downloadPath);
      print('✓ Downloaded backup from WebDAV');

      // Restore from backup
      await exportImportService.restoreFromFile(
        downloadPath,
        backupPassword,
        overwrite: false,
      );
      print('✓ Restored data from backup\n');

      // Cleanup download file
      try {
        await File(downloadPath).delete();
      } catch (_) {}

      print('=== PHASE 5: Verify Restored Data ===');

      final restoredGroups = await groupService.getAll();
      final restoredPasswords = await passwordService.getAll();

      print('Restored data:');
      print('  Groups: ${restoredGroups.length}');
      for (var group in restoredGroups) {
        print('    - ${group.name} (ID: ${group.id}, icon: ${group.icon}, sort: ${group.sortOrder})');
      }
      print('  Passwords: ${restoredPasswords.length}');
      for (var password in restoredPasswords) {
        print('    - ${password.title} (Group ID: ${password.groupId})');
      }

      // Verify counts
      expect(restoredGroups.length, greaterThanOrEqualTo(2));
      expect(restoredPasswords.length, 3);
      print('✓ Count verification passed');

      // Verify groups exist
      final personalGroupRestored = restoredGroups.firstWhere(
        (g) => g.name == 'Personal',
        orElse: () => throw Exception('Personal group not found'),
      );
      expect(personalGroupRestored.icon, 'person');
      expect(personalGroupRestored.sortOrder, 1);
      print('✓ Personal group verified');

      final workGroupRestored = restoredGroups.firstWhere(
        (g) => g.name == 'Work',
        orElse: () => throw Exception('Work group not found'),
      );
      expect(workGroupRestored.icon, 'work');
      expect(workGroupRestored.sortOrder, 2);
      print('✓ Work group verified');

      // Verify passwords
      final gmailPassword = restoredPasswords.firstWhere(
        (p) => p.title == 'Gmail Account',
        orElse: () => throw Exception('Gmail password not found'),
      );
      expect(gmailPassword.username, 'test@gmail.com');
      expect(gmailPassword.password, 'SecurePass123!');
      expect(gmailPassword.url, 'https://gmail.com');
      expect(gmailPassword.notes, 'Personal email');
      print('✓ Gmail password verified');

      final githubPassword = restoredPasswords.firstWhere(
        (p) => p.title == 'GitHub',
        orElse: () => throw Exception('GitHub password not found'),
      );
      expect(githubPassword.username, 'testuser');
      expect(githubPassword.password, 'GitHubPass456!');
      print('✓ GitHub password verified');

      final companyPassword = restoredPasswords.firstWhere(
        (p) => p.title == 'Company Portal',
        orElse: () => throw Exception('Company password not found'),
      );
      expect(companyPassword.username, 'employee001');
      expect(companyPassword.password, 'WorkPass789!');
      expect(companyPassword.url, 'https://company.com/portal');
      print('✓ Company password verified');

      print('\n✅ All data integrity checks passed!');
      print('✅ Full workflow test completed successfully!\n');
    });

    test('backup file format validation', () async {
      print('\n=== Testing Backup File Format ===');

      // Create minimal data
      final groupId = await groupService.create(Group(
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await passwordService.create(PasswordEntry(
        groupId: groupId,
        title: 'Test Entry',
        password: 'test123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Generate backup
      const password = 'TestPassword123';
      final backupPath = await exportImportService.createTempBackup(password);
      final backupFile = File(backupPath);

      // Verify filename format
      final fileName = backupPath.split('/').last;
      expect(fileName, matches(RegExp(r'^apwd_backup_\d{8}_\d{6}\.apwd$')));
      print('✓ Filename format: $fileName');

      // Verify file exists and has content
      expect(await backupFile.exists(), true);
      final size = await backupFile.length();
      expect(size, greaterThan(100));
      print('✓ File size: $size bytes');

      // Verify file extension
      expect(fileName.endsWith('.apwd'), true);
      print('✓ File extension: .apwd');

      print('✅ Backup file format validation passed!\n');
    });

    test('wrong password rejection', () async {
      print('\n=== Testing Wrong Password Rejection ===');

      // Create data and backup
      final groupId = await groupService.create(Group(
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await passwordService.create(PasswordEntry(
        groupId: groupId,
        title: 'Test',
        password: 'test123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      const correctPassword = 'CorrectPassword123';
      final backupPath = await exportImportService.createTempBackup(correctPassword);
      print('✓ Created backup with correct password');

      // Try wrong password
      const wrongPassword = 'WrongPassword456';
      try {
        await exportImportService.restoreFromFile(backupPath, wrongPassword);
        fail('Should have thrown exception for wrong password');
      } catch (e) {
        print('✓ Wrong password correctly rejected: ${e.toString()}');
        expect(e, isA<Exception>());
      }

      // Verify correct password works
      await exportImportService.restoreFromFile(backupPath, correctPassword);
      print('✓ Correct password accepted');

      // Cleanup
      try {
        await File(backupPath).delete();
      } catch (_) {}
      print('✅ Password validation test passed!\n');
    });

    test('performance test with realistic dataset', () async {
      print('\n=== Testing Performance with Realistic Dataset ===');

      // Create realistic dataset: 5 groups, 25 passwords
      print('Creating test dataset...');
      final groupIds = <int>[];
      for (int i = 0; i < 5; i++) {
        final id = await groupService.create(Group(
          name: 'Group $i',
          icon: 'icon$i',
          sortOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        groupIds.add(id);
      }

      for (int i = 0; i < 25; i++) {
        await passwordService.create(PasswordEntry(
          groupId: groupIds[i % groupIds.length],
          title: 'Entry $i',
          username: 'user$i@example.com',
          password: 'SecurePassword$i!',
          url: 'https://site$i.example.com',
          notes: 'Notes for entry $i with some additional text to simulate real-world data',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
      print('✓ Created 5 groups and 25 passwords');

      // Measure backup time
      final backupStopwatch = Stopwatch()..start();
      final backupPath = await exportImportService.createTempBackup('PerformanceTest123');
      backupStopwatch.stop();

      final backupSize = await File(backupPath).length();
      print('✓ Backup completed in ${backupStopwatch.elapsedMilliseconds}ms');
      print('  File size: ${(backupSize / 1024).toStringAsFixed(2)} KB');
      expect(backupStopwatch.elapsedMilliseconds, lessThan(5000)); // Should be under 5 seconds

      // Clear data
      for (var id in groupIds) {
        await groupService.delete(id);
      }

      // Measure restore time
      final restoreStopwatch = Stopwatch()..start();
      await exportImportService.restoreFromFile(backupPath, 'PerformanceTest123');
      restoreStopwatch.stop();

      print('✓ Restore completed in ${restoreStopwatch.elapsedMilliseconds}ms');
      expect(restoreStopwatch.elapsedMilliseconds, lessThan(5000)); // Should be under 5 seconds

      // Verify data
      final restoredGroups = await groupService.getAll();
      final restoredPasswords = await passwordService.getAll();
      expect(restoredGroups.length, greaterThanOrEqualTo(5));
      expect(restoredPasswords.length, 25);
      print('✓ Data integrity verified');

      // Cleanup
      try {
        await File(backupPath).delete();
      } catch (_) {
        // File may have been moved/deleted during test
      }
      print('✅ Performance test passed!\n');
    });
  });
}
