# APWD - Secure Password Manager

A lightweight, cross-platform password manager built with Flutter, featuring AES-256 encryption and local-first storage.

## 🔐 Features

- **Strong Encryption**: AES-256-CBC encryption with PBKDF2 key derivation (100,000 iterations)
- **Local Storage**: All data stored locally in an encrypted SQLCipher database
- **Biometric Authentication**: Support for Face ID, Touch ID, and fingerprint (native platforms only)
- **Auto-Lock**: Configurable auto-lock timeout for security
- **Password Generator**: Generate strong, customizable passwords
- **Groups/Categories**: Organize passwords into groups
- **Search**: Quick search across all password entries
- **Export/Import**: Encrypted backup and restore functionality
- **No Cloud**: Your data never leaves your device

## ✅ Supported Platforms

| Platform | Status | Requirements |
|----------|--------|--------------|
| **iOS** | ✅ Fully Supported | iOS 12.0+ |
| **Android** | ✅ Fully Supported | Android 6.0+ (API 23) |
| **macOS** | ✅ Fully Supported | macOS 10.14+ |
| **Windows** | ✅ Fully Supported | Windows 10+ |
| **Linux** | ✅ Fully Supported | Ubuntu 20.04+ |
| **Web** | ❌ Not Supported | See [Web Platform](docs/development/WEB_PLATFORM.md) |

### Why Web is Not Supported

APWD uses SQLCipher for encrypted database storage, which requires native SQLite binaries and is not compatible with Web browsers. Web browsers use IndexedDB, which has a different API and security model.

For technical details, see [Web Platform](docs/development/WEB_PLATFORM.md).

## 🚀 Getting Started

### Prerequisites

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- For iOS: Xcode 14+
- For Android: Android Studio with Android SDK

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd apwd
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# iOS (requires macOS with Xcode)
flutter run -d ios

# Android (requires Android emulator or device)
flutter run -d android

# macOS (requires Xcode)
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

## 📱 Usage

### First-Time Setup

1. Launch the app
2. Create a master password (minimum 8 characters)
3. Confirm your master password
4. Start adding password entries!

### Adding a Password

1. Tap the **+** button on the home screen
2. Fill in the details:
   - Title (required)
   - Username
   - Password (or use the password generator)
   - URL
   - Notes
3. Select a group/category
4. Tap **Save**

### Password Generator

- Configurable length (8-32 characters)
- Choose character types: uppercase, lowercase, digits, symbols
- One-tap copy to clipboard

### Security Settings

- **Auto-lock timeout**: 30 seconds to 1 hour (or never)
- **Biometric authentication**: Enable Face ID/Touch ID/fingerprint
- **Clipboard timeout**: Auto-clear copied passwords after 30-120 seconds

## 🔧 Development

> **🐛 Debugging?** Check the [Debugging Guide](docs/development/DEBUGGING_GUIDE.md) for systematic problem-solving approach and common traps.

### Running Tests

```bash
# Run all unit tests
flutter test

# Run tests with coverage
flutter test --coverage
```

**Test Results**:
- Unit Tests: 108/108 passing ✅
- Integration Tests: 13/13 passing ✅

See [Testing Documentation](docs/testing/TESTING.md) for details.

### Project Structure

```
lib/
├── models/          # Data models (Group, PasswordEntry, AppSettings)
├── services/        # Business logic services
│   ├── auth_service.dart
│   ├── crypto_service.dart
│   ├── database_service.dart
│   ├── password_service.dart
│   ├── group_service.dart
│   ├── generator_service.dart
│   └── export_import_service.dart
├── providers/       # State management (Provider pattern)
│   ├── auth_provider.dart
│   ├── password_provider.dart
│   ├── group_provider.dart
│   └── settings_provider.dart
├── screens/         # UI screens
│   ├── splash_screen.dart
│   ├── setup_password_screen.dart
│   ├── lock_screen.dart
│   ├── home_screen.dart
│   ├── password_detail_screen.dart
│   ├── password_edit_screen.dart
│   └── settings_screen.dart
├── widgets/         # Reusable widgets
│   └── password_generator_dialog.dart
└── utils/           # Constants and utilities
    └── constants.dart
```

### Architecture

- **Data Layer**: SQLCipher encrypted database
- **Business Logic Layer**: Services for crypto, auth, database operations
- **State Management**: Provider pattern
- **UI Layer**: Flutter Material Design 3

### Encryption Details

- **Key Derivation**: PBKDF2-HMAC-SHA256 with 100,000 iterations
- **Encryption**: AES-256-CBC with PKCS7 padding
- **Random IV**: New IV for each encryption operation
- **Key Splitting**: Derived key split into database key and authentication key
- **Master Password**: Never stored; only the hash is stored for verification

## 📚 Documentation

### Development Guides
- [**Development Overview**](docs/development/README.md) - Index of all development documentation
- [**Debugging Guide**](docs/development/DEBUGGING_GUIDE.md) ⭐ - **Systematic debugging methodology and common traps**
- [Android Setup](docs/development/ANDROID_SETUP.md) - Android development and real device testing
- [iOS Setup](docs/development/IOS_SETUP.md) - iOS development environment
- [Web Platform](docs/development/WEB_PLATFORM.md) - Why Web is not supported

### Testing & Design
- [Testing](docs/testing/TESTING.md) - Complete testing guide with automation
- [Design Specs](docs/superpowers/specs/) - Architecture and design documents

## 🛡️ Security Considerations

- **Master Password**: Choose a strong, unique master password. If forgotten, data cannot be recovered.
- **Local Storage**: Data is stored locally only. No cloud sync means no backup unless you use the export feature.
- **Biometric Data**: Never stored in the app; uses platform-native biometric APIs.
- **Auto-Lock**: Recommended for mobile devices to prevent unauthorized access.

## 🐛 Known Issues

- Web platform not supported (SQLCipher incompatibility)
- `file_picker` plugin warnings on some platforms (does not affect functionality)

## 📝 License

[Add your license here]

## 🤝 Contributing

[Add contributing guidelines here]

## 📧 Contact

[Add contact information here]

---

**Version**: 0.1.0+1
**Last Updated**: 2026-03-21
