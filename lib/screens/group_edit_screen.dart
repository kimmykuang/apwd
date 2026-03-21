import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';

/// Screen for creating or editing a group
class GroupEditScreen extends StatefulWidget {
  final int? groupId;

  const GroupEditScreen({super.key, this.groupId});

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  String _selectedIcon = '📁';
  Group? _existingGroup;

  // Common icons for groups
  final List<String> _availableIcons = [
    '📁', '🔑', '👤', '💼', '💰', '🌐', '🎮', '🎓', '🏠', '🏥',
    '🛒', '✈️', '🍔', '⚽', '🎵', '📱', '💻', '🚗', '🏦', '📧',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGroup();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    final groups = context.read<GroupProvider>().groups;
    final group = groups.firstWhere(
      (g) => g.id == widget.groupId,
      orElse: () => Group(
        name: '',
        icon: '📁',
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    setState(() {
      _existingGroup = group;
      _nameController.text = group.name;
      _selectedIcon = group.icon ?? '📁';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final group = Group(
        id: widget.groupId,
        name: _nameController.text,
        icon: _selectedIcon,
        sortOrder: _existingGroup?.sortOrder ?? 0,
        createdAt: _existingGroup?.createdAt ?? now,
        updatedAt: now,
      );

      final groupProvider = context.read<GroupProvider>();
      final success = widget.groupId == null
          ? await groupProvider.createGroup(group)
          : await groupProvider.updateGroup(group);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(groupProvider.errorMessage ?? 'Failed to save'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupId == null ? 'Add Group' : 'Edit Group'),
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
            // Icon selector
            const Text(
              'Icon',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = _availableIcons[index];
                  final isSelected = icon == _selectedIcon;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedIcon = icon);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withOpacity(0.2) : null,
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Work, Personal, Finance',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a group name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: Text(
                        _selectedIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _nameController.text.isEmpty
                                ? 'Group Name'
                                : _nameController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
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
                  : Text(widget.groupId == null ? 'Create Group' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
