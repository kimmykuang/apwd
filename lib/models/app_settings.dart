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
}
