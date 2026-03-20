import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../services/group_service.dart';

/// Provider for group management
class GroupProvider with ChangeNotifier {
  final GroupService _groupService;

  List<Group> _groups = [];
  Group? _selectedGroup;
  bool _isLoading = false;
  String? _errorMessage;

  GroupProvider(this._groupService);

  List<Group> get groups => _groups;
  Group? get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all groups
  Future<void> loadGroups() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _groups = await _groupService.getAll();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new group
  Future<bool> createGroup(Group group) async {
    try {
      _errorMessage = null;
      await _groupService.create(group);
      await loadGroups();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a group
  Future<bool> updateGroup(Group group) async {
    try {
      _errorMessage = null;
      await _groupService.update(group);
      await loadGroups();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a group
  Future<bool> deleteGroup(int id) async {
    try {
      _errorMessage = null;
      await _groupService.delete(id);
      await loadGroups();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Select a group
  void selectGroup(Group? group) {
    _selectedGroup = group;
    notifyListeners();
  }

  /// Get password count for a group
  Future<int> getPasswordCount(int groupId) async {
    try {
      return await _groupService.getPasswordCount(groupId);
    } catch (e) {
      return 0;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
