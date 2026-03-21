import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/password_entry.dart';
import '../providers/password_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/password_generator_dialog.dart';

/// Screen for creating or editing a password entry
class PasswordEditScreen extends StatefulWidget {
  final int? passwordId;

  const PasswordEditScreen({super.key, this.passwordId});

  @override
  State<PasswordEditScreen> createState() => _PasswordEditScreenState();
}

class _PasswordEditScreenState extends State<PasswordEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  int? _selectedGroupId;
  PasswordEntry? _existingEntry;

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保在 build 完成后加载数据
    // 这样避免在 build 过程中调用 setState/notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<GroupProvider>().loadGroups();

    if (widget.passwordId != null) {
      await context.read<PasswordProvider>().selectPassword(widget.passwordId!);
      final password = context.read<PasswordProvider>().selectedPassword;

      if (password != null) {
        setState(() {
          _existingEntry = password;
          _titleController.text = password.title;
          _usernameController.text = password.username ?? '';
          _passwordController.text = password.password;
          _urlController.text = password.url ?? '';
          _notesController.text = password.notes ?? '';
          _selectedGroupId = password.groupId;
        });
      }
    } else {
      // Set default group for new entries
      final groups = context.read<GroupProvider>().groups;
      if (groups.isNotEmpty) {
        setState(() {
          _selectedGroupId = groups.first.id;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a group'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final entry = PasswordEntry(
        id: widget.passwordId,
        groupId: _selectedGroupId!,
        title: _titleController.text,
        username: _usernameController.text.isEmpty ? null : _usernameController.text,
        password: _passwordController.text,
        url: _urlController.text.isEmpty ? null : _urlController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: _existingEntry?.createdAt ?? now,
        updatedAt: now,
      );

      final passwordProvider = context.read<PasswordProvider>();
      final success = widget.passwordId == null
          ? await passwordProvider.createPassword(entry)
          : await passwordProvider.updatePassword(entry);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(passwordProvider.errorMessage ?? 'Failed to save'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePassword() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const PasswordGeneratorDialog(),
    );

    if (password != null) {
      setState(() {
        _passwordController.text = password;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.passwordId == null ? 'Add Password' : 'Edit Password'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Consumer<GroupProvider>(
              builder: (context, provider, child) {
                if (provider.groups.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No groups available. Create a group first.'),
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Group',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.groups.map((group) {
                    return DropdownMenuItem(
                      value: group.id,
                      child: Text(group.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGroupId = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a group';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _generatePassword,
                    ),
                  ],
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.passwordId == null ? 'Add Password' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
