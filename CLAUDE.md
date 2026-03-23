# APWD - Secure Password Manager

A Flutter-based password manager with SQLCipher encryption, WebDAV backup, and cross-platform support.

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run on iOS
flutter run -d iPhone

# Run tests
flutter test

# Run UI integration tests (requires simulator)
flutter test test/ui/app_test.dart -d <device-id>
```

## Project Architecture

APWD follows a layered architecture with Provider for state management:

```
lib/
├── models/        # Data models (Group, PasswordEntry)
├── services/      # Business logic layer → See lib/services/CLAUDE.md
├── providers/     # State management   → See lib/providers/CLAUDE.md
├── screens/       # UI layer           → See lib/screens/CLAUDE.md
├── widgets/       # Reusable components
└── utils/         # Constants and utilities
```

### Core Technologies

- **Encryption**: SQLCipher (AES-256), PBKDF2-HMAC-SHA256
- **Storage**: Encrypted SQLite database
- **State**: Provider pattern
- **Backup**: WebDAV with encrypted exports
- **Platforms**: iOS, Android, macOS

## Key Features

### Security
- SQLCipher encrypted database
- Master password with key derivation (100k iterations)
- Biometric authentication support
- Auto-lock after timeout
- Encrypted backup/restore

### Password Management
- Organize by groups
- Secure password generator
- Search and filter
- Copy to clipboard with auto-clear

### Backup & Sync
- WebDAV integration for remote backup
- Encrypted export/import (.apwd format)
- Restore with skip/overwrite options

## Documentation Index

### Architecture & Implementation
- **[lib/CLAUDE.md](lib/CLAUDE.md)** - Code architecture overview
- **[lib/services/CLAUDE.md](lib/services/CLAUDE.md)** - Service layer details
- **[lib/providers/CLAUDE.md](lib/providers/CLAUDE.md)** - State management
- **[lib/screens/CLAUDE.md](lib/screens/CLAUDE.md)** - UI components

### Testing
- **[test/CLAUDE.md](test/CLAUDE.md)** - Testing strategy and conventions

### Development
- **[docs/CLAUDE.md](docs/CLAUDE.md)** - Development guides and references
- **[docs/MOBILE_MCP_SETUP.md](docs/MOBILE_MCP_SETUP.md)** - AI-driven simulator testing

## Common Tasks

### Adding a New Feature

1. **Design**: Create spec in `docs/superpowers/specs/`
2. **Plan**: Create plan in `docs/superpowers/plans/`
3. **Implement**: Follow service → provider → screen pattern
4. **Test**: Write unit tests, integration tests
5. **Document**: Update relevant CLAUDE.md files

### Modifying Encryption

See [lib/services/CLAUDE.md](lib/services/CLAUDE.md#crypto-service) for crypto implementation details.

### Adding UI Screens

See [lib/screens/CLAUDE.md](lib/screens/CLAUDE.md) for screen conventions and patterns.

## Test Coverage

- **Unit Tests**: 24 tests (services, models)
- **Integration Tests**: 24 tests (database, export/import, WebDAV)
- **UI Tests**: 1 comprehensive E2E test (5 scenarios)

Run all tests:
```bash
flutter test
```

## Recent Updates

- ✅ WebDAV backup/restore functionality
- ✅ Comprehensive test suite (48 automated tests)
- ✅ UI integration testing support
- ✅ Mobile-MCP setup for AI-driven testing

## Contributing

1. Read architecture docs in `lib/CLAUDE.md`
2. Follow existing patterns
3. Write tests for new features
4. Update documentation

## Security Notes

- Master password never stored in plain text
- All passwords encrypted at rest (SQLCipher)
- Backup exports are encrypted (AES-256-CBC)
- Clipboard auto-clears after timeout
- Biometric data stored in secure platform storage
