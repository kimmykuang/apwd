import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/password_entry.dart';
import 'database_service.dart';

/// Service for password entry operations
class PasswordService {
  final DatabaseService _dbService;

  PasswordService(this._dbService);

  Database get _db {
    if (_dbService.database == null) {
      throw StateError('Database not initialized');
    }
    return _dbService.database!;
  }

  /// Create a new password entry
  Future<int> create(PasswordEntry entry) async {
    return await _db.insert('password_entries', entry.toMap());
  }

  /// Get password entry by ID
  Future<PasswordEntry?> getById(int id) async {
    final results = await _db.query(
      'password_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return PasswordEntry.fromMap(results.first);
  }

  /// Get all password entries for a group
  Future<List<PasswordEntry>> getByGroupId(int groupId) async {
    final results = await _db.query(
      'password_entries',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'updated_at DESC',
    );

    return results.map((map) => PasswordEntry.fromMap(map)).toList();
  }

  /// Get all password entries
  Future<List<PasswordEntry>> getAll() async {
    final results = await _db.query(
      'password_entries',
      orderBy: 'updated_at DESC',
    );

    return results.map((map) => PasswordEntry.fromMap(map)).toList();
  }

  /// Update a password entry
  Future<void> update(PasswordEntry entry) async {
    await _db.update(
      'password_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete a password entry
  Future<void> delete(int id) async {
    await _db.delete(
      'password_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search password entries by keyword
  /// Searches in title, username, url, and notes fields
  Future<List<PasswordEntry>> search(String keyword) async {
    final lowerKeyword = keyword.toLowerCase();

    final results = await _db.rawQuery('''
      SELECT * FROM password_entries
      WHERE
        LOWER(title) LIKE ? OR
        LOWER(username) LIKE ? OR
        LOWER(url) LIKE ? OR
        LOWER(notes) LIKE ?
      ORDER BY
        CASE
          WHEN LOWER(title) LIKE ? THEN 1
          WHEN LOWER(username) LIKE ? THEN 2
          ELSE 3
        END,
        updated_at DESC
      LIMIT 50
    ''', [
      '%$lowerKeyword%',
      '%$lowerKeyword%',
      '%$lowerKeyword%',
      '%$lowerKeyword%',
      '%$lowerKeyword%',
      '%$lowerKeyword%',
    ]);

    return results.map((map) => PasswordEntry.fromMap(map)).toList();
  }
}
