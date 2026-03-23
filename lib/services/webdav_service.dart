import 'dart:io';
import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

/// Service for WebDAV backup and restore operations
class WebDavService {
  webdav.Client? _client;
  String? _url;
  String? _username;
  String? _password;
  String? _remotePath;

  bool get isConnected => _client != null;

  /// Test WebDAV connection without storing credentials
  Future<bool> testConnection(
    String url,
    String username,
    String password, {
    String? remotePath,
  }) async {
    try {
      // Normalize URL
      url = _normalizeUrl(url);

      // Create temporary client
      final client = webdav.newClient(
        url,
        user: username,
        password: password,
        debug: false,
      );

      // Test connection with ping
      await client.ping();

      // If remote path specified, check if it exists or can be created
      if (remotePath != null && remotePath.isNotEmpty) {
        remotePath = _normalizeRemotePath(remotePath);
        try {
          // Try to list contents (checks read permission and existence)
          await client.readDir(remotePath);
        } catch (e) {
          // If path doesn't exist, try to create it
          try {
            await client.mkdir(remotePath);
          } catch (createError) {
            throw WebDavException(
              'Cannot access or create remote path: $remotePath',
              WebDavErrorType.pathError,
            );
          }
        }
      }

      return true;
    } on SocketException {
      throw WebDavException(
        '无法连接到WebDAV服务器。请检查网络连接。',
        WebDavErrorType.networkError,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw WebDavException(
          '用户名或密码错误',
          WebDavErrorType.authError,
        );
      }
      throw WebDavException(
        'WebDAV服务器错误: ${e.message}',
        WebDavErrorType.serverError,
      );
    } catch (e) {
      throw WebDavException(
        '连接测试失败: $e',
        WebDavErrorType.unknownError,
      );
    }
  }

  /// Connect to WebDAV server and store credentials
  Future<void> connect(
    String url,
    String username,
    String password, {
    String? remotePath,
  }) async {
    // Test connection first
    await testConnection(url, username, password, remotePath: remotePath);

    // Store credentials and create client
    _url = _normalizeUrl(url);
    _username = username;
    _password = password;
    _remotePath = remotePath != null ? _normalizeRemotePath(remotePath) : '/';

    _client = webdav.newClient(
      _url!,
      user: _username!,
      password: _password!,
      debug: false,
    );
  }

  /// Disconnect from WebDAV server
  void disconnect() {
    _client = null;
    _url = null;
    _username = null;
    _password = null;
    _remotePath = null;
  }

  /// Upload backup file to WebDAV server
  Future<void> uploadBackup(
    String localFilePath,
    String remoteFileName, {
    void Function(double progress)? onProgress,
  }) async {
    _ensureConnected();

    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        throw WebDavException(
          '本地文件不存在: $localFilePath',
          WebDavErrorType.fileError,
        );
      }

      final bytes = await file.readAsBytes();
      final remotePath = _getRemoteFilePath(remoteFileName);

      // Upload with progress tracking
      await _client!.write(
        remotePath,
        bytes,
        onProgress: onProgress != null
            ? (count, total) {
                if (total > 0) {
                  onProgress(count / total);
                }
              }
            : null,
      );
    } on SocketException {
      throw WebDavException(
        '网络连接失败，上传中断',
        WebDavErrorType.networkError,
      );
    } on DioException catch (e) {
      throw WebDavException(
        '上传失败: ${e.message}',
        WebDavErrorType.uploadError,
      );
    } catch (e) {
      throw WebDavException(
        '上传失败: $e',
        WebDavErrorType.unknownError,
      );
    }
  }

  /// Download backup file from WebDAV server
  Future<String> downloadBackup(
    String remoteFileName,
    String localDirectory, {
    void Function(double progress)? onProgress,
  }) async {
    _ensureConnected();

    try {
      final remotePath = _getRemoteFilePath(remoteFileName);

      // Download with progress tracking
      final bytes = await _client!.read(
        remotePath,
        onProgress: onProgress != null
            ? (count, total) {
                if (total > 0) {
                  onProgress(count / total);
                }
              }
            : null,
      );

      // Save to local file
      final localFile = File('$localDirectory/$remoteFileName');
      await localFile.parent.create(recursive: true);
      await localFile.writeAsBytes(bytes);

      return localFile.path;
    } on SocketException {
      throw WebDavException(
        '网络连接失败，下载中断',
        WebDavErrorType.networkError,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw WebDavException(
          '远程备份文件不存在: $remoteFileName',
          WebDavErrorType.fileNotFoundError,
        );
      }
      throw WebDavException(
        '下载失败: ${e.message}',
        WebDavErrorType.downloadError,
      );
    } catch (e) {
      throw WebDavException(
        '下载失败: $e',
        WebDavErrorType.unknownError,
      );
    }
  }

  /// List all backup files in WebDAV remote path
  Future<List<WebDavBackupFile>> listBackups() async {
    _ensureConnected();

    try {
      final files = await _client!.readDir(_remotePath!);

      final backupFiles = <WebDavBackupFile>[];
      for (final file in files) {
        // Only include .apwd files
        if (file.name?.endsWith('.apwd') ?? false) {
          backupFiles.add(WebDavBackupFile(
            name: file.name!,
            size: file.size ?? 0,
            modifiedTime: file.mTime,
            path: file.path ?? '',
          ));
        }
      }

      // Sort by modification time (newest first)
      backupFiles.sort((a, b) {
        if (a.modifiedTime == null && b.modifiedTime == null) return 0;
        if (a.modifiedTime == null) return 1;
        if (b.modifiedTime == null) return -1;
        return b.modifiedTime!.compareTo(a.modifiedTime!);
      });

      return backupFiles;
    } on SocketException {
      throw WebDavException(
        '网络连接失败',
        WebDavErrorType.networkError,
      );
    } on DioException catch (e) {
      throw WebDavException(
        '无法列出备份文件: ${e.message}',
        WebDavErrorType.serverError,
      );
    } catch (e) {
      throw WebDavException(
        '列出备份文件失败: $e',
        WebDavErrorType.unknownError,
      );
    }
  }

  /// Delete a backup file from WebDAV server
  Future<void> deleteBackup(String remoteFileName) async {
    _ensureConnected();

    try {
      final remotePath = _getRemoteFilePath(remoteFileName);
      await _client!.remove(remotePath);
    } on SocketException {
      throw WebDavException(
        '网络连接失败',
        WebDavErrorType.networkError,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw WebDavException(
          '文件不存在: $remoteFileName',
          WebDavErrorType.fileNotFoundError,
        );
      }
      throw WebDavException(
        '删除失败: ${e.message}',
        WebDavErrorType.serverError,
      );
    } catch (e) {
      throw WebDavException(
        '删除失败: $e',
        WebDavErrorType.unknownError,
      );
    }
  }

  // Helper methods

  void _ensureConnected() {
    if (_client == null) {
      throw WebDavException(
        '未连接到WebDAV服务器',
        WebDavErrorType.notConnectedError,
      );
    }
  }

  String _normalizeUrl(String url) {
    // Ensure URL ends with /
    if (!url.endsWith('/')) {
      url = '$url/';
    }
    // Ensure URL uses https (security best practice)
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  String _normalizeRemotePath(String path) {
    // Ensure path starts with /
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    // Ensure path ends with /
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    return path;
  }

  String _getRemoteFilePath(String fileName) {
    return '$_remotePath$fileName';
  }
}

/// Represents a backup file on WebDAV server
class WebDavBackupFile {
  final String name;
  final int size;
  final DateTime? modifiedTime;
  final String path;

  WebDavBackupFile({
    required this.name,
    required this.size,
    this.modifiedTime,
    required this.path,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// WebDAV exception with error type
class WebDavException implements Exception {
  final String message;
  final WebDavErrorType type;

  WebDavException(this.message, this.type);

  @override
  String toString() => message;
}

/// Types of WebDAV errors
enum WebDavErrorType {
  networkError,
  authError,
  serverError,
  fileError,
  fileNotFoundError,
  uploadError,
  downloadError,
  pathError,
  notConnectedError,
  unknownError,
}
