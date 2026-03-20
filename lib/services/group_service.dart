import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/group.dart';
import 'database_service.dart';

/// Service for group operations
class GroupService {
  final DatabaseService _dbService;

  GroupService(this._dbService);

  Database get _db {
    if (_dbService.database == null) {
      throw StateError('Database not initialized');
    }
    return _dbService.database!;
  }

  /// Create a new group
  Future<int> create(Group group) async {
    return await _db.insert('groups', group.toMap());
  }

  /// Get group by ID
  Future<Group?> getById(int id) async {
    final results = await _db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Group.fromMap(results.first);
  }

  /// Get all groups ordered by sort order
  Future<List<Group>> getAll() async {
    final results = await _db.query(
      'groups',
      orderBy: 'sort_order ASC, name ASC',
    );

    return results.map((map) => Group.fromMap(map)).toList();
  }

  /// Update a group
  Future<void> update(Group group) async {
    await _db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  /// Delete a group
  Future<void> delete(int id) async {
    await _db.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of passwords in a group
  Future<int> getPasswordCount(int groupId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM password_entries WHERE group_id = ?',
      [groupId],
    );

    return (result.first['count'] as int?) ?? 0;
  }
}
