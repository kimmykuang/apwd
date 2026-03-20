import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/password_provider.dart';

/// Screen showing password details
class PasswordDetailScreen extends StatefulWidget {
  final int passwordId;

  const PasswordDetailScreen({super.key, required this.passwordId});

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    await context.read<PasswordProvider>().selectPassword(widget.passwordId);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  Future<void> _deletePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password'),
        content: const Text('Are you sure you want to delete this password?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<PasswordProvider>().deletePassword(widget.passwordId);
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/password-edit',
                arguments: widget.passwordId,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deletePassword,
          ),
        ],
      ),
      body: Consumer<PasswordProvider>(
        builder: (context, provider, child) {
          final password = provider.selectedPassword;

          if (password == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailField(
                        'Title',
                        password.title,
                        Icons.title,
                        onCopy: () => _copyToClipboard(password.title, 'Title'),
                      ),
                      if (password.username != null) ...[
                        const Divider(height: 32),
                        _buildDetailField(
                          'Username',
                          password.username!,
                          Icons.person,
                          onCopy: () => _copyToClipboard(password.username!, 'Username'),
                        ),
                      ],
                      const Divider(height: 32),
                      _buildDetailField(
                        'Password',
                        _showPassword ? password.password : '••••••••',
                        Icons.lock,
                        onCopy: () => _copyToClipboard(password.password, 'Password'),
                        trailing: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                      ),
                      if (password.url != null) ...[
                        const Divider(height: 32),
                        _buildDetailField(
                          'URL',
                          password.url!,
                          Icons.link,
                          onCopy: () => _copyToClipboard(password.url!, 'URL'),
                        ),
                      ],
                      if (password.notes != null) ...[
                        const Divider(height: 32),
                        _buildDetailField(
                          'Notes',
                          password.notes!,
                          Icons.notes,
                          maxLines: 5,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metadata',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildMetadataRow('Created', _formatDate(password.createdAt)),
                      const SizedBox(height: 8),
                      _buildMetadataRow('Updated', _formatDate(password.updatedAt)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailField(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onCopy,
    Widget? trailing,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing,
            if (onCopy != null)
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: onCopy,
                iconSize: 20,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
