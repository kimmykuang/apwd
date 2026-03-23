/// Application-wide constants
class AppConstants {
  // Crypto
  static const int pbkdf2Iterations = 100000;
  static const int saltLength = 32;
  static const int keyLength = 64; // 512 bits

  // Security
  static const int defaultAutoLockTimeout = 300; // 5 minutes in seconds
  static const int defaultClipboardClearTimeout = 30; // 30 seconds
  static const int maxFailedAttempts = 5;
  static const int lockoutDuration = 30; // 30 seconds

  // Password Generator
  static const int defaultPasswordLength = 16;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;

  // Database
  static const String dbName = 'apwd.db';
  static const int dbVersion = 1;

  // Settings Keys
  static const String settingAutoLockTimeout = 'auto_lock_timeout';
  static const String settingBiometricEnabled = 'biometric_enabled';
  static const String settingMasterPasswordHash = 'master_password_hash';
  static const String settingPasswordSalt = 'password_salt';
  static const String settingClipboardClearTimeout = 'clipboard_clear_timeout';
  static const String settingFirstLaunchCompleted = 'first_launch_completed';

  // WebDAV Settings Keys
  static const String settingWebdavUrl = 'webdav_url';
  static const String settingWebdavRemotePath = 'webdav_remote_path';
  static const String settingWebdavEnabled = 'webdav_enabled';
  static const String settingWebdavLastBackup = 'webdav_last_backup';

  // Export/Import
  static const String exportFileExtension = '.apwd';
  static const String exportFormatVersion = '1.0';

  // Secure Storage Keys
  static const String secureStorageDbKey = 'db_key';
  static const String secureStorageWebdavUsername = 'webdav_username';
  static const String secureStorageWebdavPassword = 'webdav_password';
}
