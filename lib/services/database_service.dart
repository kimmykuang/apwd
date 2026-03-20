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
    // Close existing database if open
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }

    // Use provided database factory (for testing) or default
    final factory = _databaseFactory ?? databaseFactory;

    // Convert key to hex string for SQLCipher
    final keyHex = databaseKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');

    // Open database with encryption
    _database = await factory.openDatabase(
      dbPath,
      options: common.OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
        onConfigure: (db) async {
          // Set encryption key (only for SQLCipher, not FFI)
          if (_databaseFactory == null) {
            await db.rawQuery("PRAGMA key = \"x'$keyHex'\"");
          }

          // Enable foreign keys
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onOpen: (db) async {
          // Ensure foreign keys are enabled on every open
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
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
}
