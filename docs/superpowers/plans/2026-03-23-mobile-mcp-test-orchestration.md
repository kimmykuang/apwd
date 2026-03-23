# Mobile-MCP 测试编排系统实施计划

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 APWD 构建基于 mobile-mcp 的结构化 E2E 测试系统，使用 YAML 定义场景、Python 辅助脚本准备状态、Claude 执行和验证

**Architecture:** 三层架构 - Claude 作为智能编排层读取 YAML 场景，调用 Python 脚本准备确定性状态，使用 mobile-mcp 执行 UI 操作并视觉验证结果

**Tech Stack:** YAML (场景定义), Python 3 (辅助脚本), mobile-mcp (模拟器控制), Claude CLI (执行引擎)

---

## Chunk 1: 基础设施搭建

### Task 1: 创建目录结构

**Files:**
- Create: `tests/e2e/scenarios/`
- Create: `tests/e2e/utils/`
- Create: `tests/e2e/reports/`
- Create: `tests/e2e/reports/screenshots/`

- [ ] **Step 1: 创建 E2E 测试目录结构**

```bash
mkdir -p tests/e2e/scenarios
mkdir -p tests/e2e/utils
mkdir -p tests/e2e/reports/screenshots
```

- [ ] **Step 2: 创建 .gitkeep 文件保留空目录**

```bash
touch tests/e2e/reports/.gitkeep
touch tests/e2e/reports/screenshots/.gitkeep
```

- [ ] **Step 3: 验证目录结构**

Run: `ls -la tests/e2e/`
Expected: 显示 scenarios/, utils/, reports/ 三个目录

- [ ] **Step 4: Commit**

```bash
git add tests/e2e/
git commit -m "chore: create E2E test directory structure

Add directories for mobile-mcp test orchestration:
- scenarios/ for YAML test definitions
- utils/ for Python helper scripts
- reports/ for test results and screenshots"
```

---

### Task 2: 创建测试配置文件

**Files:**
- Create: `tests/e2e/config.yaml`

- [ ] **Step 1: 创建 config.yaml 配置文件**

```yaml
# tests/e2e/config.yaml
# APWD E2E 测试全局配置

# 模拟器配置
simulator:
  platform: "ios"
  device_id: "auto"  # "auto" 自动查找，或具体 UUID
  device_name: "iPhone 15"
  os_version: "17.0"

# 应用配置
app:
  bundle_id: "com.apwd.app"
  build_path: "build/ios/iphonesimulator/Runner.app"
  launch_timeout: 30

# Claude 配置
claude:
  model: "claude-sonnet-4-6"
  temperature: 0.0
  max_retries: 3

# 测试报告配置
reporting:
  output_dir: "tests/e2e/reports"
  screenshot_format: "png"
  screenshot_dir: "tests/e2e/reports/screenshots"
  save_video: false
  cleanup_screenshots_on_success: false

# 超时配置
timeouts:
  step_default: 30
  state_preparation: 120
  test_scenario: 300

# WebDAV 测试配置
webdav_test:
  enabled: false  # 默认禁用以保证安全，执行 webdav_test.yaml 前需手动启用或设置环境变量
  url: "${WEBDAV_TEST_URL}"
  username: "${WEBDAV_TEST_USER}"
  password: "${WEBDAV_TEST_PASSWORD}"
  remote_path: "/APWD_Test"

# 错误处理策略
error_handling:
  simulator_not_running:
    action: "start_simulator"
    command: "xcrun simctl boot {device_id}"
    retry: true

  app_not_installed:
    action: "install_app"
    command: "xcrun simctl install {device_id} {build_path}"
    retry: true
    on_failure_abort: true

  app_crashed:
    action: "relaunch_app"
    command: "xcrun simctl launch {device_id} {bundle_id}"
    retry: true
    max_retries: 3

# 命名约定
naming:
  screenshot_pattern: "{scenario}_{step}_{timestamp}.png"
  report_pattern: "{scenario}_{timestamp}.md"
```

- [ ] **Step 2: 验证 YAML 语法**

Run: `python3 -c "import yaml; yaml.safe_load(open('tests/e2e/config.yaml'))"`
Expected: 无错误输出

- [ ] **Step 3: Commit**

```bash
git add tests/e2e/config.yaml
git commit -m "feat: add E2E test configuration file

Add config.yaml with:
- Simulator and app configuration
- Timeout settings
- Error handling strategies
- Report naming conventions"
```

---

### Task 3: 创建标准状态准备脚本

**Files:**
- Create: `tests/e2e/utils/prepare_standard_state.py`

- [ ] **Step 1: 创建 prepare_standard_state.py 脚本**

```python
#!/usr/bin/env python3
"""
准备标准测试状态

功能：
- 生成测试数据配置 JSON
- 返回标准格式的 JSON 响应
- Claude 读取配置后通过 UI 创建数据

注意：不直接操作加密数据库，而是提供配置让 Claude 执行创建
"""
import json
import sys


def prepare_standard_state():
    """混合模式：Python 生成配置，Claude 执行创建"""

    # 注意：模拟器管理由 Claude 通过 config.yaml 处理
    # 此脚本仅负责生成测试数据配置

    # 返回测试数据配置
    # 注意：Default 分组由应用初始化时自动创建，此处仅创建额外的 Work 分组
    config = {
        "master_password": "TestPassword123!",
        "groups": [
            {"name": "Work", "icon": "💼"}
        ],
        "passwords": [
            {
                "title": "GitHub",
                "username": "test@github.com",
                "password": "GitHubPass123!",
                "group": "Default"
            },
            {
                "title": "Gmail",
                "username": "test@gmail.com",
                "password": "GmailPass123!",
                "group": "Default"
            },
            {
                "title": "AWS Console",
                "username": "test@aws.com",
                "password": "AWSPass123!",
                "group": "Work"
            }
        ]
    }

    print(json.dumps({"status": "success", "config": config}))
    sys.exit(0)


if __name__ == "__main__":
    try:
        prepare_standard_state()
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
        sys.exit(1)
```

- [ ] **Step 2: 添加执行权限**

```bash
chmod +x tests/e2e/utils/prepare_standard_state.py
```

- [ ] **Step 3: 测试脚本执行**

Run: `python3 tests/e2e/utils/prepare_standard_state.py`
Expected: 输出 JSON 格式，status 为 success，包含 config 字段

- [ ] **Step 4: 验证 JSON 格式**

```bash
python3 tests/e2e/utils/prepare_standard_state.py | python3 -m json.tool
```
Expected: 格式化的 JSON，包含 master_password, groups, passwords

- [ ] **Step 5: Commit**

```bash
git add tests/e2e/utils/prepare_standard_state.py
git commit -m "feat: add standard state preparation script

Add Python script to generate test data configuration:
- Master password: TestPassword123!
- 2 groups: Default, Work
- 3 passwords: GitHub, Gmail, AWS Console

Returns JSON for Claude to create data via UI"
```

---

### Task 4: 创建应用数据清理脚本

**Files:**
- Create: `tests/e2e/utils/clean_app_data.py`

- [ ] **Step 1: 创建 clean_app_data.py 脚本**

```python
#!/usr/bin/env python3
"""
清理应用数据

功能：
- 卸载并重新安装应用以清空数据
- 用于测试场景间的状态隔离

使用：python3 clean_app_data.py <device_id>
"""
import subprocess
import sys
import json


def clean_app_data(device_id, bundle_id="com.apwd.app"):
    """卸载并重新安装应用"""
    try:
        # 卸载应用
        subprocess.run([
            "xcrun", "simctl", "uninstall",
            device_id, bundle_id
        ], check=True)

        # 重新安装（需要提供 .app 路径）
        app_path = "build/ios/iphonesimulator/Runner.app"
        subprocess.run([
            "xcrun", "simctl", "install",
            device_id, app_path
        ], check=True)

        print(json.dumps({"status": "success"}))
        sys.exit(0)

    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    device_id = sys.argv[1] if len(sys.argv) > 1 else None
    if not device_id:
        print(json.dumps({"status": "error", "message": "Missing device_id"}))
        sys.exit(1)
    clean_app_data(device_id)
```

- [ ] **Step 2: 添加执行权限**

```bash
chmod +x tests/e2e/utils/clean_app_data.py
```

- [ ] **Step 3: 验证脚本语法**

Run: `python3 -m py_compile tests/e2e/utils/clean_app_data.py`
Expected: 无错误（编译通过）

- [ ] **Step 4: 测试错误处理（无参数）**

Run: `python3 tests/e2e/utils/clean_app_data.py`
Expected: 输出 JSON，status 为 error，message 为 "Missing device_id"

- [ ] **Step 5: Commit**

```bash
git add tests/e2e/utils/clean_app_data.py
git commit -m "feat: add app data cleanup script

Add script to uninstall and reinstall app:
- Clears all app data
- Used for test isolation
- Returns standard JSON response"
```

---

### Task 5: 创建首次安装场景

**Files:**
- Create: `tests/e2e/scenarios/base_setup.yaml`

- [ ] **Step 1: 创建 base_setup.yaml 场景定义**

```yaml
# tests/e2e/scenarios/base_setup.yaml
name: "首次安装设置主密码"
description: "全新安装 APWD，完成主密码设置流程"
type: "base"

preconditions:
  - simulator_running: true
  - app_installed: true
  - app_state: "fresh_install"

steps:
  - id: "step1"
    action: "verify_initial_screen"
    description: "验证首次启动显示设置密码页面"
    expected:
      screen: "SetupPasswordScreen"
      elements: ["密码输入框", "确认密码输入框", "Create Password按钮"]

  - id: "step2"
    action: "enter_master_password"
    description: "输入主密码和确认密码"
    params:
      password: "TestPassword123!"
    timeout: 30
    retry_on_failure: 2
    fallback:
      - "截图当前界面，检查是否有输入框可见"
      - "如果界面不正确，重启应用并重试"
    expected:
      both_fields_filled: true

  - id: "step3"
    action: "tap_create_button"
    description: "点击 Create Password 按钮"
    expected:
      navigation: "HomeScreen"
      message: "No passwords yet"

post_state:
  name: "master_password_set"
  description: "主密码已设置，进入空白主页面"
```

- [ ] **Step 2: 验证 YAML 语法**

Run: `python3 -c "import yaml; yaml.safe_load(open('tests/e2e/scenarios/base_setup.yaml'))"`
Expected: 无错误

- [ ] **Step 3: 检查场景完整性**

验证必填字段存在：
- name, description, type
- steps 包含 id, action, description, expected
- post_state 定义清晰

- [ ] **Step 4: Commit**

```bash
git add tests/e2e/scenarios/base_setup.yaml
git commit -m "feat: add base setup test scenario

Add first-time installation scenario:
- Verify SetupPasswordScreen appears
- Enter master password twice
- Create password and verify HomeScreen
- Post state: master_password_set"
```

---

### Task 6: 创建标准状态场景

**Files:**
- Create: `tests/e2e/scenarios/standard_state.yaml`

- [ ] **Step 1: 创建 standard_state.yaml 场景定义**

```yaml
# tests/e2e/scenarios/standard_state.yaml
name: "标准测试状态"
description: "主密码已设置，包含3个测试密码和2个分组"
type: "state_definition"

depends_on:
  - base_setup

preparation_script: "tests/e2e/utils/prepare_standard_state.py"

expected_state:
  groups:
    - id: 1
      name: "Default"
      icon: "🔐"
    - id: 2
      name: "Work"
      icon: "💼"

  passwords:
    - title: "GitHub"
      username: "test@github.com"
      password: "GitHubPass123!"
      group: "Default"
    - title: "Gmail"
      username: "test@gmail.com"
      password: "GmailPass123!"
      group: "Default"
    - title: "AWS Console"
      username: "test@aws.com"
      password: "AWSPass123!"
      group: "Work"

verification_steps:
  - "打开应用，应该直接在主页面（已解锁状态）"
  - "主页面显示3个密码条目"
  - "分组列表包含 Default 和 Work 两个分组"

post_state:
  name: "standard_state"
  description: "标准测试状态已准备"
```

- [ ] **Step 2: 验证 YAML 语法**

Run: `python3 -c "import yaml; yaml.safe_load(open('tests/e2e/scenarios/standard_state.yaml'))"`
Expected: 无错误

- [ ] **Step 3: 验证依赖的 Python 脚本存在且可执行**

Run: `ls -l tests/e2e/utils/prepare_standard_state.py`
Expected: 文件存在且有执行权限 (-rwxr-xr-x)

- [ ] **Step 4: Commit**

```bash
git add tests/e2e/scenarios/standard_state.yaml
git commit -m "feat: add standard state definition scenario

Add standard test state preparation:
- Depends on base_setup
- Uses prepare_standard_state.py script
- Creates 3 passwords in 2 groups
- Defines expected state for verification"
```

---

## Chunk 2: 核心测试场景

### Task 7: 创建搜索功能测试场景

**Files:**
- Create: `tests/e2e/scenarios/search_test.yaml`

- [ ] **Step 1: 创建 search_test.yaml 场景定义**

```yaml
# tests/e2e/scenarios/search_test.yaml
name: "搜索密码功能测试"
description: "验证搜索功能能正确找到已存在的密码"
type: "test"
requires_state: "standard_state"

steps:
  - id: "search_existing"
    action: "search_password"
    description: "搜索已存在的密码 GitHub"
    params:
      query: "GitHub"
    timeout: 30
    retry_on_failure: 2
    expected:
      found: true
      result_count: 1
      first_result_title: "GitHub"

  - id: "view_details"
    action: "tap_search_result"
    description: "点击搜索结果进入详情页"
    params:
      index: 0
    expected:
      screen: "PasswordDetailScreen"
      title: "GitHub"
      username: "test@github.com"

  - id: "search_nonexistent"
    action: "go_back_and_search"
    description: "返回主页，搜索不存在的密码"
    params:
      query: "NonExistent"
    expected:
      found: false
      message: "No results found"

success_criteria:
  - "所有步骤的 expected 条件都满足"
  - "每步都有截图记录"
  - "无异常或崩溃"
```

- [ ] **Step 2: 验证 YAML 语法**

Run: `python3 -c "import yaml; yaml.safe_load(open('tests/e2e/scenarios/search_test.yaml'))"`
Expected: 无错误

- [ ] **Step 3: 验证场景依赖链**

检查：requires_state: "standard_state" → depends_on: base_setup
依赖链完整

- [ ] **Step 4: Commit**

```bash
git add tests/e2e/scenarios/search_test.yaml
git commit -m "feat: add search functionality test scenario

Add comprehensive search test:
- Search existing password (GitHub)
- View password details
- Search nonexistent password
- Verify error messages and UI states"
```

---

### Task 8: 创建密码 CRUD 测试场景

**Files:**
- Create: `tests/e2e/scenarios/password_crud_test.yaml`

- [ ] **Step 1: 创建 password_crud_test.yaml 场景定义**

```yaml
# tests/e2e/scenarios/password_crud_test.yaml
name: "密码条目 CRUD 操作"
description: "测试添加、编辑、删除密码的完整流程"
type: "test"
requires_state: "standard_state"

steps:
  - id: "add_password"
    action: "add_new_password"
    description: "添加新密码 Twitter"
    params:
      title: "Twitter"
      username: "test@twitter.com"
      password: "TwitterPass123!"
      group: "Default"
    expected:
      save_success: true
      appears_in_list: true

  - id: "edit_password"
    action: "edit_password"
    description: "编辑 Twitter 密码的用户名"
    params:
      title: "Twitter"
      new_username: "newemail@twitter.com"
    expected:
      save_success: true

  - id: "view_edited"
    action: "view_password_details"
    description: "查看详情验证修改成功"
    params:
      title: "Twitter"
    expected:
      username: "newemail@twitter.com"

  - id: "delete_password"
    action: "delete_password"
    description: "删除 Twitter 密码"
    params:
      title: "Twitter"
    expected:
      delete_success: true
      not_in_list: true

  # 边界情况测试
  - id: "edge_empty_title"
    action: "add_password_with_validation"
    description: "测试空标题的验证"
    params:
      title: ""
      username: "test@example.com"
      password: "Pass123!"
    expected:
      save_failed: true
      error_message: "Please enter a title"

  - id: "edge_special_chars"
    action: "add_password_special_chars"
    description: "测试特殊字符"
    params:
      title: "Test<>\"'&"
      password: "!@#$%^&*()"
    expected:
      save_success: true
      display_correct: true

success_criteria:
  - "CRUD 操作全部成功"
  - "边界情况正确处理"
  - "UI 反馈准确"
```

- [ ] **Step 2: 验证 YAML 语法**

Run: `python3 -c "import yaml; yaml.safe_load(open('tests/e2e/scenarios/password_crud_test.yaml'))"`
Expected: 无错误

- [ ] **Step 3: Commit**

```bash
git add tests/e2e/scenarios/password_crud_test.yaml
git commit -m "feat: add password CRUD test scenario

Add comprehensive CRUD testing:
- Create new password (Twitter)
- Edit password username
- View edited details
- Delete password
- Edge cases: empty title, special characters"
```

---

### Task 9: 创建分组管理测试场景

**Files:**
- Create: `tests/e2e/scenarios/groups_test.yaml`

- [ ] **Step 1: 创建 groups_test.yaml 场景定义**

```yaml
# tests/e2e/scenarios/groups_test.yaml
name: "分组管理"
description: "测试创建、编辑、删除分组以及密码分组归属"
type: "test"
requires_state: "standard_state"

steps:
  - id: "create_group"
    action: "create_new_group"
    description: "创建新分组 Personal"
    params:
      name: "Personal"
      icon: "💙"
    expected:
      create_success: true
      appears_in_list: true

  - id: "move_password"
    action: "move_password_to_group"
    description: "将 Gmail 移动到 Personal 分组"
    params:
      password_title: "Gmail"
      target_group: "Personal"
    expected:
      move_success: true
      password_in_new_group: true

  - id: "edit_group_name"
    action: "edit_group"
    description: "编辑分组名称为 Private"
    params:
      old_name: "Personal"
      new_name: "Private"
    expected:
      edit_success: true
      name_updated: true

  - id: "delete_empty_group"
    action: "delete_group"
    description: "删除空分组 Work"
    precondition:
      - "先将 AWS Console 移到 Default 分组"
    params:
      group_name: "Work"
    expected:
      delete_success: true
      not_in_list: true

  - id: "cannot_delete_nonempty"
    action: "try_delete_nonempty_group"
    description: "验证无法删除有密码的分组"
    params:
      group_name: "Default"
    expected:
      delete_failed: true
      error_shown: true

success_criteria:
  - "分组 CRUD 操作成功"
  - "密码移动功能正常"
  - "防止删除非空分组"
```

- [ ] **Step 2: 验证 YAML 语法**

Run: `python3 -c "import yaml; yaml.safe_load(open('tests/e2e/scenarios/groups_test.yaml'))"`
Expected: 无错误

- [ ] **Step 3: Commit**

```bash
git add tests/e2e/scenarios/groups_test.yaml
git commit -m "feat: add groups management test scenario

Add group management testing:
- Create new group (Personal)
- Move password between groups
- Edit group name
- Delete empty group
- Prevent deletion of non-empty group"
```

---

### Task 10: 创建 WebDAV 备份恢复测试场景

**Files:**
- Create: `tests/e2e/scenarios/webdav_test.yaml`

- [ ] **Step 1: 创建 webdav_test.yaml 场景定义**

```yaml
# tests/e2e/scenarios/webdav_test.yaml
name: "WebDAV 备份和恢复"
description: "测试 WebDAV 远程备份和恢复功能"
type: "test"
requires_state: "standard_state"

preconditions:
  webdav_server:
    check: "curl -I ${WEBDAV_TEST_URL}"
    on_failure: "skip_test_with_message"
    message: "WebDAV 服务器不可达，跳过此测试"

steps:
  - id: "configure_webdav"
    action: "setup_webdav_settings"
    description: "配置 WebDAV 设置"
    params:
      url: "${WEBDAV_TEST_URL}"
      username: "${WEBDAV_TEST_USER}"
      password: "${WEBDAV_TEST_PASSWORD}"
      remote_path: "/APWD_Test"
    expected:
      settings_saved: true

  - id: "test_connection"
    action: "test_webdav_connection"
    description: "测试 WebDAV 连接"
    timeout: 45
    expected:
      connection_success: true
      message: "Connected successfully"

  - id: "backup_to_webdav"
    action: "backup_to_webdav"
    description: "执行 WebDAV 备份"
    params:
      encryption_password: "BackupPass123!"
    expected:
      backup_success: true
      message: "Backup completed"

  - id: "clear_local_data"
    action: "clear_app_data"
    description: "清空本地数据库"
    script: "tests/e2e/utils/clean_app_data.py"
    expected:
      data_cleared: true

  - id: "restore_from_webdav"
    action: "restore_from_webdav"
    description: "从 WebDAV 恢复数据"
    params:
      encryption_password: "BackupPass123!"
    expected:
      restore_success: true
      password_count: 3

  - id: "verify_restored_data"
    action: "verify_passwords"
    description: "验证恢复的密码"
    expected:
      passwords:
        - title: "GitHub"
        - title: "Gmail"
        - title: "AWS Console"

success_criteria:
  - "WebDAV 连接成功"
  - "备份上传成功"
  - "恢复数据完整"
```

- [ ] **Step 2: 验证 YAML 语法**

Run: `python3 -c "import yaml; yaml.safe_load(open('tests/e2e/scenarios/webdav_test.yaml'))"`
Expected: 无错误

- [ ] **Step 3: 添加注释说明前置条件**

在文件开头添加注释：
```yaml
# 注意：此测试需要 WebDAV 服务器运行
# 设置环境变量：WEBDAV_TEST_URL, WEBDAV_TEST_USER, WEBDAV_TEST_PASSWORD
# 或在 config.yaml 的 webdav_test 部分配置
```

- [ ] **Step 4: Commit**

```bash
git add tests/e2e/scenarios/webdav_test.yaml
git commit -m "feat: add WebDAV backup/restore test scenario

Add WebDAV testing:
- Configure WebDAV settings
- Test connection
- Backup to remote server
- Clear local data
- Restore from WebDAV
- Verify data integrity

Requires WebDAV server environment variables"
```

---

### Task 11: 创建导出导入测试场景

**Files:**
- Create: `tests/e2e/scenarios/export_import_test.yaml`

- [ ] **Step 1: 创建 export_import_test.yaml 场景定义**

```yaml
# tests/e2e/scenarios/export_import_test.yaml
name: "本地导出和导入"
description: "测试本地备份文件的导出和导入功能"
type: "test"
requires_state: "standard_state"

steps:
  - id: "export_backup"
    action: "export_to_file"
    description: "导出备份到本地文件"
    params:
      encryption_password: "BackupPass123!"
    expected:
      export_success: true
      file_generated: true
      file_pattern: "apwd_backup_*.apwd"

  - id: "verify_file_exists"
    action: "check_file_exists"
    description: "验证 .apwd 文件已生成"
    expected:
      file_exists: true
      file_size_gt: 0

  - id: "clear_local_data"
    action: "clear_app_data"
    description: "清空本地数据库"
    script: "tests/e2e/utils/clean_app_data.py"
    expected:
      data_cleared: true

  - id: "import_backup"
    action: "import_from_file"
    description: "从本地文件导入备份"
    params:
      file_path: "${EXPORTED_FILE_PATH}"
      encryption_password: "BackupPass123!"
    expected:
      import_success: true
      message: "Import completed"

  - id: "verify_passwords_restored"
    action: "verify_password_list"
    description: "验证密码已恢复"
    expected:
      password_count: 3
      titles: ["GitHub", "Gmail", "AWS Console"]

  - id: "verify_password_details"
    action: "verify_each_password"
    description: "验证每个密码的详细信息"
    passwords:
      - title: "GitHub"
        username: "test@github.com"
        group: "Default"
      - title: "Gmail"
        username: "test@gmail.com"
        group: "Default"
      - title: "AWS Console"
        username: "test@aws.com"
        group: "Work"
    expected:
      all_details_correct: true

  - id: "cleanup"
    action: "delete_backup_file"
    description: "清理测试生成的备份文件"
    params:
      file_path: "${EXPORTED_FILE_PATH}"
    expected:
      file_deleted: true

success_criteria:
  - "导出生成 .apwd 文件"
  - "导入恢复所有数据"
  - "数据内容准确无误"
  - "测试文件已清理"
```

- [ ] **Step 2: 验证 YAML 语法**

Run: `python3 -c "import yaml; yaml.safe_load(open('tests/e2e/scenarios/export_import_test.yaml'))"`
Expected: 无错误

- [ ] **Step 3: Commit**

```bash
git add tests/e2e/scenarios/export_import_test.yaml
git commit -m "feat: add export/import test scenario

Add local backup testing:
- Export to .apwd file
- Verify file generation
- Clear local data
- Import from file
- Verify data restoration
- Cleanup test files"
```

---

## Chunk 3: 辅助工具和文档

### Task 12: 创建便捷启动脚本

**Files:**
- Create: `tests/e2e/run_tests.sh`

- [ ] **Step 1: 创建 run_tests.sh 脚本**

```bash
#!/bin/bash
# tests/e2e/run_tests.sh
# APWD E2E 测试便捷启动脚本

set -e

echo "🚀 启动 APWD E2E 测试"
echo ""
echo "可选场景："
echo "  1. search_test - 搜索功能"
echo "  2. password_crud_test - 密码 CRUD"
echo "  3. groups_test - 分组管理"
echo "  4. webdav_test - WebDAV 备份"
echo "  5. export_import_test - 导出导入"
echo "  6. all - 执行所有测试"
echo ""
read -p "请选择 (1-6): " choice

case $choice in
  1) SCENARIO="search_test.yaml" ;;
  2) SCENARIO="password_crud_test.yaml" ;;
  3) SCENARIO="groups_test.yaml" ;;
  4) SCENARIO="webdav_test.yaml" ;;
  5) SCENARIO="export_import_test.yaml" ;;
  6) SCENARIO="all" ;;
  *) echo "无效选择"; exit 1 ;;
esac

if [ "$SCENARIO" = "all" ]; then
  PROMPT="执行 APWD 完整 E2E 测试套件，生成汇总报告"
else
  PROMPT="执行测试场景 tests/e2e/scenarios/$SCENARIO"
fi

echo ""
echo "📱 正在启动测试..."
echo ""

# 调用 Claude CLI
claude -p "$PROMPT"
```

- [ ] **Step 2: 添加执行权限**

```bash
chmod +x tests/e2e/run_tests.sh
```

- [ ] **Step 3: 测试脚本语法**

Run: `bash -n tests/e2e/run_tests.sh`
Expected: 无语法错误

- [ ] **Step 4: Commit**

```bash
git add tests/e2e/run_tests.sh
git commit -m "feat: add E2E test convenience script

Add interactive script to launch tests:
- Menu selection for test scenarios
- Calls Claude CLI with appropriate prompt
- Supports individual or batch execution"
```

---

### Task 13: 创建 E2E 测试文档

**Files:**
- Create: `tests/e2e/README.md`

- [ ] **Step 1: 创建 README.md 文档**

```markdown
# APWD E2E 测试系统

基于 mobile-mcp 的结构化端到端测试框架。

## 架构

三层设计：
- **Claude**: 智能编排层，读取 YAML、调用脚本、执行测试、生成报告
- **Python**: 辅助脚本，准备确定性状态
- **mobile-mcp**: 模拟器控制和 UI 操作

## 目录结构

```
tests/e2e/
├── scenarios/       # YAML 测试场景定义
├── utils/           # Python 辅助脚本
├── reports/         # 测试报告输出
├── config.yaml      # 全局配置
└── run_tests.sh     # 便捷启动脚本
```

## 测试场景

1. **base_setup.yaml** - 首次安装设置主密码
2. **standard_state.yaml** - 标准测试状态准备
3. **search_test.yaml** - 搜索功能测试
4. **password_crud_test.yaml** - 密码 CRUD 操作
5. **groups_test.yaml** - 分组管理
6. **webdav_test.yaml** - WebDAV 备份恢复
7. **export_import_test.yaml** - 本地导出导入

## 快速开始

### 前置条件

1. 安装并配置 mobile-mcp
2. 启动 iOS 模拟器
3. 安装 APWD 应用到模拟器

### 执行单个测试

```bash
# 方式1：使用便捷脚本
./tests/e2e/run_tests.sh

# 方式2：直接使用 Claude CLI
claude -p "执行测试场景 tests/e2e/scenarios/search_test.yaml"
```

### 执行完整测试套件

```bash
claude -p "执行 APWD 完整 E2E 测试套件"
```

## 配置

编辑 `tests/e2e/config.yaml` 配置：
- 模拟器设备 ID
- 应用 bundle ID
- 超时时间
- WebDAV 服务器（可选）

## 测试报告

测试报告保存在 `tests/e2e/reports/`：
- Markdown 格式报告
- 截图保存在 `screenshots/` 子目录
- 每个场景生成独立报告

## WebDAV 测试

WebDAV 测试需要配置环境变量：

```bash
export WEBDAV_TEST_URL="https://webdav.test.local"
export WEBDAV_TEST_USER="testuser"
export WEBDAV_TEST_PASSWORD="testpass"
```

或在 `config.yaml` 中设置。

## 故障排除

### 模拟器未运行

```bash
# 启动模拟器
open -a Simulator

# 或使用脚本
./scripts/start_simulator.sh
```

### 应用未安装

```bash
# 构建并安装
flutter build ios --simulator
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
```

### Python 脚本错误

```bash
# 测试脚本
python3 tests/e2e/utils/prepare_standard_state.py

# 应该输出 JSON 格式的配置
```

## 扩展测试场景

1. 创建新的 YAML 文件在 `scenarios/`
2. 定义场景元数据和步骤
3. 指定依赖状态 (`requires_state`)
4. 添加到 `run_tests.sh` 菜单（可选）

参考现有场景文件格式。

## 参考文档

- [设计规范](../../docs/superpowers/specs/2026-03-23-mobile-mcp-orchestration-design.md)
- [mobile-mcp 设置](../../docs/MOBILE_MCP_SETUP.md)
- [APWD 测试策略](../CLAUDE.md)
```

- [ ] **Step 2: 验证文档格式**

Run: `cat tests/e2e/README.md | head -20`
Expected: 显示文档开头内容

- [ ] **Step 3: Commit**

```bash
git add tests/e2e/README.md
git commit -m "docs: add E2E test system README

Add comprehensive documentation:
- Architecture overview
- Directory structure
- Quick start guide
- Configuration instructions
- Troubleshooting tips
- Extending test scenarios"
```

---

### Task 14: 更新项目根目录文档

**Files:**
- Modify: `test/CLAUDE.md`

- [ ] **Step 0: 验证文件存在**

Run: `ls -l test/CLAUDE.md`
Expected: 文件存在

- [ ] **Step 1: 在 test/CLAUDE.md 中添加 E2E 测试部分**

在文档末尾添加：

```markdown
---

## E2E 测试 (Mobile-MCP)

### 目的

使用 mobile-mcp 进行真实模拟器上的端到端测试，验证完整用户流程。

### 位置

`test/e2e/` - 基于 YAML 场景定义的结构化测试

### 测试类型

- **场景测试**: 验证完整用户旅程（搜索、CRUD、分组、备份等）
- **视觉验证**: AI 判断 UI 元素和状态
- **跨功能测试**: WebDAV 备份、导出导入等集成功能

### 执行方式

```bash
# 交互式选择
./tests/e2e/run_tests.sh

# 直接执行
claude -p "执行测试场景 tests/e2e/scenarios/search_test.yaml"

# 完整套件
claude -p "执行 APWD 完整 E2E 测试套件"
```

### 架构特点

- **YAML 场景定义**: 声明式测试步骤
- **Python 辅助脚本**: 准备确定性状态
- **Claude 智能编排**: 执行、判断、验证、报告

### 与传统测试的关系

| 测试类型 | 用途 | 工具 | 执行频率 |
|---------|------|------|---------|
| 单元测试 | 验证业务逻辑 | Flutter Test | 每次提交 |
| 集成测试 | 验证服务交互 | Flutter Test | 每次提交 |
| UI 测试 | 验证核心流程 | Flutter Test | 提交前 |
| E2E 测试 | 验证真实用户体验 | mobile-mcp | 发布前/手动 |

详见 [E2E 测试文档](e2e/README.md)
```

- [ ] **Step 2: 验证修改后的文档**

Run: `tail -50 test/CLAUDE.md`
Expected: 显示新添加的 E2E 测试部分

- [ ] **Step 3: Commit**

```bash
git add test/CLAUDE.md
git commit -m "docs: add E2E testing section to test documentation

Link to new E2E test system:
- Describe mobile-mcp based testing
- Explain relationship with existing tests
- Provide usage examples"
```

---

### Task 15: 验证完整系统集成

**Files:**
- Verify: 所有文件和配置

- [ ] **Step 1: 检查目录结构完整性**

```bash
ls -la tests/e2e/scenarios/
ls -la tests/e2e/utils/
ls -la tests/e2e/reports/
ls tests/e2e/config.yaml
ls tests/e2e/run_tests.sh
ls tests/e2e/README.md
```

Expected: 所有文件和目录都存在

- [ ] **Step 2: 验证所有 YAML 场景语法**

```bash
for file in tests/e2e/scenarios/*.yaml; do
  if [ -f "$file" ]; then
    echo "Checking $file..."
    python3 -c "import yaml; yaml.safe_load(open('$file'))"
  fi
done
```

Expected: 所有文件无语法错误

- [ ] **Step 3: 测试所有 Python 脚本**

```bash
# 测试 prepare_standard_state.py
python3 tests/e2e/utils/prepare_standard_state.py | python3 -m json.tool

# 测试 clean_app_data.py (无参数应返回错误)
python3 tests/e2e/utils/clean_app_data.py || echo "Expected error - OK"
```

Expected:
- prepare_standard_state.py 输出格式化的 JSON
- clean_app_data.py 返回错误信息

- [ ] **Step 4: 验证场景依赖关系**

手动检查：
- standard_state.yaml depends_on: [base_setup]
- search_test.yaml requires_state: "standard_state"
- password_crud_test.yaml requires_state: "standard_state"
- groups_test.yaml requires_state: "standard_state"
- webdav_test.yaml requires_state: "standard_state"
- export_import_test.yaml requires_state: "standard_state"

依赖链：base_setup → standard_state → 其他测试

- [ ] **Step 5: 生成系统清单文档**

创建清单文件记录所有组件：

```bash
cat > tests/e2e/MANIFEST.md << 'EOF'
# E2E 测试系统清单

## 场景文件 (7个)
- [x] base_setup.yaml - 首次安装
- [x] standard_state.yaml - 标准状态
- [x] search_test.yaml - 搜索测试
- [x] password_crud_test.yaml - CRUD 测试
- [x] groups_test.yaml - 分组测试
- [x] webdav_test.yaml - WebDAV 测试
- [x] export_import_test.yaml - 导出导入测试

## Python 脚本 (2个)
- [x] prepare_standard_state.py - 状态准备
- [x] clean_app_data.py - 数据清理

## 配置文件 (1个)
- [x] config.yaml - 全局配置

## 文档 (2个)
- [x] README.md - 使用文档
- [x] MANIFEST.md - 系统清单

## 脚本 (1个)
- [x] run_tests.sh - 启动脚本

## 总计
- 场景: 7
- 脚本: 3
- 配置: 1
- 文档: 2
EOF
```

- [ ] **Step 6: 最终提交**

```bash
git add tests/e2e/MANIFEST.md
git commit -m "chore: add E2E test system manifest

Complete E2E test infrastructure:
- 7 test scenarios (base, standard_state + 5 tests)
- 2 Python helper scripts
- Configuration and documentation
- Convenience launch script

System ready for execution by Claude + mobile-mcp"
```

---

## 验收标准

### 基础设施
- [x] 目录结构完整 (scenarios/, utils/, reports/)
- [x] config.yaml 配置完整且语法正确
- [x] Python 脚本可执行且返回标准 JSON

### 场景定义
- [x] 7 个 YAML 场景文件全部创建
- [x] 所有 YAML 语法正确
- [x] 场景依赖关系明确 (base_setup → standard_state → 测试)

### 文档和工具
- [x] README.md 文档完整
- [x] run_tests.sh 脚本可执行
- [x] test/CLAUDE.md 已更新
- [x] MANIFEST.md 记录所有组件

### 集成验证
- [x] 所有文件路径引用正确
- [x] Python 脚本返回格式符合规范
- [x] YAML 场景的 preparation_script 路径正确

---

## 下一步

系统已完成搭建，可以开始执行测试：

1. **手动验证**: 使用 Claude CLI 执行单个场景
   ```bash
   claude -p "执行测试场景 tests/e2e/scenarios/search_test.yaml"
   ```

2. **完整测试**: 执行所有场景并生成报告
   ```bash
   ./tests/e2e/run_tests.sh
   ```

3. **迭代优化**: 根据执行结果调整场景定义和错误处理

---

## 参考文档

- [设计规范](../../docs/superpowers/specs/2026-03-23-mobile-mcp-orchestration-design.md)
- [mobile-mcp 设置](../../docs/MOBILE_MCP_SETUP.md)
- [APWD 架构](../../lib/CLAUDE.md)
