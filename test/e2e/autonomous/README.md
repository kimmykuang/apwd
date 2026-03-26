# Autonomous Test Runner

Fully automated iOS simulator testing framework for APWD.

## Overview

The autonomous test runner provides zero-manual-intervention testing by:
1. Automatically selecting and booting iOS simulator
2. Building and installing the APWD app
3. Running comprehensive test suite
4. Generating detailed reports

## Features

- ✅ **Zero Configuration** - Automatically finds available simulators
- ✅ **Self-Contained** - Handles build, install, and execution
- ✅ **Comprehensive** - Tests complete application workflow
- ✅ **Resilient** - Handles errors and retries automatically
- ✅ **Detailed Reports** - JSON and text output with timestamps

## Prerequisites

```bash
# Xcode Command Line Tools
xcode-select --install

# Flutter SDK
flutter doctor

# Python 3
python3 --version
```

## Running Tests

### Quick Start

```bash
# Run from project root
python3 test/e2e/autonomous/autonomous_test_runner.py

# Or use unified test runner
python test/run_tests.py --e2e-autonomous
```

### What It Does

1. **Setup Phase**
   - Lists available iOS simulators
   - Selects best simulator (prioritizes iPhone 16)
   - Boots simulator if not running
   - Waits for simulator to be ready

2. **Build Phase**
   - Runs `flutter pub get`
   - Builds app for iOS simulator
   - Installs app on simulator

3. **Test Phase**
   - Launches APWD app
   - Executes test scenarios:
     - Master password setup
     - Password creation
     - Password viewing
     - Search functionality
     - Group management

4. **Cleanup Phase**
   - Collects test results
   - Generates reports
   - Shuts down simulator (optional)

## Output

### Reports Directory

```
test/e2e/autonomous/reports/
├── test_run_20260326_143000.json       # Machine-readable results
├── test_run_20260326_143000.txt        # Human-readable log
└── screenshots/                         # Test screenshots (if enabled)
    ├── step_1_setup.png
    ├── step_2_create.png
    └── step_3_verify.png
```

### JSON Report Format

```json
{
  "timestamp": "2026-03-26T14:30:00",
  "duration_seconds": 180,
  "simulator": {
    "name": "iPhone 16",
    "os": "iOS 18.0",
    "uuid": "12345678-1234-1234-1234-123456789012"
  },
  "phases": {
    "setup": "success",
    "build": "success",
    "install": "success",
    "test": "success"
  },
  "tests": [
    {
      "name": "Master Password Setup",
      "status": "passed",
      "duration": 15.2
    },
    {
      "name": "Create Password",
      "status": "passed",
      "duration": 8.5
    }
  ],
  "summary": {
    "total": 5,
    "passed": 5,
    "failed": 0,
    "skipped": 0
  }
}
```

## Configuration

Edit `autonomous_test_runner.py` to customize:

```python
class AutonomousTestRunner:
    def __init__(self):
        self.project_dir = Path(__file__).parent.parent.parent.parent
        self.results_dir = self.test_dir / "reports"

        # Test configuration
        self.test_timeout = 300  # 5 minutes per test
        self.retry_count = 3
        self.cleanup_on_success = True
```

## Troubleshooting

### Simulator Not Found

**Error**: `No available iOS simulators found`

**Solution**:
```bash
# List simulators
xcrun simctl list devices

# Create new simulator
xcrun simctl create "iPhone 16" "iPhone 16" "iOS-18-0"
```

### Build Failed

**Error**: `Flutter build failed`

**Solution**:
```bash
# Clean Flutter cache
flutter clean
flutter pub get

# Verify Flutter installation
flutter doctor -v
```

### App Install Failed

**Error**: `Failed to install app on simulator`

**Solution**:
```bash
# Reset simulator
xcrun simctl shutdown all
xcrun simctl erase all

# Rebuild and try again
flutter clean
flutter build ios --simulator
```

### Test Timeout

**Error**: `Test execution timeout after 300s`

**Solution**:
- Increase `test_timeout` in configuration
- Check simulator performance (close other apps)
- Verify app is responding (not crashed)

## Comparison with Other Test Types

| Feature | Autonomous | Mobile E2E | Unit/Integration |
|---------|-----------|------------|------------------|
| **Automation Level** | Fully automated | Semi-automated | Fully automated |
| **User Interaction** | None | None | N/A |
| **Setup Required** | Minimal | Moderate | Minimal |
| **Test Definition** | Python code | YAML | Dart code |
| **Speed** | Slow (~10min) | Slow (~2min/scenario) | Fast (<30s) |
| **CI/CD Friendly** | ⚠️ Requires macOS | ⚠️ Requires macOS | ✅ Any platform |
| **Debugging** | Logs + JSON | Screenshots | Stack traces |

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Autonomous Tests

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:      # Manual trigger

jobs:
  autonomous-test:
    runs-on: macos-latest
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v2

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Run autonomous tests
        run: python3 test/e2e/autonomous/autonomous_test_runner.py

      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v2
        with:
          name: autonomous-test-reports
          path: test/e2e/autonomous/reports/
```

## Use Cases

### 1. Nightly Regression Testing
Run comprehensive tests every night to catch regressions early.

### 2. Pre-Release Validation
Validate complete workflows before creating a release.

### 3. Smoke Testing
Quick sanity check after major changes.

### 4. Performance Baseline
Track test execution time to detect performance degradation.

## Best Practices

1. **Run on dedicated hardware** - Avoid running on development machines
2. **Monitor reports** - Set up alerts for test failures
3. **Keep updated** - Update simulator OS versions regularly
4. **Clean state** - Reset simulator between test runs if needed
5. **Log everything** - Detailed logs help debug failures

## Advanced Usage

### Custom Test Scenarios

Modify the test scenarios in `autonomous_test_runner.py`:

```python
def run_test_scenarios(self):
    """Execute test scenarios"""
    scenarios = [
        self.test_master_password_setup,
        self.test_create_password,
        self.test_custom_scenario,  # Add your own
    ]

    for scenario in scenarios:
        scenario()

def test_custom_scenario(self):
    """Your custom test logic"""
    print("Running custom scenario...")
    # Implementation here
```

### Parallel Execution

Run multiple simulators in parallel:

```python
# Run on iPhone 16
python3 test/e2e/autonomous/autonomous_test_runner.py --device "iPhone 16"

# Run on iPhone 16 Pro (in another terminal)
python3 test/e2e/autonomous/autonomous_test_runner.py --device "iPhone 16 Pro"
```

---

**Version**: 1.0
**Last Updated**: 2026-03-26
**Maintenance**: Active development
