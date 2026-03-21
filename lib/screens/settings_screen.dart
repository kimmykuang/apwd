import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
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
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await context.read<SettingsProvider>().loadSettings();
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
