import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

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
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Biometric Authentication'),
                subtitle: const Text('Use fingerprint or face ID'),
                value: provider.biometricEnabled,
                onChanged: (value) {
                  provider.setBiometricEnabled(value);
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
                onTap: () {
                  context.read<AuthProvider>().lock();
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
