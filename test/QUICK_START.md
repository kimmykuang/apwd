# APWD Tests - Quick Start

## 🚀 Run All Tests

```bash
python test/run_tests.py --all
```

## 📋 Run Specific Test Type

```bash
# Unit tests (fast, ~10s)
python test/run_tests.py --unit

# Integration tests (~30s)
python test/run_tests.py --integration

# Mobile E2E (slow, ~2min per scenario)
python test/run_tests.py --e2e-mobile

# Web E2E (~5min)
python test/run_tests.py --e2e-web

# Autonomous tests (~10min)
python test/run_tests.py --e2e-autonomous
```

## 🎯 Run Specific Mobile Scenario

```bash
python test/run_tests.py --e2e-mobile --scenario search_test
python test/run_tests.py --e2e-mobile --scenario webdav_test
```

## 📁 Test Structure

```
test/
├── unit/              # 26 unit tests
├── integration/       # 10 integration tests  
├── e2e/
│   ├── mobile/       # 7 AI-driven scenarios
│   ├── web/          # 7 Selenium tests
│   └── autonomous/   # Full automation
├── CLAUDE.md         # Complete documentation
└── run_tests.py      # Unified entry point
```

## 📊 Test Reports

All reports saved to:
- `test/unit/reports/`
- `test/integration/reports/`
- `test/e2e/mobile/reports/`
- `test/e2e/web/reports/`
- `test/e2e/autonomous/reports/`

## 📖 Full Documentation

See [test/CLAUDE.md](CLAUDE.md) for complete testing guide.

---

**Coverage**: ~92% | **Tests**: ~50
