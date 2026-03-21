import 'dart:typed_data';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart' as common;
import 'package:apwd/models/app_settings.dart';

/// Service for managing the encrypted SQLite database.
///
/// This service handles database initialization, schema creation, and provides
/// access to the database instance. It uses SQLCipher for encryption.
class DatabaseService {
  common.Database? _database;
  final common.DatabaseFactory? _databaseFactory;

  /// Creates a new DatabaseService.
  ///
  /// [databaseFactory] is optional and primarily used for testing with FFI.
  /// If not provided, the default SQLCipher database factory will be used.
  DatabaseService({common.DatabaseFactory? databaseFactory})
      : _databaseFactory = databaseFactory;

  /// Gets the database instance.
  ///
  /// Throws [StateError] if the database has not been initialized.
  common.Database get database {
    if (_database == null) {
      throw StateError('Database has not been initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Initializes the encrypted database.
  ///
  /// Creates the database file if it doesn't exist, sets up encryption,
  /// creates tables, and inserts default settings.
  ///
  /// [dbPath] - The file path where the database will be stored
  /// [databaseKey] - The 32-byte encryption key for SQLCipher
  ///
  /// This method is idempotent and can be called multiple times safely.
  Future<void> initialize(String dbPath, Uint8List databaseKey) async {
    print('[DB] Initialize called with dbPath: $dbPath');
    // Close existing database if open
    if (_database != null && _database!.isOpen) {
      print('[DB] Closing existing database...');
      await _database!.close();
      _database = null;
      print('[DB] Existing database closed');
    }

    // Convert key to hex string for SQLCipher
    final keyHex = databaseKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    print('[DB] Opening database with encryption... Key length: ${databaseKey.length} bytes');

    // For sqflite_sqlcipher, use openDatabase with password parameter
    if (_databaseFactory == null) {
      // Real SQLCipher implementation
      print('[DB] Using SQLCipher with password parameter');
      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _onCreate,
        password: "x'$keyHex'",  // Use password parameter for SQLCipher
        onOpen: (db) async {
          print('[DB] onOpen callback');
          // Enable foreign keys
          await db.execute('PRAGMA foreign_keys = ON');
          print('[DB] onOpen completed');
        },
      );
    } else {
      // Test mode with FFI
      print('[DB] Using test database factory');
      _database = await _databaseFactory!.openDatabase(
        dbPath,
        options: common.OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
          onOpen: (db) async {
            print('[DB] onOpen callback (test mode)');
            await db.execute('PRAGMA foreign_keys = ON');
          },
        ),
      );
    }
    print('[DB] Database opened successfully, isOpen: ${_database!.isOpen}');
  }

  /// Creates the database schema and inserts default data.
  ///
  /// Called automatically when the database is first created.
  Future<void> _onCreate(common.Database db, int version) async {
    // Create groups table
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create password_entries table
    await db.execute('''
      CREATE TABLE password_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        url TEXT,
        username TEXT,
        password TEXT NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        auto_lock_timeout INTEGER NOT NULL DEFAULT 300,
        biometric_enabled INTEGER NOT NULL DEFAULT 0,
        clipboard_clear_timeout INTEGER NOT NULL DEFAULT 30
      )
    ''');

    // Create app_settings table for key-value storage
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_groups_name ON groups(name)
    ''');

    await db.execute('''
      CREATE INDEX idx_password_entries_group_id ON password_entries(group_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_password_entries_title ON password_entries(title)
    ''');

    // Insert default settings
    final defaultSettings = const AppSettings();
    await db.insert('settings', defaultSettings.toMap());

    // Insert default groups
    await _createDefaultGroups(db);
  }

  /// Creates default groups for a new database.
  ///
  /// Only creates a single "Default" group. Users can add more groups later
  /// through the group management interface.
  Future<void> _createDefaultGroups(common.Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Only create one default group - users can add more as needed
    await db.insert('groups', {
      'name': 'Default',
      'icon': '🔑',
      'sort_order': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  /// Closes the database connection.
  ///
  /// After calling this method, the database property will throw [StateError]
  /// until initialize() is called again.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Save a setting value
  Future<void> setSetting(String key, String value) async {
    if (_database == null) {
      throw StateError('Database not initialized');
    }

    await _database!.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a setting value
  Future<String?> getSetting(String key) async {
    if (_database == null) {
      throw StateError('Database not initialized');
    }

    final results = await _database!.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String?;
  }

  /// Save an integer setting
  Future<void> setIntSetting(String key, int value) async {
    await setSetting(key, value.toString());
  }

  /// Get an integer setting
  Future<int?> getIntSetting(String key, {int? defaultValue}) async {
    final value = await getSetting(key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Save a boolean setting
  Future<void> setBoolSetting(String key, bool value) async {
    await setSetting(key, value.toString());
  }

  /// Get a boolean setting
  Future<bool?> getBoolSetting(String key, {bool? defaultValue}) async {
    final value = await getSetting(key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }
}
