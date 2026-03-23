import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/webdav_provider.dart';
import '../utils/constants.dart';
import '../main.dart' show navigatorKey;

/// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load settings after the first frame to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    await context.read<SettingsProvider>().loadSettings();
    await context.read<WebDavProvider>().loadSettings();
  }

  Future<void> _showEnableBiometricDialog(BuildContext context) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enable Biometric Authentication'),
        content: const Text(
          'You will need to verify your fingerprint and enter your master password to enable this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Now execute the enable flow in a new context
    await _enableBiometric(context);
  }

  Future<void> _showDisableBiometricDialog(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disable Biometric Authentication'),
        content: const Text(
          'Are you sure you want to disable biometric authentication?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Disable'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _disableBiometric(context);
  }

  Future<void> _enableBiometric(BuildContext context) async {
    // Get providers at the beginning
    final authProvider = context.read<AuthProvider>();
    final authService = authProvider.authService;

    // Step 1: Check if biometric is available
    final canAuth = await authService.checkBiometric();
    if (!canAuth) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication is not available on this device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Step 2: Verify biometric
    final authenticated = await authService.authenticateWithBiometric();
    if (!mounted) return;

    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Step 3: Ask for master password
    if (!mounted) return;
    final passwordController = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Master Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'To enable biometric authentication, please enter your master password.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Master Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(passwordController.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    final password = confirmed;
    passwordController.dispose();

    if (password == null || password.isEmpty || !mounted) return;

    // Step 4: Store password IMMEDIATELY without verification
    // The password will be verified when actually unlocking
    try {
      print('[SETTINGS] Storing biometric password...');
      await authService.storeBiometricPassword(password);
      print('[SETTINGS] Password stored successfully');

      await authService.setBiometricEnabled(true);
      print('[SETTINGS] Biometric enabled');

      if (!mounted) return;

      // Navigate to home using global navigator key (avoids Provider context issues)
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);

      // Show success message
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication enabled. Lock and unlock to test.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('[SETTINGS] Error enabling biometric: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enable biometric: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disableBiometric(BuildContext context) async {
    // Get providers at the beginning
    final authProvider = context.read<AuthProvider>();
    final authService = authProvider.authService;

    // Delete stored password
    await authService.deleteBiometricPassword();
    await authService.setBiometricEnabled(false);

    if (!mounted) return;

    // Navigate to home to break widget tree dependency (use global navigator key)
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);

    // Show success message
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication disabled'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              const _SectionHeader('Security'),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Auto-lock Timeout'),
                subtitle: Text('${provider.autoLockTimeout} seconds'),
                onTap: () => _showAutoLockDialog(provider),
              ),
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('Clipboard Clear Timeout'),
                subtitle: Text('${provider.clipboardClearTimeout} seconds'),
                onTap: () => _showClipboardDialog(provider),
              ),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Biometric Authentication'),
                subtitle: Text(
                  provider.biometricEnabled
                    ? 'Enabled - Tap to disable'
                    : 'Disabled - Tap to enable'
                ),
                trailing: provider.biometricEnabled
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () {
                  if (provider.biometricEnabled) {
                    // Disable
                    _showDisableBiometricDialog(context);
                  } else {
                    // Enable
                    _showEnableBiometricDialog(context);
                  }
                },
              ),
              const Divider(),
              const _SectionHeader('WebDAV Backup'),
              Consumer<WebDavProvider>(
                builder: (context, webdavProvider, _) {
                  return Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.cloud_sync),
                        title: const Text('Enable WebDAV Sync'),
                        subtitle: Text(
                          webdavProvider.webdavEnabled
                              ? 'Enabled'
                              : 'Disabled',
                        ),
                        value: webdavProvider.webdavEnabled,
                        onChanged: (value) async {
                          if (value) {
                            // Show configuration dialog when enabling
                            await _showWebDavConfigDialog(webdavProvider);
                          } else {
                            // Disable directly
                            await webdavProvider.saveSettings(enabled: false);
                          }
                        },
                      ),
                      if (webdavProvider.webdavEnabled) ...[
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('WebDAV Settings'),
                          subtitle: Text(webdavProvider.webdavUrl ?? 'Not configured'),
                          onTap: () => _showWebDavConfigDialog(webdavProvider),
                        ),
                        if (webdavProvider.lastBackupTime != null)
                          ListTile(
                            leading: const Icon(Icons.access_time),
                            title: const Text('Last Backup'),
                            subtitle: Text(
                              _formatDateTime(webdavProvider.lastBackupTime!),
                            ),
                          ),
                        ListTile(
                          leading: const Icon(Icons.backup),
                          title: const Text('Backup to WebDAV'),
                          subtitle: const Text('Upload encrypted backup to server'),
                          trailing: webdavProvider.isUploading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value: webdavProvider.uploadProgress,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload),
                          onTap: webdavProvider.isUploading
                              ? null
                              : () => _showBackupDialog(webdavProvider),
                        ),
                        ListTile(
                          leading: const Icon(Icons.restore),
                          title: const Text('Restore from WebDAV'),
                          subtitle: const Text('Download and restore backup'),
                          trailing: webdavProvider.isDownloading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value: webdavProvider.downloadProgress,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_download),
                          onTap: webdavProvider.isDownloading
                              ? null
                              : () => _showRestoreDialog(webdavProvider),
                        ),
                      ],
                      if (webdavProvider.statusMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            webdavProvider.statusMessage!,
                            style: TextStyle(
                              color: webdavProvider.statusMessage!.contains('成功')
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Divider(),
              const _SectionHeader('About'),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: const Text('0.1.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('License'),
                subtitle: const Text('MIT License'),
              ),
              const Divider(),
              const _SectionHeader('Account'),
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Change Master Password'),
                subtitle: const Text('Update your master password'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Lock App', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await context.read<AuthProvider>().lock();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/lock',
                    (route) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAutoLockDialog(SettingsProvider provider) async {
    final options = [60, 300, 600, 1800, 3600]; // 1min, 5min, 10min, 30min, 1hr
    final labels = ['1 minute', '5 minutes', '10 minutes', '30 minutes', '1 hour'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-lock Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(options.length, (index) {
            return RadioListTile<int>(
              title: Text(labels[index]),
              value: options[index],
              groupValue: provider.autoLockTimeout,
              onChanged: (value) {
                if (value != null) {
                  provider.setAutoLockTimeout(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClipboardDialog(SettingsProvider provider) async {
    final options = [10, 30, 60, 120]; // 10s, 30s, 1min, 2min
    final labels = ['10 seconds', '30 seconds', '1 minute', '2 minutes'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clipboard Clear Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(options.length, (index) {
            return RadioListTile<int>(
              title: Text(labels[index]),
              value: options[index],
              groupValue: provider.clipboardClearTimeout,
              onChanged: (value) {
                if (value != null) {
                  provider.setClipboardClearTimeout(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showWebDavConfigDialog(WebDavProvider webdavProvider) async {
    final urlController = TextEditingController(
      text: webdavProvider.webdavUrl ?? '',
    );
    final usernameController = TextEditingController(
      text: webdavProvider.webdavUsername ?? '',
    );
    final passwordController = TextEditingController();
    final remotePathController = TextEditingController(
      text: webdavProvider.webdavRemotePath ?? '/APWD',
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('WebDAV Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'https://cloud.example.com/remote.php/dav',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: remotePathController,
                  decoration: const InputDecoration(
                    labelText: 'Remote Path',
                    hintText: '/APWD',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Test connection first
                final url = urlController.text.trim();
                final username = usernameController.text.trim();
                final password = passwordController.text;
                final remotePath = remotePathController.text.trim();

                if (url.isEmpty || username.isEmpty || password.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                // Show testing indicator
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final success = await webdavProvider.testConnection(
                    url: url,
                    username: username,
                    password: password,
                    remotePath: remotePath.isEmpty ? null : remotePath,
                  );

                  // Close loading dialog
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  if (success) {
                    // Save settings
                    await webdavProvider.saveSettings(
                      url: url,
                      username: username,
                      password: password,
                      remotePath: remotePath.isEmpty ? null : remotePath,
                      enabled: true,
                    );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(true);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('WebDAV configured successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Close loading dialog
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connection failed: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Test & Save'),
            ),
          ],
        ),
      );
    } finally {
      // Dispose controllers after dialog is fully closed
      urlController.dispose();
      usernameController.dispose();
      passwordController.dispose();
      remotePathController.dispose();
    }
  }

  Future<void> _showBackupDialog(WebDavProvider webdavProvider) async {
    final passwordController = TextEditingController();

    try {
      final confirmed = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Backup to WebDAV'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a password to encrypt your backup. This can be different from your master password.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Backup Password',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Important: Store this password safely. You will need it to restore your backup.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                passwordController.text,
              ),
              child: const Text('Backup'),
            ),
          ],
        ),
      );

      if (confirmed == null || confirmed.isEmpty || !mounted) return;

      try {
        await webdavProvider.backupToWebDAV(confirmed);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _showRestoreDialog(WebDavProvider webdavProvider) async {
    try {
      // Load available backups
      await webdavProvider.loadAvailableBackups();

      if (!mounted) return;

      final backups = webdavProvider.availableBackups;

      if (backups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backups found on WebDAV server'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show backup selection dialog
      final selectedBackup = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Select Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index];
                return ListTile(
                  title: Text(backup.name),
                  subtitle: Text(
                    '${backup.formattedSize} • ${backup.modifiedTime != null ? _formatDateTime(backup.modifiedTime!) : "Unknown date"}',
                  ),
                  onTap: () => Navigator.of(dialogContext).pop(backup.name),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedBackup == null || !mounted) return;

      // Show restore options dialog
      final passwordController = TextEditingController();

      try {
        bool overwrite = false;

        final confirmed = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Restore from Backup'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('File: $selectedBackup'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Backup Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Import Mode:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Skip existing entries'),
                    subtitle: const Text('Keep current data for duplicates'),
                    value: false,
                    groupValue: overwrite,
                    onChanged: (value) {
                      setState(() => overwrite = value ?? false);
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('Overwrite existing entries'),
                    subtitle: const Text('Replace current data with backup'),
                    value: true,
                    groupValue: overwrite,
                    onChanged: (value) {
                      setState(() => overwrite = value ?? false);
                    },
                  ),
                  if (overwrite)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '⚠️ Warning: Existing passwords will be replaced',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop({
                    'password': passwordController.text,
                    'overwrite': overwrite,
                  }),
                  child: const Text('Restore'),
                ),
              ],
            ),
          ),
        );

        if (confirmed == null || !mounted) return;

        final password = confirmed['password'] as String;
        final shouldOverwrite = confirmed['overwrite'] as bool;

        if (password.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password is required'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Perform restore
        await webdavProvider.restoreFromWebDAV(
          selectedBackup,
          password,
          overwrite: shouldOverwrite,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restore completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } finally {
        passwordController.dispose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
