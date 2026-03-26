# Testing

APWD uses a comprehensive testing strategy with multiple test layers.

## Quick Start

```bash
# 运行所有测试
python test/run_tests.py --all

# 运行特定类型测试
python test/run_tests.py --unit           # 单元测试
python test/run_tests.py --integration    # 集成测试
python test/run_tests.py --e2e-mobile     # 移动端 E2E
python test/run_tests.py --e2e-web        # Web E2E

# 运行特定移动端场景
python test/run_tests.py --e2e-mobile --scenario webdav_test
```

---

## Test Structure

```
test/
├── unit/                    # 单元测试 (26 tests)
│   ├── models/              # Model 序列化测试
│   ├── services/            # Service 单元测试
│   └── reports/             # 单元测试报告 (gitignored)
│
├── integration/             # Flutter 集成测试 (10 tests)
│   ├── webdav_integration_test.dart   # WebDAV 备份/恢复集成
│   ├── webdav_full_e2e_test.dart      # 完整 E2E 场景
│   └── reports/             # 集成测试报告 (gitignored)
│
├── e2e/                     # 端到端测试
│   ├── mobile/              # 移动端 E2E (7 scenarios)
│   │   ├── scenarios/       # YAML 测试场景
│   │   ├── utils/           # Python 工具脚本
│   │   ├── reports/         # 测试报告和截图 (gitignored)
│   │   ├── run_tests.sh     # 移动端测试启动器
│   │   ├── config.yaml      # 测试配置
│   │   └── README.md        # 详细文档
│   │
│   ├── web/                 # Web E2E (7 tests)
│   │   ├── e2e_test.py      # Selenium Web 测试
│   │   └── reports/         # Web 测试报告 (gitignored)
│   │
│   └── autonomous/          # 自主测试运行器
│       ├── autonomous_test_runner.py  # iOS 自动化测试
│       └── reports/         # 自主测试报告 (gitignored)
│
├── CLAUDE.md                # 测试文档 (本文件)
└── run_tests.py             # 统一测试入口 ⭐
```

---

## Test Types

### 1. Unit Tests (`test/unit/`)

**Purpose**: Test individual service methods in isolation

**Coverage:** 26 tests
- Models: 2 tests (Group, PasswordEntry)
- Services: 24 tests (Auth, Crypto, Database, Password, Group, WebDAV, etc.)

**Run:**
```bash
# 运行所有单元测试
flutter test test/unit

# 运行特定文件
flutter test test/unit/services/crypto_service_test.dart
```

**Pattern:**
```dart
void main() {
  late ServiceClass service;
  late MockDependency mockDep;

  setUp(() {
    mockDep = MockDependency();
    service = ServiceClass(mockDep);
  });

  test('should do something', () async {
    // Arrange
    when(mockDep.method()).thenReturn(value);

    // Act
    final result = await service.method();

    // Assert
    expect(result, expectedValue);
  });
}
```

**Key Services Tested:**
- `CryptoService` - Encryption/decryption
- `PasswordService` - CRUD operations
- `GroupService` - Group management
- `WebDavService` - Remote sync
- `ExportImportService` - Backup/restore

---

### 2. Integration Tests (`test/integration/`)

**Purpose**: Test interactions between multiple services

**Coverage:** 10 tests
- `webdav_integration_test.dart` - WebDAV backup/restore workflows (5 tests)
- `webdav_full_e2e_test.dart` - Complete self-contained scenarios (5 tests)

**Run:**
```bash
flutter test test/integration
```

**Pattern:**
```dart
void main() {
  late DatabaseService dbService;
  late PasswordService passwordService;

  setUp(() async {
    dbService = DatabaseService();
    await dbService.initialize(testPath, testKey);
    passwordService = PasswordService(dbService);
  });

  tearDown() async {
    await dbService.close();
    await File(testDbPath).delete();
  });

  test('complete workflow', () async {
    // Create → Export → Clear → Import → Verify
  });
}
```

**Difference from E2E:**
- Integration tests call service methods directly (Dart code)
- E2E tests interact with real UI via simulator (user perspective)
- Integration tests are faster (~5 seconds)
- E2E tests are comprehensive (~2 minutes per scenario)

---

### 3. Mobile E2E Tests (`test/e2e/mobile/`)

**Purpose**: Test complete user workflows on real iOS simulator

**Coverage:** 7 scenarios
1. `base_setup.yaml` - First-time master password setup
2. `standard_state.yaml` - Prepare standard test data
3. `search_test.yaml` - Search functionality
4. `password_crud_test.yaml` - Password CRUD operations
5. `groups_test.yaml` - Group management
6. `webdav_test.yaml` - WebDAV backup/restore
7. `export_import_test.yaml` - Export/import workflows

**Technology Stack:**
- **Claude AI** - Interprets YAML scenarios and adapts to UI
- **mobile-mcp** - Controls iOS simulator via MCP protocol
- **Python** - Orchestration scripts

**Run:**
```bash
# 交互式菜单
cd test/e2e/mobile && ./run_tests.sh

# 或使用统一入口
python test/run_tests.py --e2e-mobile

# 运行特定场景
python test/run_tests.py --e2e-mobile --scenario webdav_test
```

**Features:**
- ✅ Real iOS simulator UI testing
- ✅ AI-driven, adapts to UI changes
- ✅ Screenshot capture at each step
- ✅ Mock WebDAV server support
- ✅ Natural language test scenarios

**Documentation:** See [test/e2e/mobile/README.md](e2e/mobile/README.md)

---

### 4. Web E2E Tests (`test/e2e/web/`)

**Purpose**: Test Flutter Web version in browser

**Coverage:** 7 tests
- Master password setup
- Password CRUD
- Search functionality
- Complete user workflows

**Technology:** Selenium WebDriver + Chrome

**Run:**
```bash
# 1. 启动 Flutter Web 应用
flutter run -d chrome

# 2. 运行测试
python test/e2e/web/e2e_test.py

# 或使用统一入口
python test/run_tests.py --e2e-web
```

**Output:**
- Screenshots: `test/e2e/web/reports/`
- Test report: Console output

---

### 5. Autonomous Tests (`test/e2e/autonomous/`)

**Purpose**: Fully automated iOS simulator testing

**Coverage:** Complete application workflow
- Simulator setup and management
- App installation and launch
- Full test suite execution
- Result reporting

**Run:**
```bash
python test/e2e/autonomous/autonomous_test_runner.py

# 或使用统一入口
python test/run_tests.py --e2e-autonomous
```

**Features:**
- ✅ Zero manual intervention
- ✅ Automatic simulator selection
- ✅ Build and install automation
- ✅ Comprehensive result reporting

---

## Test Reports

All test reports are automatically generated and stored in respective `reports/` directories:

```
test/unit/reports/          # Unit test coverage reports
test/integration/reports/   # Integration test reports
test/e2e/mobile/reports/    # Mobile E2E screenshots and reports
test/e2e/web/reports/       # Web E2E screenshots
test/e2e/autonomous/reports/# Autonomous test results
```

**Note:** All `reports/` directories are gitignored to keep the repository clean.

---

## Running Tests in CI/CD

### GitHub Actions Example

```yaml
name: Test

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter test test/unit

  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter test test/integration

  mobile-e2e:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - name: Run Mobile E2E
        run: python test/run_tests.py --e2e-mobile --scenario search_test
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

---

## Test Coverage Summary

| Test Type | Count | Run Time | Purpose |
|-----------|-------|----------|---------|
| Unit | 26 | ~10s | Service logic verification |
| Integration | 10 | ~30s | Multi-service workflows |
| Mobile E2E | 7 scenarios | ~2min/scenario | Real UI testing (iOS) |
| Web E2E | 7 tests | ~5min | Real UI testing (Web) |
| Autonomous | Full suite | ~10min | Automated iOS testing |

**Total Coverage:** ~92% of features

---

## Best Practices

### When to Use Each Test Type

1. **Unit Tests** - When developing/modifying service methods
2. **Integration Tests** - When testing cross-service interactions
3. **Mobile E2E** - Before releases, to verify complete iOS flows
4. **Web E2E** - To verify Flutter Web compatibility
5. **Autonomous** - For continuous testing in CI/CD

### Writing New Tests

#### Unit Test
```bash
# Create test file in test/unit/services/
cp test/unit/services/password_service_test.dart \
   test/unit/services/new_service_test.dart

# Run the test
flutter test test/unit/services/new_service_test.dart
```

#### Mobile E2E Scenario
```bash
# Create YAML scenario in test/e2e/mobile/scenarios/
cp test/e2e/mobile/scenarios/search_test.yaml \
   test/e2e/mobile/scenarios/new_test.yaml

# Edit scenario and run
python test/run_tests.py --e2e-mobile --scenario new_test
```

---

## Troubleshooting

### Common Issues

#### Unit/Integration Tests Fail
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter test
```

#### Mobile E2E Fails
```bash
# Check simulator
xcrun simctl list devices

# Restart simulator
xcrun simctl shutdown all
xcrun simctl boot "iPhone 16"

# Check mobile-mcp
npm list -g mobile-mcp
```

#### Web E2E Fails
```bash
# Ensure app is running
flutter run -d chrome

# Check Selenium dependencies
pip3 install selenium
```

---

## References

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mobile E2E Documentation](e2e/mobile/README.md)
- [Mobile-MCP Setup](../docs/MOBILE_MCP_SETUP.md)

---

**Last Updated:** 2026-03-26
**Version:** 2.0 (Restructured)
