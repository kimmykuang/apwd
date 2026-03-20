/// Application settings model
class AppSettings {
  final int autoLockTimeout; // seconds
  final bool biometricEnabled;
  final int clipboardClearTimeout; // seconds

  const AppSettings({
    this.autoLockTimeout = 300, // 5 minutes default
    this.biometricEnabled = false,
    this.clipboardClearTimeout = 30, // 30 seconds default
  });

  /// Converts the AppSettings to a Map for database storage.
  ///
  /// Uses snake_case keys to match database column names.
  Map<String, dynamic> toMap() {
    return {
      'auto_lock_timeout': autoLockTimeout,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'clipboard_clear_timeout': clipboardClearTimeout,
    };
  }

  /// Creates an AppSettings from a Map (typically from database query).
  ///
  /// Expects snake_case keys matching database column names.
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      autoLockTimeout: map['auto_lock_timeout'] as int? ?? 300,
      biometricEnabled: (map['biometric_enabled'] as int? ?? 0) == 1,
      clipboardClearTimeout: map['clipboard_clear_timeout'] as int? ?? 30,
    );
  }

  AppSettings copyWith({
    int? autoLockTimeout,
    bool? biometricEnabled,
    int? clipboardClearTimeout,
  }) {
    return AppSettings(
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      clipboardClearTimeout: clipboardClearTimeout ?? this.clipboardClearTimeout,
    );
  }

  @override
  String toString() {
    return 'AppSettings{autoLockTimeout: $autoLockTimeout, biometricEnabled: $biometricEnabled, clipboardClearTimeout: $clipboardClearTimeout}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.autoLockTimeout == autoLockTimeout &&
        other.biometricEnabled == biometricEnabled &&
        other.clipboardClearTimeout == clipboardClearTimeout;
  }

  @override
  int get hashCode {
    return Object.hash(autoLockTimeout, biometricEnabled, clipboardClearTimeout);
  }
}
