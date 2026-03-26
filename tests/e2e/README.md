# APWD E2E Test System

End-to-end testing framework for APWD password manager using Claude AI agent to drive real iOS simulator interactions.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Directory Structure](#directory-structure)
- [Test Scenarios](#test-scenarios)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Extension Guide](#extension-guide)

---

## Architecture Overview

The APWD E2E test system uses a unique **3-layer architecture** that combines AI-driven testing with mobile automation:

```
┌─────────────────────────────────────────────────────────────┐
│                    Layer 1: Claude AI Agent                 │
│  • Reads YAML test scenarios                                │
│  • Plans test steps dynamically                             │
│  • Adapts to UI variations                                  │
│  • Generates natural language commands                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                Layer 2: Python Orchestration                │
│  • prepare_standard_state.py - generates test data configs  │
│  • clean_app_data.py - resets simulator state               │
│  • Provides structured JSON responses                       │
│  • No direct database manipulation (encrypted)              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                 Layer 3: Mobile Automation                  │
│  • mobile-mcp server (iOS simulator control)                │
│  • xcrun simctl (native iOS commands)                       │
│  • Screenshot capture & visual verification                 │
│  • App lifecycle management                                 │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Declarative Test Scenarios**: Tests are written in YAML with human-readable descriptions
2. **AI-Driven Execution**: Claude interprets scenarios and adapts to UI changes
3. **State Management**: Python scripts prepare test states without touching encrypted data
4. **Visual Verification**: Screenshots captured at each step for debugging
5. **Real Device Testing**: All tests run on real iOS simulator, not mocked UI

### Why This Architecture?

- **No Test Code Maintenance**: No brittle XPath or widget locators to update
- **Natural Language Tests**: Scenarios read like user stories
- **Adaptive**: Claude handles minor UI variations without test updates
- **Encrypted Database**: Python doesn't need decryption keys - Claude uses UI
- **Debugging**: Full screenshot trail for every test execution

---

## Directory Structure

```
tests/e2e/
├── README.md                    # This file
├── config.yaml                  # Global test configuration
├── run_tests.sh                 # Quick launch script
│
├── scenarios/                   # Test scenario definitions
│   ├── base_setup.yaml          # [BASE] First-time master password setup
│   ├── standard_state.yaml      # [STATE] Standard test state with data
│   ├── search_test.yaml         # [TEST] Search functionality
│   ├── password_crud_test.yaml  # [TEST] Password CRUD operations
│   ├── groups_test.yaml         # [TEST] Group management
│   ├── webdav_test.yaml         # [TEST] WebDAV backup/restore
│   └── export_import_test.yaml  # [TEST] Export/Import workflows
│
├── utils/                       # Python utility scripts
│   ├── prepare_standard_state.py  # Generate test data config
│   └── clean_app_data.py          # Reset simulator state
│
└── reports/                     # Test execution reports
    ├── screenshots/             # Screenshots per test run
    └── *.md                     # Markdown test reports
```

### File Type Conventions

- **Base Scenarios** (`type: base`): Initial setup steps (e.g., first launch, master password)
- **State Definitions** (`type: state_definition`): Prepare app state with data
- **Test Scenarios** (`type: test`): Actual feature tests that verify behavior
- **Python Scripts**: State preparation utilities (return JSON config)
- **Reports**: Generated automatically during test execution

---

## Test Scenarios

The E2E test suite covers 7 comprehensive scenarios:

### 1. Base Setup (`base_setup.yaml`)
**Purpose**: First-time app installation and master password setup

**Steps**:
- Launch freshly installed app
- Verify setup password screen
- Enter and confirm master password
- Verify navigation to empty home screen

**Dependencies**: None
**Post-state**: `master_password_set`

---

### 2. Standard State (`standard_state.yaml`)
**Purpose**: Prepare consistent test state with sample data

**Preparation**: Runs `prepare_standard_state.py` to generate config

**Created Data**:
- 2 groups: Default (🔐), Work (💼)
- 3 passwords:
  - GitHub (Default)
  - Gmail (Default)
  - AWS Console (Work)

**Dependencies**: `base_setup`
**Post-state**: `standard_state`

---

### 3. Search Test (`search_test.yaml`)
**Purpose**: Verify search functionality across passwords

**Tests**:
- Search by title ("GitHub")
- Search by username ("gmail")
- Search by group ("Work")
- Empty search results
- Clear search

**Dependencies**: `standard_state`

---

### 4. Password CRUD Test (`password_crud_test.yaml`)
**Purpose**: Full lifecycle of password entries

**Tests**:
- Create new password with custom group
- View password details
- Edit password (change username/password)
- Delete password
- Verify deletion

**Dependencies**: `standard_state`

---

### 5. Groups Test (`groups_test.yaml`)
**Purpose**: Group management operations

**Tests**:
- Create new group with icon
- Assign password to group
- Edit group name/icon
- Delete group (with orphan handling)
- Verify group in password list

**Dependencies**: `standard_state`

---

### 6. WebDAV Test (`webdav_test.yaml`)
**Purpose**: Remote backup and restore via WebDAV

**Tests**:
- Configure WebDAV server credentials
- Backup passwords to WebDAV
- Verify backup file on server
- Clear local data
- Restore from WebDAV backup
- Verify restored passwords

**Dependencies**: `standard_state`
**Requirements**: WebDAV server credentials in environment variables

---

### 7. Export/Import Test (`export_import_test.yaml`)
**Purpose**: Local file export and import

**Tests**:
- Export passwords to .apwd file
- Verify export file creation
- Clear local data
- Import from .apwd file
- Enter import password
- Verify imported passwords

**Dependencies**: `standard_state`

---

## Quick Start

### Prerequisites

1. **Claude CLI** installed and configured
   ```bash
   # Install Claude CLI
   npm install -g @anthropic-ai/claude-cli

   # Configure API key
   claude config
   ```

2. **mobile-mcp server** installed
   ```bash
   # Install mobile-mcp
   npm install -g mobile-mcp

   # Verify installation
   mobile-mcp --version
   ```

3. **iOS Simulator** running
   ```bash
   # List available simulators
   xcrun simctl list devices

   # Boot simulator (if not running)
   xcrun simctl boot "iPhone 15"

   # Open Simulator app
   open -a Simulator
   ```

4. **APWD built for simulator**
   ```bash
   # Build app
   flutter build ios --simulator

   # Install on simulator
   xcrun simctl install booted build/ios/iphonesimulator/Runner.app
   ```

### Running Tests

#### Option 1: Interactive Script (Recommended)

```bash
cd tests/e2e
./run_tests.sh
```

Select from menu:
1. Search test
2. Password CRUD test
3. Groups test
4. WebDAV test
5. Export/Import test
6. All tests

#### Option 2: Direct Claude CLI

```bash
# Single scenario
claude -p "Execute E2E test scenario tests/e2e/scenarios/search_test.yaml"

# Multiple scenarios
claude -p "Execute E2E tests: search, password_crud, groups"

# Full test suite
claude -p "Run complete APWD E2E test suite and generate summary report"
```

#### Option 3: Manual Step-by-Step

```bash
# 1. Clean app data
python3 tests/e2e/utils/clean_app_data.py

# 2. Prepare standard state
python3 tests/e2e/utils/prepare_standard_state.py

# 3. Run specific test via Claude
claude -p "Run search test: tests/e2e/scenarios/search_test.yaml"
```

### Viewing Results

Test reports are generated in `tests/e2e/reports/`:

```bash
# View latest report
ls -lt tests/e2e/reports/*.md | head -1 | xargs cat

# View screenshots
open tests/e2e/reports/screenshots/
```

---

## Configuration

### Global Config (`config.yaml`)

```yaml
# Simulator settings
simulator:
  platform: "ios"
  device_id: "auto"        # Auto-detect or specific UUID
  device_name: "iPhone 15"
  os_version: "17.0"

# App settings
app:
  bundle_id: "com.apwd.app"
  build_path: "build/ios/iphonesimulator/Runner.app"
  launch_timeout: 30

# Claude AI settings
claude:
  model: "claude-sonnet-4-6"
  temperature: 0.0         # Deterministic for testing
  max_retries: 3

# Test reporting
reporting:
  output_dir: "tests/e2e/reports"
  screenshot_format: "png"
  screenshot_dir: "tests/e2e/reports/screenshots"
  save_video: false
  cleanup_screenshots_on_success: false

# Timeouts
timeouts:
  step_default: 30
  state_preparation: 120
  test_scenario: 300

# WebDAV testing (disabled by default for security)
webdav_test:
  enabled: false
  url: "${WEBDAV_TEST_URL}"
  username: "${WEBDAV_TEST_USER}"
  password: "${WEBDAV_TEST_PASSWORD}"
  remote_path: "/APWD_Test"
```

### Environment Variables

For WebDAV testing, set credentials:

```bash
export WEBDAV_TEST_URL="https://webdav.example.com"
export WEBDAV_TEST_USER="testuser"
export WEBDAV_TEST_PASSWORD="testpass"
```

### Scenario YAML Structure

```yaml
name: "Test Scenario Name"
description: "Detailed description of what this test verifies"
type: "test"  # base | state_definition | test

depends_on:
  - base_setup
  - standard_state

preconditions:
  - simulator_running: true
  - app_installed: true
  - app_state: "standard_state"

steps:
  - id: "step1"
    action: "tap_element"
    description: "Tap the search icon"
    params:
      element: "search_icon"
    timeout: 30
    retry_on_failure: 2
    expected:
      screen: "SearchScreen"
      elements: ["search_input_field"]

  - id: "step2"
    action: "enter_text"
    description: "Enter search query"
    params:
      field: "search_input"
      text: "GitHub"
    expected:
      results_count: 1
      first_result_title: "GitHub"

post_state:
  name: "search_completed"
  description: "Search test finished, app on search screen"
```

---

## Troubleshooting

### Common Issues

#### 1. Simulator Not Running

**Error**: `Simulator with name "iPhone 15" not found`

**Solution**:
```bash
# List available simulators
xcrun simctl list devices

# Boot specific simulator
xcrun simctl boot "iPhone 15"

# Or use device UUID
xcrun simctl boot 12345678-1234-1234-1234-123456789ABC
```

---

#### 2. WebDriverAgent Timeout (CRITICAL)

**Error**: `error starting agent: timed out waiting for WebDriverAgent to be ready`

**Root Cause**:
WebDriverAgent requires 10-15 seconds to initialize after simulator boot. This is a critical timing issue that will block all E2E tests if not handled properly.

**Solution**:
```bash
# CORRECT: Boot simulator and wait for WebDriverAgent
xcrun simctl boot "iPhone 16"
sleep 10  # Critical: Wait for WebDriverAgent initialization

# Verify WebDriverAgent is ready
mobile-mcp list-devices  # Should show device as "online"
```

**Best Practice**:
Always include a 10-15 second wait after booting the simulator before attempting any mobile-mcp operations. This wait time is required for:
- WebDriverAgent installation (first time)
- WebDriverAgent process startup
- Network connection establishment
- Device communication initialization

**In Automated Scripts**:
```bash
#!/bin/bash
# Ensure simulator is ready for testing

DEVICE_ID="72C2426F-C7BF-4DEF-83A6-148886362E99"

# Boot simulator
xcrun simctl boot "$DEVICE_ID"

# CRITICAL: Wait for WebDriverAgent initialization
echo "Waiting for WebDriverAgent to initialize..."
sleep 15  # Use 15 seconds for reliability

# Verify device is ready
if mobile-mcp list-devices | grep -q "online"; then
    echo "✓ Device ready for testing"
else
    echo "✗ Device not ready, waiting additional 10 seconds..."
    sleep 10
fi
```

**Configuration**:
Update `tests/e2e/config.yaml` to include initialization timeouts:
```yaml
simulator:
  boot_wait_time: 15  # Seconds to wait after boot
  webdriver_ready_timeout: 30  # Max time to wait for WebDriverAgent
```

---

#### 3. App Not Installed

**Error**: `App bundle not found at path`

**Solution**:
```bash
# Rebuild app for simulator
flutter clean
flutter build ios --simulator

# Verify build path
ls build/ios/iphonesimulator/Runner.app

# Install manually
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
```

---

#### 3. App Crashed During Test

**Error**: `App not responding`

**Solution**:
```bash
# Check crash logs
xcrun simctl spawn booted log show --predicate 'processImagePath contains "Runner"' --last 5m

# Restart app
xcrun simctl terminate booted com.apwd.app
xcrun simctl launch booted com.apwd.app

# Or clean and restart test
python3 tests/e2e/utils/clean_app_data.py
```

---

#### 4. Database State Corruption

**Error**: `Cannot prepare standard state`

**Solution**:
```bash
# Full reset of app container
xcrun simctl uninstall booted com.apwd.app
xcrun simctl install booted build/ios/iphonesimulator/Runner.app

# Clear app data
python3 tests/e2e/utils/clean_app_data.py

# Restart from base_setup
claude -p "Execute base_setup.yaml then standard_state.yaml"
```

---

#### 5. WebDAV Test Failing

**Error**: `WebDAV credentials not configured`

**Solution**:
```bash
# Set environment variables
export WEBDAV_TEST_URL="https://your-webdav.com"
export WEBDAV_TEST_USER="username"
export WEBDAV_TEST_PASSWORD="password"

# Enable WebDAV in config
# Edit config.yaml: webdav_test.enabled = true

# Verify connection
curl -u "$WEBDAV_TEST_USER:$WEBDAV_TEST_PASSWORD" "$WEBDAV_TEST_URL"
```

---

#### 6. Claude Not Finding Elements

**Error**: `Element "search_icon" not found on screen`

**Solution**:
1. Check screenshot in `tests/e2e/reports/screenshots/`
2. Verify UI element names in Flutter code
3. Add explicit wait/timeout in scenario YAML
4. Ensure previous step completed successfully

**Debug commands**:
```bash
# Take manual screenshot
xcrun simctl io booted screenshot debug.png

# Check if app is in foreground
xcrun simctl launch booted com.apwd.app
```

---

#### 7. Mobile-MCP Not Responding

**Error**: `Cannot connect to mobile-mcp server`

**Solution**:
```bash
# Verify mobile-mcp is running
ps aux | grep mobile-mcp

# Check Claude MCP configuration
cat ~/.claude/claude.json

# Restart mobile-mcp (if running as service)
killall mobile-mcp
mobile-mcp start

# Test mobile-mcp manually
echo '{"action": "list_devices"}' | mobile-mcp
```

---

### Debug Mode

Enable verbose logging:

```bash
# Run with debug output
APWD_E2E_DEBUG=1 claude -p "Run search_test.yaml"

# Python scripts verbose mode
python3 -v tests/e2e/utils/prepare_standard_state.py
```

---

## Extension Guide

### Adding New Test Scenarios

1. **Create Scenario YAML**

```yaml
# tests/e2e/scenarios/my_new_test.yaml
name: "My New Feature Test"
description: "Tests the new feature XYZ"
type: "test"

depends_on:
  - standard_state

steps:
  - id: "step1"
    action: "navigate_to_feature"
    description: "Open the new feature screen"
    expected:
      screen: "NewFeatureScreen"

  - id: "step2"
    action: "perform_action"
    description: "Execute feature action"
    expected:
      result: "success"
```

2. **Update `run_tests.sh`**

```bash
echo "  7. my_new_test - My New Feature"

# Add case
7) SCENARIO="my_new_test.yaml" ;;
```

3. **Test Locally**

```bash
claude -p "Execute E2E test: tests/e2e/scenarios/my_new_test.yaml"
```

---

### Adding New State Preparation Scripts

1. **Create Python Script**

```python
#!/usr/bin/env python3
# tests/e2e/utils/prepare_my_state.py

import json
import sys

def prepare_my_state():
    config = {
        "master_password": "TestPassword123!",
        "custom_data": {
            # Your test data
        }
    }

    print(json.dumps({"status": "success", "config": config}))
    sys.exit(0)

if __name__ == "__main__":
    try:
        prepare_my_state()
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
        sys.exit(1)
```

2. **Make Executable**

```bash
chmod +x tests/e2e/utils/prepare_my_state.py
```

3. **Reference in State YAML**

```yaml
# tests/e2e/scenarios/my_state.yaml
name: "My Custom State"
type: "state_definition"
preparation_script: "tests/e2e/utils/prepare_my_state.py"
```

---

### Adding New Actions

Claude dynamically interprets actions, but you can document common patterns:

**Navigation Actions**:
- `tap_element` - Tap specific UI element
- `swipe_up` / `swipe_down` - Scroll gestures
- `navigate_back` - Go back in navigation

**Input Actions**:
- `enter_text` - Type into text field
- `select_option` - Choose from dropdown/picker
- `toggle_switch` - Enable/disable toggle

**Verification Actions**:
- `verify_screen` - Check current screen
- `verify_element_visible` - Assert element exists
- `verify_text_contains` - Check text content
- `take_screenshot` - Capture current state

**Data Actions**:
- `create_password` - Add new password entry
- `delete_password` - Remove password entry
- `create_group` - Add new group

---

### Custom Assertions

Add expected results to any step:

```yaml
steps:
  - id: "verify_count"
    action: "count_passwords"
    expected:
      count: 3
      first_title: "GitHub"
      groups: ["Default", "Work"]

  - id: "verify_search"
    action: "search"
    params:
      query: "git"
    expected:
      results_count: 1
      results:
        - title: "GitHub"
          group: "Default"
```

---

### Integration with CI/CD

Example GitHub Actions workflow:

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e-test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Install Dependencies
        run: |
          npm install -g @anthropic-ai/claude-cli mobile-mcp
          flutter pub get

      - name: Build App
        run: flutter build ios --simulator

      - name: Start Simulator
        run: |
          xcrun simctl boot "iPhone 15"
          xcrun simctl install booted build/ios/iphonesimulator/Runner.app

      - name: Run E2E Tests
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          cd tests/e2e
          claude -p "Run complete APWD E2E test suite"

      - name: Upload Test Reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-reports
          path: tests/e2e/reports/
```

---

## Best Practices

1. **Test Independence**: Each scenario should be runnable independently
2. **Clean State**: Always start from known state (base_setup or standard_state)
3. **Descriptive Steps**: Write clear descriptions for debugging
4. **Visual Verification**: Screenshots are your debugging best friend
5. **Timeout Tuning**: Adjust timeouts based on app performance
6. **Error Handling**: Use `retry_on_failure` for flaky operations
7. **Documentation**: Update this README when adding scenarios

---

## Related Documentation

- [Main Testing Guide](/test/CLAUDE.md) - Overview of all test types
- [Flutter Integration Tests](https://docs.flutter.dev/testing/integration-tests)
- [Claude MCP Documentation](https://docs.anthropic.com/mcp)
- [mobile-mcp GitHub](https://github.com/anthropics/mobile-mcp)

---

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review test reports in `tests/e2e/reports/`
3. Examine screenshots for visual debugging
4. Check simulator logs: `xcrun simctl spawn booted log show --last 5m`

---

**Last Updated**: 2026-03-23
**Test System Version**: 1.0.0
**Claude Model**: claude-sonnet-4-6
