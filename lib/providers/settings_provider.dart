import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// Provider for app settings management
class SettingsProvider with ChangeNotifier {
  final DatabaseService _dbService;

  int _autoLockTimeout = AppConstants.defaultAutoLockTimeout;
  int _clipboardClearTimeout = AppConstants.defaultClipboardClearTimeout;
  bool _biometricEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  SettingsProvider(this._dbService);

  int get autoLockTimeout => _autoLockTimeout;
  int get clipboardClearTimeout => _clipboardClearTimeout;
  bool get biometricEnabled => _biometricEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load settings from database
  Future<void> loadSettings() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final autoLockStr = await _dbService.getSetting(AppConstants.settingAutoLockTimeout);
      if (autoLockStr != null) {
        _autoLockTimeout = int.tryParse(autoLockStr) ?? AppConstants.defaultAutoLockTimeout;
      }

      final clipboardStr = await _dbService.getSetting(AppConstants.settingClipboardClearTimeout);
      if (clipboardStr != null) {
        _clipboardClearTimeout = int.tryParse(clipboardStr) ?? AppConstants.defaultClipboardClearTimeout;
      }

      _biometricEnabled = await _dbService.getBoolSetting(AppConstants.settingBiometricEnabled) ?? false;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update auto-lock timeout
  Future<bool> setAutoLockTimeout(int seconds) async {
    try {
      _errorMessage = null;
      await _dbService.setSetting(AppConstants.settingAutoLockTimeout, seconds.toString());
      _autoLockTimeout = seconds;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update clipboard clear timeout
  Future<bool> setClipboardClearTimeout(int seconds) async {
    try {
      _errorMessage = null;
      await _dbService.setSetting(AppConstants.settingClipboardClearTimeout, seconds.toString());
      _clipboardClearTimeout = seconds;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Enable/disable biometric authentication
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      _errorMessage = null;
      await _dbService.setBoolSetting(AppConstants.settingBiometricEnabled, enabled);
      _biometricEnabled = enabled;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
