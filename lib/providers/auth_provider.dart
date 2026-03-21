import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Provider for authentication state management
class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  bool _isUnlocked = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AuthProvider(this._authService);

  bool get isUnlocked => _isUnlocked;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  AuthService get authService => _authService;

  /// Setup master password for first time use
  Future<bool> setupMasterPassword(String dbPath, String masterPassword) async {
    try {
      _errorMessage = null;
      await _authService.setupMasterPassword(dbPath, masterPassword);
      _isUnlocked = true;
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unlock the application with master password
  Future<bool> unlock(String dbPath, String masterPassword) async {
    try {
      _errorMessage = null;
      final success = await _authService.unlock(dbPath, masterPassword);
      if (success) {
        _isUnlocked = true;
        notifyListeners();
      } else {
        _errorMessage = 'Invalid password';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Lock the application
  Future<void> lock() async {
    await _authService.lock();
    _isUnlocked = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set initialized state (when database already exists)
  void setInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
