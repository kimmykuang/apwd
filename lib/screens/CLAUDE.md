# Screens Layer

Screens are Flutter widgets that compose the UI. They consume providers for state and delegate actions to them.

## Screen Responsibilities

Screens handle:
- ✅ UI rendering and layout
- ✅ User input and gestures
- ✅ Navigation
- ✅ Consuming provider state

Screens do NOT:
- ❌ Business logic (delegate to providers/services)
- ❌ Direct database access
- ❌ Complex state management (use providers)

## Screen Catalog

### SetupPasswordScreen
**Purpose**: First-time master password setup

**Route**: `/setup-password`

**Features:**
- Password strength indicator
- Confirm password validation
- Creates database and sets up authentication

**State Management:**
- Uses `AuthProvider` for setup
- Creates initial default group after setup

---

### LockScreen
**Purpose**: Master password entry to unlock app

**Route**: `/lock`

**Features:**
- Password input with visibility toggle
- Biometric authentication button (if available)
- Remember last unlock attempt (error message)

**State Management:**
- Uses `AuthProvider.unlock()` / `unlockWithBiometric()`
- Navigates to HomeScreen on success

---

### HomeScreen
**Purpose**: Main password list view

**Route**: `/` (initial)

**Features:**
- Search bar with real-time filtering
- Grouped password list by category
- Pull-to-refresh
- Menu: Manage Groups, Settings, Lock

**State Management:**
- `PasswordProvider` for password list
- `GroupProvider` for group names
- `AuthProvider` for lock action

**Lifecycle:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();  // Load passwords and groups
  });
}

Future<void> _loadData() async {
  await Future.wait([
    context.read<PasswordProvider>().loadPasswords(),
    context.read<GroupProvider>().loadGroups(),
  ]);
}
```

---

### PasswordDetailScreen
**Purpose**: View password details with copy actions

**Route**: `/password-detail`

**Features:**
- Show/hide password toggle
- Copy buttons (username, password, URL)
- Edit and delete actions
- Metadata display (created, updated timestamps)

**State Management:**
- `PasswordProvider.selectPassword()` to load
- `PasswordProvider.selectedPassword` for display
- `PasswordProvider.deletePassword()` for deletion

**Key Pattern:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadPassword();
  });
}

Future<void> _loadPassword() async {
  await context.read<PasswordProvider>().selectPassword(widget.passwordId);
}
```

---

### PasswordEditScreen
**Purpose**: Add or edit password entry

**Route**: `/password-edit`

**Arguments**: `passwordId` (null for add, int for edit)

**Features:**
- Group selector dropdown
- Form validation
- Password generator button
- Show/hide password toggle
- Auto-fill from selected password (edit mode)

**Form Fields:**
- Title (required)
- Username (optional)
- Password (required) with generator
- URL (optional)
- Notes (optional, multiline)

**State Management:**
- `GroupProvider.groups` for dropdown
- `PasswordProvider.createPassword() / updatePassword()`

**Validation:**
```dart
TextFormField(
  controller: _titleController,
  decoration: InputDecoration(labelText: 'Title'),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a title';
    }
    return null;
  },
)
```

---

### GroupsScreen
**Purpose**: Manage password groups

**Route**: `/groups`

**Features:**
- List of groups with reorder support
- Edit and delete actions
- Default group cannot be deleted

**State Management:**
- `GroupProvider.groups` for list
- `GroupProvider.deleteGroup()` for deletion
- `GroupProvider.reorderGroups()` for drag-to-reorder

---

### GroupEditScreen
**Purpose**: Add or edit group

**Route**: `/group-edit`

**Arguments**: `groupId` (null for add, int for edit)

**Features:**
- Icon selector (emoji grid)
- Name input with validation
- Sort order (auto-assigned for new groups)

---

### SettingsScreen
**Purpose**: App configuration and WebDAV setup

**Route**: `/settings`

**Features:**
- **Security Section:**
  - Auto-lock timeout
  - Clipboard clear timeout
  - Biometric authentication toggle

- **WebDAV Backup Section:**
  - Enable/disable WebDAV
  - Server URL, username, password, remote path
  - Test connection button
  - Backup now / Restore buttons
  - Last backup timestamp

- **About Section:**
  - App version
  - Build number

**State Management:**
- `SettingsProvider` for general settings
- `WebDavProvider` for WebDAV configuration
- `AuthProvider` for biometric settings

**WebDAV Workflow:**
1. User configures WebDAV settings
2. Test connection
3. Click "Backup Now" → prompts for encryption password
4. Provider creates encrypted backup and uploads
5. Click "Restore" → lists available backups → prompts for password
6. Provider downloads, decrypts, and imports

---

### SplashScreen
**Purpose**: App launch screen with initialization

**Features:**
- Check if master password is set up
- Navigate to SetupPasswordScreen or LockScreen

**Duration:** 1-2 seconds minimum for branding

---

### UnsupportedPlatformScreen
**Purpose**: Fallback for unsupported platforms

**Displays:** Message indicating platform is not supported (web, Linux, Windows)

---

## Common UI Patterns

### Loading States

```dart
Consumer<PasswordProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text('Error: ${provider.errorMessage}'));
    }

    return ListView(
      children: provider.passwords.map((p) => PasswordTile(p)).toList(),
    );
  },
)
```

### Form Validation

```dart
final _formKey = GlobalKey<FormState>();

ElevatedButton(
  onPressed: () {
    if (_formKey.currentState!.validate()) {
      _save();
    }
  },
  child: Text('Save'),
)
```

### Safe Navigation After Async

```dart
Future<void> _save() async {
  setState(() => _isLoading = true);

  try {
    final success = await context.read<PasswordProvider>().createPassword(entry);

    if (!mounted) return;  // ← Important!

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Copy to Clipboard

```dart
void _copyToClipboard(String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label copied to clipboard')),
  );
}
```

### Dialogs

```dart
Future<bool?> _showDeleteConfirmation() {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Password'),
      content: Text('Are you sure you want to delete this password?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

// Usage
final confirmed = await _showDeleteConfirmation();
if (confirmed == true) {
  await _deletePassword();
}
```

### TextEditingController Lifecycle

```dart
class _PasswordEditScreenState extends State<PasswordEditScreen> {
  final _titleController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

**Important for dialogs:**
```dart
Future<void> _showPasswordDialog() async {
  final controller = TextEditingController();

  try {
    final result = await showDialog(...);
    // Handle result
  } finally {
    controller.dispose();  // ← Always dispose, even on cancel
  }
}
```

## Navigation

### Route Configuration

```dart
MaterialApp(
  initialRoute: '/splash',
  routes: {
    '/splash': (context) => SplashScreen(),
    '/setup-password': (context) => SetupPasswordScreen(),
    '/lock': (context) => LockScreen(),
    '/': (context) => HomeScreen(),
    '/password-detail': (context) => PasswordDetailScreen(...),
    '/password-edit': (context) => PasswordEditScreen(...),
    '/groups': (context) => GroupsScreen(),
    '/group-edit': (context) => GroupEditScreen(...),
    '/settings': (context) => SettingsScreen(),
  },
)
```

### Named Routes with Arguments

```dart
// Navigate with arguments
Navigator.of(context).pushNamed(
  '/password-detail',
  arguments: passwordId,
);

// Receive arguments
class PasswordDetailScreen extends StatefulWidget {
  final int passwordId;

  const PasswordDetailScreen({required this.passwordId});

  static PasswordDetailScreen fromRoute(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    return PasswordDetailScreen(passwordId: id);
  }
}
```

## Styling Conventions

### Theme

```dart
ThemeData(
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.grey[100],
  appBarTheme: AppBarTheme(
    elevation: 0,
    centerTitle: true,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
)
```

### Spacing

- Use `SizedBox(height: 16)` for vertical spacing
- Use `Padding(padding: EdgeInsets.all(16))` for screen padding
- Consistent spacing: 8, 16, 24, 32

### Typography

- Use `Theme.of(context).textTheme.headlineSmall` for titles
- Use `Theme.of(context).textTheme.bodyLarge` for content
- Use `Theme.of(context).textTheme.bodySmall` for captions

## Accessibility

- All interactive elements have semantic labels
- Text contrast ratios meet WCAG AA standards
- Touch targets at least 44x44 points
- Support dynamic text sizing

## Common Gotchas

### 1. Context after async

❌ **Wrong:**
```dart
Future<void> _save() async {
  await someAsyncOperation();
  Navigator.pop(context);  // Context might be invalid
}
```

✅ **Right:**
```dart
Future<void> _save() async {
  await someAsyncOperation();
  if (!mounted) return;
  Navigator.pop(context);
}
```

### 2. Forgetting to load data

❌ **Wrong:**
```dart
@override
void initState() {
  super.initState();
  _loadData();  // Might call notifyListeners during build
}
```

✅ **Right:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();
  });
}
```

### 3. Not disposing controllers

❌ **Wrong:**
```dart
final _controller = TextEditingController();
// No dispose
```

✅ **Right:**
```dart
final _controller = TextEditingController();

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

## Testing Screens

Widget tests for screens:

```dart
void main() {
  testWidgets('should display password list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen()),
    );

    expect(find.text('Passwords'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('should navigate to add password', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(PasswordEditScreen), findsOneWidget);
  });
}
```

## Next Steps

- See [../providers/CLAUDE.md](../providers/CLAUDE.md) for provider usage
- See [../../test/ui/CLAUDE.md](../../test/ui/CLAUDE.md) for UI testing
