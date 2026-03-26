# APWD 测试结构整合方案

## 当前状态分析

### 现有测试文件和目录

#### 1. test/ (Flutter 标准测试目录)
```
test/
├── models/              # 2 tests - Model 单元测试
├── services/            # 24 tests - Service 单元测试
├── integration/         # 10 tests - Flutter 集成测试
│   ├── webdav_integration_test.dart   (5 tests)
│   └── webdav_full_e2e_test.dart      (5 tests)
└── ui/                  # 1 test - Flutter UI 集成测试
    └── app_test.dart    (5 scenarios)
```
- **总计**: 37 个 Flutter 测试
- **运行方式**: `flutter test`
- **特点**: 测试服务层逻辑，不涉及真实 UI 交互

#### 2. tests/ 目录
```
tests/
└── e2e/                 # Claude AI 驱动的 E2E 测试
    ├── scenarios/       # 7 个测试场景 YAML
    ├── utils/           # 3 个 Python 工具脚本
    ├── mock_webdav_server.py
    ├── webdav_manager.sh
    ├── run_tests.sh     # 测试启动脚本
    └── 文档 (README, MANIFEST, etc.)
```
- **特点**: 真实 iOS 模拟器 UI 测试，使用 mobile-mcp + Claude AI
- **运行方式**: `./run_tests.sh` (调用 claude CLI)

#### 3. 根目录测试脚本

**e2e_test.py** (389 lines, 7 tests)
- 基于 Selenium 的 **Web 端** E2E 测试
- 测试 Flutter Web 版本的完整用户流程
- 运行方式: `python e2e_test.py`

**autonomous_test_runner.py** (470 lines)
- iOS 模拟器自动化运行器
- 功能与 tests/e2e 重复，可能已过时

---

## 问题分析

### 1. 目录混乱
- `test/` 和 `tests/` 两个目录并存
- 根目录有独立的测试脚本

### 2. 命名重复
- `test/integration/webdav_full_e2e_test.dart` (Flutter 集成测试)
- `tests/e2e/` (真正的 E2E 测试)
- 容易混淆

### 3. 没有统一入口
- Flutter 测试: `flutter test`
- Mobile E2E: `cd tests/e2e && ./run_tests.sh`
- Web E2E: `python e2e_test.py`
- 各自独立运行

---

## 整合方案

### 新目录结构

```
test/
├── unit/                           # 单元测试
│   ├── models/                     # 从 test/models/ 移动
│   └── services/                   # 从 test/services/ 移动
│
├── integration/                    # Flutter 集成测试（保持不变）
│   ├── webdav_integration_test.dart
│   └── webdav_full_e2e_test.dart
│
├── e2e/                            # 端到端测试
│   ├── mobile/                     # 移动端 E2E（从 tests/e2e 移动）
│   │   ├── scenarios/
│   │   ├── utils/
│   │   ├── mock_webdav_server.py
│   │   ├── webdav_manager.sh
│   │   ├── config.yaml
│   │   ├── run_tests.sh
│   │   └── README.md
│   │
│   └── web/                        # Web E2E
│       ├── e2e_test.py            # 从根目录移动
│       └── README.md              # 新建
│
├── CLAUDE.md                       # 测试文档（保持）
└── run_tests.py                    # 统一测试入口（新建）
```

### 删除的文件
- `tests/` 目录（整体移除）
- `autonomous_test_runner.py`（功能已被 test/e2e/mobile 替代）
- `test_results/` 目录（使用 test/e2e/mobile/reports 统一管理）

---

## 测试分类对比

| 测试类型 | 位置 | 运行方式 | 测试内容 |
|---------|------|---------|----------|
| **单元测试** | test/unit/ | `flutter test test/unit` | Model/Service 单元测试 |
| **集成测试** | test/integration/ | `flutter test test/integration` | 服务间集成，不涉及 UI |
| **Mobile E2E** | test/e2e/mobile/ | `cd test/e2e/mobile && ./run_tests.sh` | iOS 模拟器真实 UI 测试 |
| **Web E2E** | test/e2e/web/ | `python test/e2e/web/e2e_test.py` | Web 浏览器真实 UI 测试 |

---

## 统一测试入口 (test/run_tests.py)

### 功能
```bash
# 运行所有测试
python test/run_tests.py --all

# 运行特定类型测试
python test/run_tests.py --unit          # 单元测试
python test/run_tests.py --integration   # 集成测试
python test/run_tests.py --e2e-mobile    # 移动端 E2E
python test/run_tests.py --e2e-web       # Web E2E

# 运行特定场景
python test/run_tests.py --e2e-mobile --scenario search_test
```

### 特性
- ✅ 统一入口，一个命令运行所有测试
- ✅ 支持选择性运行
- ✅ 生成统一测试报告
- ✅ 自动环境检查（Flutter, Python, Xcode, etc.）
- ✅ 彩色输出，清晰的测试结果

---

## 迁移步骤

### 1. 创建新目录结构
```bash
mkdir -p test/unit test/e2e/mobile test/e2e/web
```

### 2. 移动文件
```bash
# 移动单元测试
mv test/models test/unit/
mv test/services test/unit/

# 移动 Mobile E2E
mv tests/e2e/* test/e2e/mobile/

# 移动 Web E2E
mv e2e_test.py test/e2e/web/
```

### 3. 清理
```bash
# 删除旧目录
rm -rf tests/
rm -rf test_results/
rm autonomous_test_runner.py
```

### 4. 更新文档
- 更新 test/CLAUDE.md
- 更新 test/e2e/mobile/README.md (路径引用)
- 创建 test/e2e/web/README.md

### 5. 创建统一入口
- 创建 test/run_tests.py
- 更新根目录 CLAUDE.md 的测试说明

---

## 优势

### 1. 结构清晰
- ✅ 单一测试目录 `test/`
- ✅ 按测试类型分层：unit → integration → e2e
- ✅ 平台分离：mobile / web

### 2. 易于维护
- ✅ 测试分类明确
- ✅ 避免命名冲突
- ✅ 统一的文档结构

### 3. 开发者友好
- ✅ 一个命令运行所有测试
- ✅ 清晰的测试覆盖报告
- ✅ 符合 Flutter 项目规范

### 4. CI/CD 友好
- ✅ 易于配置 GitHub Actions
- ✅ 支持并行运行不同类型测试
- ✅ 统一的测试输出格式

---

## 测试覆盖率对比

### 整合前
- 单元测试: 26 tests (test/models + test/services)
- 集成测试: 10 tests (test/integration)
- UI 测试: 1 test (test/ui/app_test.dart)
- Mobile E2E: 7 scenarios (tests/e2e)
- Web E2E: 7 tests (e2e_test.py)
- **总计**: ~51 测试

### 整合后
- 单元测试: 26 tests (test/unit/)
- 集成测试: 10 tests (test/integration/)
- Mobile E2E: 7 scenarios (test/e2e/mobile/)
- Web E2E: 7 tests (test/e2e/web/)
- **总计**: ~50 测试（合并重复）

覆盖率: **~92%** (基于 E2E 测试完成报告)

---

## 建议执行顺序

1. ✅ **Review** - 确认方案
2. 📝 **Backup** - 创建分支 `feature/test-restructure`
3. 🚀 **Execute** - 执行迁移步骤
4. ✅ **Verify** - 运行所有测试确认无误
5. 📄 **Document** - 更新所有相关文档
6. 🎯 **Commit** - 提交并合并到主干

---

## 需要确认

- [ ] autonomous_test_runner.py 是否还需要？
- [ ] test_results/ 目录内容是否需要保留？
- [ ] test/ui/app_test.dart 保留在 integration/ 还是移到 e2e/mobile？

---

**创建日期**: 2026-03-26
**版本**: 1.0
**状态**: 待审核
