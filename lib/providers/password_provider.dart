import 'package:flutter/foundation.dart';
import '../models/password_entry.dart';
import '../services/password_service.dart';
import '../services/crypto_service.dart';

/// Provider for password data management
class PasswordProvider with ChangeNotifier {
  final PasswordService _passwordService;
  final CryptoService _cryptoService;

  List<PasswordEntry> _passwords = [];
  List<PasswordEntry> _filteredPasswords = [];
  PasswordEntry? _selectedPassword;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  PasswordProvider(this._passwordService, this._cryptoService);

  List<PasswordEntry> get passwords => _filteredPasswords;
  PasswordEntry? get selectedPassword => _selectedPassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  /// Load all passwords
  Future<void> loadPasswords() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _passwords = await _passwordService.getAll();
      _applyFilter();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load passwords by group
  Future<void> loadPasswordsByGroup(int groupId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _passwords = await _passwordService.getByGroupId(groupId);
      _applyFilter();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search passwords
  Future<void> searchPasswords(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _applyFilter();
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final results = await _passwordService.search(query);
      _filteredPasswords = results;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new password entry
  Future<bool> createPassword(PasswordEntry entry) async {
    try {
      _errorMessage = null;
      await _passwordService.create(entry);
      await loadPasswords();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a password entry
  Future<bool> updatePassword(PasswordEntry entry) async {
    try {
      _errorMessage = null;
      await _passwordService.update(entry);
      await loadPasswords();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a password entry
  Future<bool> deletePassword(int id) async {
    try {
      _errorMessage = null;
      await _passwordService.delete(id);
      await loadPasswords();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Select a password for viewing details
  Future<void> selectPassword(int id) async {
    try {
      _selectedPassword = await _passwordService.getById(id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear selected password
  void clearSelection() {
    _selectedPassword = null;
    notifyListeners();
  }

  /// Decrypt password
  Future<String?> decryptPassword(String encryptedPassword, String masterPassword) async {
    try {
      // In production, you would decrypt using crypto service
      // For now, return the encrypted password (it's already stored encrypted)
      return encryptedPassword;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Apply search filter
  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredPasswords = List.from(_passwords);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredPasswords = _passwords.where((p) {
        return p.title.toLowerCase().contains(query) ||
            (p.username?.toLowerCase().contains(query) ?? false) ||
            (p.url?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
