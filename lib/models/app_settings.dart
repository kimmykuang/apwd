/// Represents application settings in the database.
///
/// Stores configuration for the password manager including security settings,
/// authentication configuration, and user preferences.
class AppSettings {
  /// Unique identifier (always 1 in practice, only one settings row)
  final int? id;

  /// Seconds before auto-lock (default: 300 seconds = 5 minutes)
  final int autoLockTimeout;

  /// Whether biometric authentication is enabled (default: false)
  final bool biometricEnabled;

  /// Hash of the master password (used for authentication)
  final String? masterPasswordHash;

  /// Salt for PBKDF2 key derivation
  final String? passwordSalt;

  /// Seconds before clipboard clears (default: 30 seconds)
  final int clipboardClearTimeout;

  /// Whether initial setup is completed (default: false)
  final bool firstLaunchCompleted;

  /// Timestamp when the settings were created
  final DateTime createdAt;

  /// Timestamp when the settings were last updated
  final DateTime updatedAt;

  /// Creates a new AppSettings instance.
  ///
  /// [id] is optional and typically always 1 (single settings row).
  /// [autoLockTimeout] defaults to 300 seconds (5 minutes).
  /// [biometricEnabled] defaults to false.
  /// [clipboardClearTimeout] defaults to 30 seconds.
  /// [firstLaunchCompleted] defaults to false.
  const AppSettings({
    this.id,
    this.autoLockTimeout = 300,
    this.biometricEnabled = false,
    this.masterPasswordHash,
    this.passwordSalt,
    this.clipboardClearTimeout = 30,
    this.firstLaunchCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converts the AppSettings to a Map for database storage.
  ///
  /// Uses snake_case keys to match database column names.
  /// Booleans are stored as integers (0 = false, 1 = true) for SQLite compatibility.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auto_lock_timeout': autoLockTimeout,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'master_password_hash': masterPasswordHash,
      'password_salt': passwordSalt,
      'clipboard_clear_timeout': clipboardClearTimeout,
      'first_launch_completed': firstLaunchCompleted ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Creates an AppSettings from a Map (typically from database query).
  ///
  /// Expects snake_case keys matching database column names.
  /// Converts integer values to booleans (0 = false, non-zero = true).
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as int?,
      autoLockTimeout: map['auto_lock_timeout'] as int? ?? 300,
      biometricEnabled: (map['biometric_enabled'] as int? ?? 0) != 0,
      masterPasswordHash: map['master_password_hash'] as String?,
      passwordSalt: map['password_salt'] as String?,
      clipboardClearTimeout: map['clipboard_clear_timeout'] as int? ?? 30,
      firstLaunchCompleted: (map['first_launch_completed'] as int? ?? 0) != 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Creates a copy of this AppSettings with the specified fields replaced.
  ///
  /// This enables immutable updates to AppSettings instances.
  AppSettings copyWith({
    int? id,
    int? autoLockTimeout,
    bool? biometricEnabled,
    String? masterPasswordHash,
    String? passwordSalt,
    int? clipboardClearTimeout,
    bool? firstLaunchCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      masterPasswordHash: masterPasswordHash ?? this.masterPasswordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      clipboardClearTimeout: clipboardClearTimeout ?? this.clipboardClearTimeout,
      firstLaunchCompleted: firstLaunchCompleted ?? this.firstLaunchCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AppSettings{id: $id, autoLockTimeout: $autoLockTimeout, biometricEnabled: $biometricEnabled, clipboardClearTimeout: $clipboardClearTimeout, firstLaunchCompleted: $firstLaunchCompleted}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.id == id &&
        other.autoLockTimeout == autoLockTimeout &&
        other.biometricEnabled == biometricEnabled &&
        other.masterPasswordHash == masterPasswordHash &&
        other.passwordSalt == passwordSalt &&
        other.clipboardClearTimeout == clipboardClearTimeout &&
        other.firstLaunchCompleted == firstLaunchCompleted &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      autoLockTimeout,
      biometricEnabled,
      masterPasswordHash,
      passwordSalt,
      clipboardClearTimeout,
      firstLaunchCompleted,
      createdAt,
      updatedAt,
    );
  }
}
