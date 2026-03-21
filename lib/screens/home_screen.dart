import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/password_provider.dart';
import '../providers/group_provider.dart';

/// Home screen showing password list
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final passwordProvider = context.read<PasswordProvider>();
    final groupProvider = context.read<GroupProvider>();

    await Future.wait([
      passwordProvider.loadPasswords(),
      groupProvider.loadGroups(),
    ]);
  }

  void _onSearch(String query) {
    context.read<PasswordProvider>().searchPasswords(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APWD'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'groups':
                  Navigator.of(context).pushNamed('/groups');
                  break;
                case 'settings':
                  Navigator.of(context).pushNamed('/settings');
                  break;
                case 'lock':
                  await context.read<AuthProvider>().lock();
                  Navigator.of(context).pushReplacementNamed('/lock');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'groups',
                child: Row(
                  children: [
                    Icon(Icons.folder),
                    SizedBox(width: 8),
                    Text('Manage Groups'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'lock',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline),
                    SizedBox(width: 8),
                    Text('Lock'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search passwords...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: Consumer2<PasswordProvider, GroupProvider>(
              builder: (context, passwordProvider, groupProvider, child) {
                if (passwordProvider.isLoading || groupProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (passwordProvider.passwords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.password,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No passwords yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first password',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                // Group passwords by groupId
                final groupedPasswords = <int, List<dynamic>>{};
                for (final password in passwordProvider.passwords) {
                  groupedPasswords.putIfAbsent(password.groupId, () => []).add(password);
                }

                // Get groups that have passwords and sort them
                final groupsWithPasswords = groupProvider.groups
                    .where((g) => groupedPasswords.containsKey(g.id))
                    .toList()
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                // Build flat list with headers and items
                final items = <Widget>[];
                for (final group in groupsWithPasswords) {
                  final passwords = groupedPasswords[group.id] ?? [];

                  // Add group header
                  items.add(
                    Container(
                      key: ValueKey('group_${group.id}'),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            group.icon ?? '📁',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            group.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${passwords.length})',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  // Add password items
                  for (final password in passwords) {
                    items.add(
                      ListTile(
                        key: ValueKey('password_${password.id}'),
                        leading: CircleAvatar(
                          child: Text(
                            password.title[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(password.title),
                        subtitle: Text(password.username ?? 'No username'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/password-detail',
                            arguments: password.id,
                          );
                        },
                      ),
                    );
                  }
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    children: items,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/password-edit');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
