# Web E2E Tests

Selenium-based end-to-end tests for APWD's Flutter Web version.

## Overview

These tests verify the complete user workflows in a web browser, ensuring the Flutter Web version works correctly.

## Prerequisites

```bash
# Install Selenium
pip3 install selenium

# Install WebDriver (Chrome)
brew install --cask chromedriver
```

## Running Tests

### 1. Start Flutter Web App

```bash
# In project root
flutter run -d chrome
```

The app should be running at `http://localhost:53817` (default port).

### 2. Run Tests

```bash
# Run all tests
python3 test/e2e/web/e2e_test.py

# Run with custom URL
python3 test/e2e/web/e2e_test.py http://localhost:8080

# Run with custom output directory
python3 test/e2e/web/e2e_test.py http://localhost:53817 ./custom_reports
```

## Test Coverage

### 7 Test Scenarios

1. **Master Password Setup** - First-time password creation
2. **Add Password** - Create new password entry
3. **View Password Details** - Display password information
4. **Search** - Find passwords by title/username
5. **Edit Password** - Modify existing entry
6. **Delete Password** - Remove password entry
7. **Group Management** - Create and manage groups

## Output

### Reports Directory

```
test/e2e/web/reports/
├── screenshot_master_password_setup.png
├── screenshot_add_password.png
├── screenshot_view_details.png
├── screenshot_search.png
├── screenshot_edit_password.png
├── screenshot_delete_password.png
└── screenshot_group_management.png
```

### Console Output

The test runner prints colored output showing:
- ✅ Passed tests (green)
- ❌ Failed tests (red)
- Test execution time
- Final summary

## Configuration

Edit `e2e_test.py` to configure:

```python
class APWDTester:
    def __init__(self, url="http://localhost:53817", output_dir="."):
        self.url = url
        self.output_dir = Path(output_dir)
        self.test_password = "MySecureTestPassword123!"
```

## Troubleshooting

### App Not Running

**Error**: `Failed to connect to http://localhost:53817`

**Solution**:
```bash
# Ensure Flutter web is running
flutter run -d chrome

# Or manually start web server
flutter build web
cd build/web
python3 -m http.server 53817
```

### ChromeDriver Issues

**Error**: `selenium.common.exceptions.WebDriverException`

**Solution**:
```bash
# Reinstall chromedriver
brew reinstall chromedriver

# Allow chromedriver (macOS security)
xattr -d com.apple.quarantine /usr/local/bin/chromedriver
```

### Element Not Found

**Error**: `TimeoutException: Could not find element`

**Solution**:
- Check if app is loaded completely
- Increase timeout in `e2e_test.py`
- Verify element selectors haven't changed

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Web E2E Tests

on: [push, pull_request]

jobs:
  web-e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2

      - name: Install dependencies
        run: pip3 install selenium

      - name: Build web app
        run: flutter build web

      - name: Start web server
        run: |
          cd build/web
          python3 -m http.server 53817 &
          sleep 5

      - name: Run E2E tests
        run: python3 test/e2e/web/e2e_test.py
```

## Best Practices

1. **Run tests before releases** - Catch web-specific issues
2. **Check screenshots** - Visual debugging is invaluable
3. **Test on multiple browsers** - Modify script for Firefox/Safari
4. **Keep selectors flexible** - Use data attributes when possible

## Comparison with Mobile E2E

| Feature | Mobile E2E | Web E2E |
|---------|-----------|---------|
| Platform | iOS Simulator | Chrome Browser |
| Technology | Claude AI + mobile-mcp | Selenium |
| Test Definition | YAML | Python code |
| Speed | Slow (~2min) | Fast (~1min) |
| Maintenance | Low (AI adapts) | Medium (selectors) |

---

**Version**: 1.0
**Last Updated**: 2026-03-26
