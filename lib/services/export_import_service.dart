import 'dart:convert';
import 'dart:io';
import 'package:apwd/models/group.dart';
import 'package:apwd/models/password_entry.dart';
import 'package:apwd/services/crypto_service.dart';
import 'package:apwd/services/group_service.dart';
import 'package:apwd/services/password_service.dart';
import 'package:apwd/services/database_service.dart';
import 'package:apwd/utils/constants.dart';

/// Exception thrown when export/import operations fail
class ExportImportException implements Exception {
  final String message;
  ExportImportException(this.message);

  @override
  String toString() => 'ExportImportException: $message';
}

/// Service for exporting and importing encrypted data
class ExportImportService {
  final DatabaseService _dbService;
  final CryptoService _cryptoService;
  final GroupService _groupService;
  final PasswordService _passwordService;

  ExportImportService(
    this._dbService,
    this._cryptoService,
    this._groupService,
    this._passwordService,
  );

  /// Export all data to encrypted JSON
  ///
  /// Exports groups, passwords, and settings in an encrypted format.
  /// Returns the encrypted JSON string.
  ///
  /// [password] - Password to encrypt the export data
  Future<String> exportToJson(String password) async {
    try {
      // Generate salt for export encryption
      final salt = _cryptoService.generateSalt();
      final saltBase64 = base64.encode(salt);

      // Derive encryption key from password
      final derivedKey = await _cryptoService.deriveKey(password, salt);
      final encryptionKey = _cryptoService.getDatabaseKey(derivedKey);

      // Gather all data
      final groups = await _groupService.getAll();
      final passwords = await _passwordService.getAll();

      // Get settings
      final autoLockTimeout = await _dbService.getIntSetting(
        AppConstants.settingAutoLockTimeout,
        defaultValue: AppConstants.defaultAutoLockTimeout,
      );
      final biometricEnabled = await _dbService.getBoolSetting(
        AppConstants.settingBiometricEnabled,
        defaultValue: false,
      );
      final clipboardTimeout = await _dbService.getIntSetting(
        AppConstants.settingClipboardClearTimeout,
        defaultValue: AppConstants.defaultClipboardClearTimeout,
      );

      // Build data structure
      final data = {
        'version': AppConstants.exportFormatVersion,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'groups': groups.map((g) => g.toMap()).toList(),
        'passwords': passwords.map((p) => p.toMap()).toList(),
        'settings': {
          'auto_lock_timeout': autoLockTimeout,
          'biometric_enabled': biometricEnabled,
          'clipboard_clear_timeout': clipboardTimeout,
        },
      };

      // Convert to JSON string
      final jsonString = json.encode(data);

      // Encrypt the JSON
      final encrypted = _cryptoService.encryptText(jsonString, encryptionKey);

      // Build final export structure with salt
      final exportData = {
        'version': AppConstants.exportFormatVersion,
        'salt': saltBase64,
        'data': encrypted,
      };

      return json.encode(exportData);
    } catch (e) {
      throw ExportImportException('Export failed: ${e.toString()}');
    }
  }

  /// Import data from encrypted JSON
  ///
  /// Imports groups, passwords, and settings from encrypted JSON.
  /// Existing data with the same IDs will be skipped by default.
  ///
  /// [jsonData] - The encrypted JSON string to import
  /// [password] - Password to decrypt the import data
  /// [overwrite] - If true, overwrite existing entries with same ID
  Future<void> importFromJson(
    String jsonData,
    String password, {
    bool overwrite = false,
  }) async {
    try {
      // Parse outer structure
      final Map<String, dynamic> exportData = json.decode(jsonData);

      // Validate structure
      if (!exportData.containsKey('version') ||
          !exportData.containsKey('salt') ||
          !exportData.containsKey('data')) {
        throw ExportImportException('Invalid export format');
      }

      final version = exportData['version'] as String;
      if (version != AppConstants.exportFormatVersion) {
        throw ExportImportException('Unsupported export version: $version');
      }

      final saltBase64 = exportData['salt'] as String;
      final encrypted = exportData['data'] as String;

      // Derive decryption key
      final salt = base64.decode(saltBase64);
      final derivedKey = await _cryptoService.deriveKey(password, salt);
      final decryptionKey = _cryptoService.getDatabaseKey(derivedKey);

      // Decrypt the data
      final decryptedJson = _cryptoService.decryptText(encrypted, decryptionKey);
      final Map<String, dynamic> data = json.decode(decryptedJson);

      // Validate inner structure
      if (!data.containsKey('groups') || !data.containsKey('passwords')) {
        throw ExportImportException('Invalid data structure');
      }

      // Import groups
      final groupsList = data['groups'] as List;
      final Map<int, int> groupIdMapping = {}; // old ID -> new ID

      for (var groupMap in groupsList) {
        final oldId = groupMap['id'] as int?;
        final group = Group.fromMap(groupMap);

        // Check if group already exists
        final existingGroup = oldId != null ? await _groupService.getById(oldId) : null;

        int newId;
        if (existingGroup != null && !overwrite) {
          // Skip existing group
          newId = existingGroup.id!;
        } else if (existingGroup != null && overwrite) {
          // Update existing group
          await _groupService.update(group);
          newId = group.id!;
        } else {
          // Create new group
          newId = await _groupService.create(group.copyWith(id: null));
        }

        if (oldId != null) {
          groupIdMapping[oldId] = newId;
        }
      }

      // Import passwords
      final passwordsList = data['passwords'] as List;

      for (var passwordMap in passwordsList) {
        final oldId = passwordMap['id'] as int?;
        final oldGroupId = passwordMap['group_id'] as int;

        // Map old group ID to new group ID
        final newGroupId = groupIdMapping[oldGroupId] ?? oldGroupId;

        final password = PasswordEntry.fromMap({
          ...passwordMap,
          'group_id': newGroupId,
        });

        // Check if password already exists
        final existingPassword = oldId != null ? await _passwordService.getById(oldId) : null;

        if (existingPassword != null && !overwrite) {
          // Skip existing password
          continue;
        } else if (existingPassword != null && overwrite) {
          // Update existing password
          await _passwordService.update(password);
        } else {
          // Create new password
          await _passwordService.create(password.copyWith(id: null));
        }
      }

      // Import settings if present
      if (data.containsKey('settings')) {
        final settings = data['settings'] as Map<String, dynamic>;

        if (settings.containsKey('auto_lock_timeout')) {
          await _dbService.setIntSetting(
            AppConstants.settingAutoLockTimeout,
            settings['auto_lock_timeout'] as int,
          );
        }

        if (settings.containsKey('biometric_enabled')) {
          await _dbService.setBoolSetting(
            AppConstants.settingBiometricEnabled,
            settings['biometric_enabled'] as bool,
          );
        }

        if (settings.containsKey('clipboard_clear_timeout')) {
          await _dbService.setIntSetting(
            AppConstants.settingClipboardClearTimeout,
            settings['clipboard_clear_timeout'] as int,
          );
        }
      }
    } catch (e) {
      if (e is ExportImportException) rethrow;
      throw ExportImportException('Import failed: ${e.toString()}');
    }
  }

  /// Create encrypted backup file
  ///
  /// Creates a backup file at the specified path with all data encrypted.
  ///
  /// [filePath] - Path where backup file will be created
  /// [password] - Password to encrypt the backup
  Future<void> createBackup(String filePath, String password) async {
    try {
      final exportData = await exportToJson(password);
      final file = File(filePath);

      // Ensure directory exists
      await file.parent.create(recursive: true);

      // Write to file
      await file.writeAsString(exportData);
    } catch (e) {
      throw ExportImportException('Backup creation failed: ${e.toString()}');
    }
  }

  /// Restore from encrypted backup file
  ///
  /// Restores data from a backup file.
  ///
  /// [filePath] - Path to the backup file
  /// [password] - Password to decrypt the backup
  /// [overwrite] - If true, overwrite existing entries
  Future<void> restoreBackup(
    String filePath,
    String password, {
    bool overwrite = false,
  }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw ExportImportException('Backup file not found: $filePath');
      }

      final jsonData = await file.readAsString();
      await importFromJson(jsonData, password, overwrite: overwrite);
    } catch (e) {
      if (e is ExportImportException) rethrow;
      throw ExportImportException('Backup restoration failed: ${e.toString()}');
    }
  }

  /// Create temporary backup file for WebDAV upload
  ///
  /// Creates a backup file in the system temp directory and returns its path.
  /// The file should be deleted after upload.
  ///
  /// [password] - Password to encrypt the backup
  /// Returns the path to the temporary backup file
  Future<String> createTempBackup(String password) async {
    try {
      // Generate backup filename with timestamp
      final fileName = generateBackupFileName();

      // Get temp directory
      final tempDir = Directory.systemTemp;
      final filePath = '${tempDir.path}/$fileName';

      // Create backup
      await createBackup(filePath, password);

      return filePath;
    } catch (e) {
      throw ExportImportException('Temp backup creation failed: ${e.toString()}');
    }
  }

  /// Restore from file path (alias for restoreBackup for consistency)
  ///
  /// [filePath] - Path to the backup file
  /// [password] - Password to decrypt the backup
  /// [overwrite] - If true, overwrite existing entries
  Future<void> restoreFromFile(
    String filePath,
    String password, {
    bool overwrite = false,
  }) async {
    await restoreBackup(filePath, password, overwrite: overwrite);
  }

  /// Generate backup filename with timestamp
  ///
  /// Returns filename in format: apwd_backup_YYYYMMDD_HHMMSS.apwd
  /// Example: apwd_backup_20260323_143022.apwd
  String generateBackupFileName() {
    final now = DateTime.now();
    final timestamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return 'apwd_backup_$timestamp${AppConstants.exportFileExtension}';
  }
}
