import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../services/webdav_service.dart';
import '../services/export_import_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// Provider for WebDAV backup and restore state management
class WebDavProvider extends ChangeNotifier {
  final WebDavService _webdavService;
  final ExportImportService _exportImportService;
  final DatabaseService _dbService;
  final FlutterSecureStorage _secureStorage;

  WebDavProvider(
    this._webdavService,
    this._exportImportService,
    this._dbService,
  ) : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  // WebDAV Configuration
  String? _webdavUrl;
  String? _webdavUsername;
  String? _webdavRemotePath;
  bool _webdavEnabled = false;
  DateTime? _lastBackupTime;

  // Connection status
  bool _isConnected = false;
  bool _isTestingConnection = false;
  bool _isUploading = false;
  bool _isDownloading = false;
  double _uploadProgress = 0.0;
  double _downloadProgress = 0.0;
  String? _statusMessage;

  // Available backups
  List<WebDavBackupFile> _availableBackups = [];

  // Getters
  String? get webdavUrl => _webdavUrl;
  String? get webdavUsername => _webdavUsername;
  String? get webdavRemotePath => _webdavRemotePath;
  bool get webdavEnabled => _webdavEnabled;
  DateTime? get lastBackupTime => _lastBackupTime;
  bool get isConnected => _isConnected;
  bool get isTestingConnection => _isTestingConnection;
  bool get isUploading => _isUploading;
  bool get isDownloading => _isDownloading;
  double get uploadProgress => _uploadProgress;
  double get downloadProgress => _downloadProgress;
  String? get statusMessage => _statusMessage;
  List<WebDavBackupFile> get availableBackups => _availableBackups;

  /// Load WebDAV settings from database and secure storage
  Future<void> loadSettings() async {
    try {
      // Load from database
      _webdavUrl = await _dbService.getSetting(AppConstants.settingWebdavUrl);
      _webdavRemotePath = await _dbService.getSetting(
        AppConstants.settingWebdavRemotePath,
      );
      _webdavEnabled = await _dbService.getBoolSetting(
            AppConstants.settingWebdavEnabled,
            defaultValue: false,
          ) ??
          false;

      // Load last backup timestamp
      final lastBackupStr = await _dbService.getSetting(
        AppConstants.settingWebdavLastBackup,
      );
      if (lastBackupStr != null) {
        _lastBackupTime = DateTime.tryParse(lastBackupStr);
      }

      // Load credentials from secure storage
      _webdavUsername = await _secureStorage.read(
        key: AppConstants.secureStorageWebdavUsername,
      );

      notifyListeners();
    } catch (e) {
      print('[WebDAV] Error loading settings: $e');
    }
  }

  /// Save WebDAV settings to database and secure storage
  Future<void> saveSettings({
    String? url,
    String? username,
    String? password,
    String? remotePath,
    bool? enabled,
  }) async {
    try {
      if (url != null) {
        _webdavUrl = url;
        await _dbService.setSetting(AppConstants.settingWebdavUrl, url);
      }

      if (remotePath != null) {
        _webdavRemotePath = remotePath;
        await _dbService.setSetting(
          AppConstants.settingWebdavRemotePath,
          remotePath,
        );
      }

      if (enabled != null) {
        _webdavEnabled = enabled;
        await _dbService.setBoolSetting(
          AppConstants.settingWebdavEnabled,
          enabled,
        );
      }

      // Save credentials to secure storage
      if (username != null) {
        _webdavUsername = username;
        await _secureStorage.write(
          key: AppConstants.secureStorageWebdavUsername,
          value: username,
        );
      }

      if (password != null) {
        await _secureStorage.write(
          key: AppConstants.secureStorageWebdavPassword,
          value: password,
        );
      }

      notifyListeners();
    } catch (e) {
      throw Exception('保存设置失败: $e');
    }
  }

  /// Test WebDAV connection
  Future<bool> testConnection({
    String? url,
    String? username,
    String? password,
    String? remotePath,
  }) async {
    _isTestingConnection = true;
    _statusMessage = '正在测试连接...';
    notifyListeners();

    try {
      // Use provided values or stored values
      final testUrl = url ?? _webdavUrl;
      final testUsername = username ?? _webdavUsername;
      final testPassword = password ??
          await _secureStorage.read(
            key: AppConstants.secureStorageWebdavPassword,
          );
      final testRemotePath = remotePath ?? _webdavRemotePath;

      if (testUrl == null || testUrl.isEmpty) {
        throw Exception('服务器URL不能为空');
      }
      if (testUsername == null || testUsername.isEmpty) {
        throw Exception('用户名不能为空');
      }
      if (testPassword == null || testPassword.isEmpty) {
        throw Exception('密码不能为空');
      }

      // Test connection
      await _webdavService.testConnection(
        testUrl,
        testUsername,
        testPassword,
        remotePath: testRemotePath,
      );

      _isConnected = true;
      _statusMessage = '连接成功！';
      return true;
    } catch (e) {
      _isConnected = false;
      _statusMessage = '连接失败: ${e.toString()}';
      return false;
    } finally {
      _isTestingConnection = false;
      notifyListeners();
    }
  }

  /// Connect to WebDAV server with stored credentials
  Future<void> connect() async {
    try {
      final url = _webdavUrl;
      final username = _webdavUsername;
      final password = await _secureStorage.read(
        key: AppConstants.secureStorageWebdavPassword,
      );
      final remotePath = _webdavRemotePath;

      if (url == null || username == null || password == null) {
        throw Exception('WebDAV配置不完整');
      }

      await _webdavService.connect(
        url,
        username,
        password,
        remotePath: remotePath,
      );

      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      throw Exception('连接失败: $e');
    }
  }

  /// Backup to WebDAV
  Future<void> backupToWebDAV(String password) async {
    if (!_webdavEnabled) {
      throw Exception('WebDAV备份未启用');
    }

    _isUploading = true;
    _uploadProgress = 0.0;
    _statusMessage = '正在创建备份...';
    notifyListeners();

    String? tempFilePath;

    try {
      // Ensure connected
      if (!_webdavService.isConnected) {
        await connect();
      }

      // Create temporary backup file
      _statusMessage = '正在加密数据...';
      notifyListeners();

      tempFilePath = await _exportImportService.createTempBackup(password);

      // Upload to WebDAV
      _statusMessage = '正在上传到WebDAV...';
      notifyListeners();

      final fileName = tempFilePath.split('/').last;

      await _webdavService.uploadBackup(
        tempFilePath,
        fileName,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      // Update last backup time
      _lastBackupTime = DateTime.now();
      await _dbService.setSetting(
        AppConstants.settingWebdavLastBackup,
        _lastBackupTime!.toIso8601String(),
      );

      _statusMessage = '备份成功！';
    } catch (e) {
      _statusMessage = '备份失败: ${e.toString()}';
      rethrow;
    } finally {
      // Clean up temp file
      if (tempFilePath != null) {
        try {
          await File(tempFilePath).delete();
        } catch (e) {
          print('[WebDAV] Failed to delete temp file: $e');
        }
      }

      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  /// Restore from WebDAV
  Future<void> restoreFromWebDAV(
    String remoteFileName,
    String password, {
    bool overwrite = false,
  }) async {
    if (!_webdavEnabled) {
      throw Exception('WebDAV备份未启用');
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    _statusMessage = '正在下载备份...';
    notifyListeners();

    String? localFilePath;

    try {
      // Ensure connected
      if (!_webdavService.isConnected) {
        await connect();
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();

      // Download from WebDAV
      localFilePath = await _webdavService.downloadBackup(
        remoteFileName,
        tempDir.path,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      // Import data
      _statusMessage = '正在导入数据...';
      notifyListeners();

      await _exportImportService.restoreFromFile(
        localFilePath,
        password,
        overwrite: overwrite,
      );

      _statusMessage = '恢复成功！';
    } catch (e) {
      _statusMessage = '恢复失败: ${e.toString()}';
      rethrow;
    } finally {
      // Clean up downloaded file
      if (localFilePath != null) {
        try {
          await File(localFilePath).delete();
        } catch (e) {
          print('[WebDAV] Failed to delete downloaded file: $e');
        }
      }

      _isDownloading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }

  /// List available backups on WebDAV server
  Future<void> loadAvailableBackups() async {
    try {
      // Ensure connected
      if (!_webdavService.isConnected) {
        await connect();
      }

      _availableBackups = await _webdavService.listBackups();
      notifyListeners();
    } catch (e) {
      print('[WebDAV] Failed to load backups: $e');
      _availableBackups = [];
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a backup from WebDAV server
  Future<void> deleteBackup(String remoteFileName) async {
    try {
      // Ensure connected
      if (!_webdavService.isConnected) {
        await connect();
      }

      await _webdavService.deleteBackup(remoteFileName);

      // Reload backup list
      await loadAvailableBackups();
    } catch (e) {
      throw Exception('删除备份失败: $e');
    }
  }

  /// Clear status message
  void clearStatus() {
    _statusMessage = null;
    notifyListeners();
  }

  /// Disconnect from WebDAV
  void disconnect() {
    _webdavService.disconnect();
    _isConnected = false;
    notifyListeners();
  }
}
