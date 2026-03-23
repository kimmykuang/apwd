# Mobile-MCP 测试编排系统设计

## 概述

**目标**: 为 APWD 密码管理器构建基于 mobile-mcp 的结构化 E2E 测试系统，解决纯交互式测试的混乱问题。

**核心理念**:
- Claude 作为"大脑"，执行、判断并返回结果
- Python 作为流程编排和确定性逻辑辅助
- YAML 定义清晰的测试场景和操作路径
- mobile-mcp 作为被使用的工具

**解决的问题**:
mobile-mcp 本身是交互+截图+识别工具，但缺乏对完整 E2E 流程的理解。典型问题如"进入主页面第一个操作设置两个 master password"导致死循环，无法理解应该先检查当前状态再决定操作。

---

## 架构设计

### 三层架构

```
┌─────────────────────────────────────────────┐
│  Claude CLI/Code (智能编排层)               │
│  - 读取 YAML 场景定义                       │
│  - 调用 Python 准备状态 (Bash tool)         │
│  - 使用 mobile-mcp 操作模拟器 (MCP tool)    │
│  - 视觉验证和判断                           │
│  - 生成结构化测试报告 (Write tool)          │
└─────────────────┬───────────────────────────┘
                  │
         ┌────────┴────────┐
         │                 │
    ┌────┴─────┐      ┌────┴──────────┐
    │ Python   │      │ mobile-mcp    │
    │ 辅助脚本 │      │ + 模拟器      │
    │          │      │               │
    │ - 清理   │      │ - tap/swipe   │
    │   数据   │      │ - 截图        │
    │ - 生成   │      │ - 输入文字    │
    │   配置   │      │               │
    └──────────┘      └───────────────┘
```

### 职责划分

**Claude (智能编排层)**:
- 读取并理解 YAML 场景定义
- 调用 Python 脚本准备测试状态
- 使用 mobile-mcp 执行 UI 操作
- 视觉判断 UI 元素和状态（不确定性任务）
- 验证每步是否符合预期
- 生成结构化测试报告

**Python (辅助脚本)**:
- 数据准备（清理数据库、生成测试数据配置）
- 模拟器控制（启动、重启）
- 返回 JSON 配置供 Claude 使用
- 确定性逻辑操作

**mobile-mcp (执行工具)**:
- 底层 UI 操作（点击、滑动、输入）
- 截图
- 元素识别

---

## 目录结构

```
tests/e2e/
├── scenarios/              # YAML 场景定义
│   ├── base_setup.yaml            # 基础：首次安装设置主密码
│   ├── standard_state.yaml        # 标准状态定义
│   ├── search_test.yaml           # 测试场景：搜索功能
│   ├── password_crud_test.yaml    # 测试场景：密码 CRUD
│   ├── groups_test.yaml           # 测试场景：分组管理
│   ├── webdav_test.yaml           # 测试场景：WebDAV 备份恢复
│   └── export_import_test.yaml    # 测试场景：本地导出导入
├── utils/                  # Python 工具脚本
│   ├── prepare_standard_state.py  # 准备标准测试状态
│   ├── clean_app_data.py          # 清理应用数据
│   └── create_test_data.py        # 生成测试数据配置
├── reports/                # 测试报告输出目录
│   ├── screenshots/               # 测试截图
│   └── *.md                       # 测试报告文件
├── config.yaml             # 测试配置（可选）
└── run_tests.sh            # 便捷启动脚本（可选）
```

---

## YAML 场景定义格式

### 场景类型

- **base**: 基础场景，不依赖其他状态（如首次安装）
- **state_definition**: 状态定义，用于准备测试前置条件
- **test**: 测试场景，依赖特定状态

### 基础场景示例

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

### 状态定义示例

```yaml
# tests/e2e/scenarios/standard_state.yaml
name: "标准测试状态"
description: "主密码已设置，包含3个测试密码和2个分组"
type: "state_definition"

depends_on:
  - base_setup

preparation_script: "tests/e2e/utils/prepare_standard_state.py"
# Claude 会执行这个 Python 脚本，脚本返回 JSON 配置

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

### 测试场景示例

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

### YAML Schema 字段说明

**顶层字段**:
- `name`: 场景名称
- `description`: 场景描述
- `type`: 场景类型 (base/state_definition/test)
- `depends_on`: 依赖的场景列表
- `requires_state`: 要求的前置状态
- `preparation_script`: Python 准备脚本路径

**步骤字段 (steps)**:
- `id`: 步骤唯一标识
- `action`: 操作类型
- `description`: 步骤描述
- `params`: 操作参数
- `timeout`: 超时时间（秒）
- `retry_on_failure`: 失败重试次数
- `expected`: 预期结果（对象，字段任意）

**错误处理字段**:
- `fallback`: 失败后的降级操作列表（字符串数组）
  ```yaml
  fallback:
    - "截图当前界面，分析是否在正确页面"
    - "如果不在主页面，返回主页重试"
  ```
- `on_failure`: 失败时的行为定义（对象）
  ```yaml
  on_failure:
    action: "save_diff"  # 执行的动作
    path: "reports/visual_diff.png"  # 相关路径（可选）
    abort: false  # 是否终止测试（默认 false）
  ```

**错误处理配置**:
所有场景共享的错误处理策略应定义在 `tests/e2e/config.yaml` 中：
```yaml
error_handling:
  simulator_not_running:
    action: "start_simulator"
    command: "xcrun simctl boot {device_id}"
    retry: true
  app_crashed:
    action: "relaunch_app"
    command: "xcrun simctl launch {device_id} {bundle_id}"
    retry: true
    max_retries: 3
```
其中 `{device_id}` 和 `{bundle_id}` 从 config.yaml 的 simulator 和 app 配置中动态替换

---

## Python 辅助脚本

### 混合模式设计

**核心原则**: Python 不直接操作加密数据库，而是提供配置，由 Claude 通过 UI 创建数据。

**原因**:
- APWD 使用 SQLCipher 加密数据库
- 密码字段经过 AES-256-CBC 加密
- Python 复制加密逻辑复杂且易出错

### 标准状态准备脚本

```python
# tests/e2e/utils/prepare_standard_state.py
"""
准备标准测试状态：
1. 重启模拟器清理状态（可选）
2. 返回测试数据配置 JSON
3. Claude 读取 JSON 并通过 UI 创建数据
"""
import json
import sys
import os

def prepare_standard_state():
    """混合模式：Python 生成配置，Claude 执行创建"""

    # 注意：模拟器管理由 Claude 通过 config.yaml 处理
    # 此脚本仅负责生成测试数据配置

    # 返回测试数据配置
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

### 清理数据脚本

```python
# tests/e2e/utils/clean_app_data.py
"""
清理应用数据（卸载重装或清理沙盒）
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
    import sys
    device_id = sys.argv[1] if len(sys.argv) > 1 else None
    if not device_id:
        print(json.dumps({"status": "error", "message": "Missing device_id"}))
        sys.exit(1)
    clean_app_data(device_id)
```

### Python 脚本 JSON 接口规范

所有 Python 辅助脚本必须遵守统一的 JSON 响应格式：

**成功响应**:
```json
{
  "status": "success",
  "config": {
    // 可选：测试数据配置（如 prepare_standard_state.py）
  },
  "message": "Optional success message"
}
```

**失败响应**:
```json
{
  "status": "error",
  "message": "具体错误信息",
  "error_code": "OPTIONAL_ERROR_CODE"  // 可选
}
```

**退出码**:
- 成功：`sys.exit(0)`
- 失败：`sys.exit(1)`

**Claude 处理逻辑**:
```python
result = subprocess.run(['python', 'script.py'], capture_output=True, text=True)
data = json.loads(result.stdout)

if result.returncode != 0 or data.get('status') != 'success':
    # 记录错误到测试报告
    # 标记测试为 BLOCKED
    # 不继续执行后续步骤
else:
    # 使用 data['config'] 中的配置
    # 继续执行测试
```

---

## Claude 执行流程

### 单场景执行流程

```
用户输入: "执行测试场景 tests/e2e/scenarios/search_test.yaml"
    ↓
┌──────────────────────────────────────────────┐
│ Step 1: 读取场景文件                         │
│ - Read tests/e2e/scenarios/search_test.yaml  │
│ - 解析 requires_state: "standard_state"      │
└────────────────┬─────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────┐
│ Step 2: 准备依赖状态                         │
│ - Read standard_state.yaml                   │
│ - 发现 depends_on: [base_setup]             │
│ - Read base_setup.yaml                       │
│ - 检查是否需要执行 base_setup               │
└────────────────┬─────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────┐
│ Step 3: 执行状态准备                         │
│ - Bash: python prepare_standard_state.py     │
│ - 获取返回 JSON:                             │
│   {status: "success", config: {...}}         │
│ - 如果 status == "error"，终止并报告         │
└────────────────┬─────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────┐
│ Step 4: 通过 UI 创建测试数据                 │
│ 根据 config 中的数据，使用 mobile-mcp:      │
│ - 设置主密码 "TestPassword123!"             │
│ - 创建 Work 分组                             │
│ - 添加 3 个测试密码                          │
│ - 每步截图验证成功                           │
└────────────────┬─────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────┐
│ Step 5: 执行测试步骤                         │
│ 遍历 search_test.yaml 的 steps:             │
│                                              │
│ step: search_existing                       │
│ - 使用 mobile-mcp 截图当前界面              │
│ - 点击搜索图标                              │
│ - 输入 "GitHub"                             │
│ - 验证搜索结果 (found: true, count: 1)     │
│ - 截图保存                                  │
│                                              │
│ step: view_details                          │
│ - 点击第一个搜索结果                        │
│ - 验证进入详情页 (screen: PasswordDetail)  │
│ - 验证标题 "GitHub" 和用户名                │
│ - 截图保存                                  │
│                                              │
│ step: search_nonexistent                    │
│ - 返回主页                                  │
│ - 搜索 "NonExistent"                        │
│ - 验证 found: false                         │
│ - 截图保存                                  │
└────────────────┬─────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────┐
│ Step 6: 生成测试报告                         │
│ - Write tests/e2e/reports/search_test.md     │
│ - 包含每步结果、截图路径、耗时              │
│ - 标记 PASS/FAIL                            │
└──────────────────────────────────────────────┘
```

### 批量执行流程

```
用户输入: "执行 APWD 完整 E2E 测试套件"
    ↓
读取 tests/e2e/scenarios/ 目录
    ↓
过滤出所有 type: "test" 的场景
    ↓
按依赖关系排序:
  1. base_setup (如需要)
  2. standard_state
  3. search_test
  4. password_crud_test
  5. groups_test
  6. webdav_test
  7. export_import_test
    ↓
逐个执行每个场景（使用单场景流程）
    ↓
生成汇总报告:
  - 总共执行 X 个场景
  - 通过 Y 个
  - 失败 Z 个
  - 总耗时
  - 每个场景的详细链接
```

---

## 7 个核心测试场景

### 场景依赖关系图

```
base_setup.yaml (首次安装设置主密码)
    ↓
standard_state.yaml (标准状态：3个密码 + 2个分组)
    ↓
    ├── search_test.yaml (搜索功能)
    ├── password_crud_test.yaml (密码 CRUD)
    ├── groups_test.yaml (分组管理)
    ├── webdav_test.yaml (WebDAV 备份恢复)
    └── export_import_test.yaml (本地导出导入)
```

### 场景1: 首次安装流程 (base_setup.yaml)

**目标**: 验证全新安装后的主密码设置流程

**前置条件**: 应用全新安装（无数据）

**测试步骤**:
1. 启动应用
2. 验证显示 SetupPasswordScreen
3. 输入主密码（两次）
4. 点击 Create Password
5. 验证进入 HomeScreen，显示 "No passwords yet"

**后置状态**: `master_password_set`

---

### 场景2: 标准状态准备 (standard_state.yaml)

**目标**: 准备包含测试数据的标准状态

**依赖**: base_setup

**测试数据**:
- 分组: Default (🔐), Work (💼)
- 密码:
  - GitHub (test@github.com, GitHubPass123!, Default)
  - Gmail (test@gmail.com, GmailPass123!, Default)
  - AWS Console (test@aws.com, AWSPass123!, Work)

**准备方式**:
1. Python 脚本生成配置 JSON
2. Claude 读取配置通过 UI 创建数据

**后置状态**: `standard_state`

---

### 场景3: 搜索功能 (search_test.yaml)

**依赖状态**: standard_state

**测试步骤**:
1. 搜索已存在密码 "GitHub"
   - 验证 found: true, result_count: 1
2. 点击搜索结果查看详情
   - 验证进入 PasswordDetailScreen
   - 验证标题和用户名
3. 返回，搜索不存在密码 "NonExistent"
   - 验证 found: false
   - 验证显示 "No results found"

---

### 场景4: 密码 CRUD (password_crud_test.yaml)

**依赖状态**: standard_state

**测试步骤**:
1. 添加新密码 "Twitter"
   - 标题: Twitter
   - 用户名: test@twitter.com
   - 密码: TwitterPass123!
   - 分组: Default
   - 验证出现在密码列表
2. 编辑 "Twitter" 密码
   - 修改用户名为: newemail@twitter.com
   - 验证保存成功
3. 查看详情验证修改
4. 删除 "Twitter"
   - 验证从列表消失

**边界情况**:
- 空标题验证
- 超长标题处理
- 特殊字符处理

---

### 场景5: 分组管理 (groups_test.yaml)

**依赖状态**: standard_state

**测试步骤**:
1. 创建新分组 "Personal" (💙)
   - 验证出现在分组列表
2. 将 "Gmail" 移动到 "Personal" 分组
   - 编辑 Gmail
   - 修改分组为 Personal
   - 验证保存成功
3. 编辑分组名称
   - 将 "Personal" 改为 "Private"
   - 验证修改成功
4. 删除空分组 "Work"
   - 先将 AWS Console 移到 Default
   - 删除 Work 分组
   - 验证删除成功
5. 验证无法删除有密码的分组
   - 尝试删除 Default
   - 验证显示错误提示

---

### 场景6: WebDAV 备份恢复 (webdav_test.yaml)

**依赖状态**: standard_state

**前置条件**:
- WebDAV 测试服务器运行中
  - 验证方式：Claude 在测试前执行 `curl -I $WEBDAV_TEST_URL` 检查 HTTP 200
  - 失败处理：如果服务器不可达，标记测试为 BLOCKED，不执行
- 环境变量配置（在 tests/e2e/config.yaml 或系统环境）:
  ```yaml
  webdav_test:
    url: "https://webdav.test.local"  # 或 $WEBDAV_TEST_URL
    username: "testuser"              # 或 $WEBDAV_TEST_USER
    password: "testpass"              # 或 $WEBDAV_TEST_PASSWORD
    remote_path: "/APWD_Test"
  ```
- Claude 从 config.yaml 读取配置或使用环境变量

**测试步骤**:
1. 打开设置 → WebDAV 配置
2. 输入测试服务器地址、用户名、密码
3. 点击 "Test Connection"
   - 验证连接成功
4. 点击 "Backup Now"
   - 输入加密密码 "BackupPass123!"
   - 验证显示备份成功
5. Python 脚本清空本地数据库
6. 执行恢复
   - 输入加密密码
   - 验证 3 个密码都恢复成功
7. 验证密码内容正确

---

### 场景7: 本地导出导入 (export_import_test.yaml)

**依赖状态**: standard_state

**测试步骤**:
1. 打开设置 → 导出备份
2. 输入加密密码 "BackupPass123!"
3. 验证生成 .apwd 文件
   - 文件路径：iOS 模拟器的 Documents 目录
   - 文件名格式：`apwd_backup_YYYYMMDD_HHMMSS.apwd`
   - Claude 通过截图或 mobile-mcp API 获取文件路径
   - 验证文件存在：Bash `ls -la <file_path>`
4. Python 脚本清空本地数据库
   - 脚本：`tests/e2e/utils/clean_app_data.py`
   - 传入设备 ID 和应用 bundle ID
5. 导入备份文件
   - Claude 通过 mobile-mcp 操作文件选择器
   - 选择步骤3生成的 .apwd 文件（使用记录的文件路径）
   - 输入解密密码 "BackupPass123!"
   - 验证导入成功（显示成功消息）
6. 验证 3 个密码都恢复
   - 主页面显示 3 个密码条目
   - 标题分别为：GitHub, Gmail, AWS Console
7. 验证密码内容正确
   - 点击每个密码查看详情
   - 验证用户名和所属分组

**后置清理**:
- Python 脚本删除测试生成的 .apwd 文件
  ```bash
  rm -f <file_path>
  ```

---

## 错误处理和边界情况

### 错误处理策略

**1. 模拟器状态问题**

错误处理配置统一定义在 `tests/e2e/config.yaml` 中（而非每个 YAML 场景）：

```yaml
# tests/e2e/config.yaml
simulator:
  platform: "ios"
  device_id: "auto"  # "auto" 表示自动查找，或具体 UUID
  device_name: "iPhone 15"  # 如果 device_id 为 auto，按名称查找

app:
  bundle_id: "com.apwd.app"
  build_path: "build/ios/iphonesimulator/Runner.app"

error_handling:
  simulator_not_running:
    action: "start_simulator"
    command: "xcrun simctl boot {device_id}"
    retry: true

  app_not_installed:
    action: "install_app"
    command: "xcrun simctl install {device_id} {build_path}"
    retry: true
    on_failure_abort: true  # 安装失败则终止测试

  app_crashed:
    action: "relaunch_app"
    command: "xcrun simctl launch {device_id} {bundle_id}"
    retry: true
    max_retries: 3
```

**动态值替换**:
- `{device_id}`: 从 config.yaml 的 simulator.device_id 读取
  - 如果值为 "auto"，Claude 执行：
    ```bash
    xcrun simctl list devices | grep "iPhone 15" | grep -oE '\([A-F0-9-]+\)' | head -1
    ```
- `{bundle_id}`: 从 config.yaml 的 app.bundle_id 读取
- `{build_path}`: 从 config.yaml 的 app.build_path 读取

**优先级**:
如果单个场景的 YAML 定义了错误处理，优先使用场景级配置，否则使用 config.yaml 的全局配置
    action: "重启应用"
    command: "xcrun simctl launch <device_id> com.apwd.app"
    retry: true
    max_retries: 3
```

**2. UI 元素识别失败**

每个步骤支持超时和重试:

```yaml
steps:
  - id: "search_existing"
    action: "search_password"
    timeout: 30  # 30秒超时
    retry_on_failure: 2  # 失败重试2次
    fallback:
      - "截图当前界面，分析是否在正确页面"
      - "如果不在主页面，返回主页重试"
```

**3. 状态准备失败**

Python 脚本返回状态码和错误信息:

```python
try:
    # ... 准备逻辑
    print(json.dumps({"status": "success", "config": {...}}))
    sys.exit(0)
except Exception as e:
    print(json.dumps({"status": "error", "message": str(e)}))
    sys.exit(1)
```

Claude 检查返回码，失败则终止并报告。

**4. 测试步骤失败处理**

- 记录失败步骤和截图
- 标记测试为 FAILED
- 继续执行后续场景（除非是依赖场景失败）
- 在报告中详细记录失败原因

### 边界情况测试

在各场景中添加边界测试步骤:

**空值验证**:
```yaml
- id: "edge_empty_title"
  action: "add_password_with_validation"
  params:
    title: ""
    username: "test@example.com"
    password: "Pass123!"
  expected:
    save_failed: true
    error_message: "Please enter a title"
```

**超长输入**:
```yaml
- id: "edge_long_title"
  action: "add_password_with_long_title"
  params:
    title: "A" * 256
    username: "test"
    password: "Pass123!"
  expected:
    save_success: true
```

**特殊字符**:
```yaml
- id: "edge_special_chars"
  action: "add_password_special_chars"
  params:
    title: "Test<>\"'&"
    password: "!@#$%^&*()"
  expected:
    save_success: true
    display_correct: true
```

---

## 测试报告格式

### 单场景报告示例

```markdown
# 测试报告：搜索密码功能测试

**执行时间**: 2026-03-23 14:30:25
**场景文件**: tests/e2e/scenarios/search_test.yaml
**状态准备**: standard_state
**总耗时**: 45.3 秒
**结果**: ✅ PASS

---

## 状态准备

### 执行脚本
```bash
python tests/e2e/utils/prepare_standard_state.py
```

### 创建的测试数据
- ✅ 主密码: TestPassword123!
- ✅ 分组: Default, Work
- ✅ 密码条目: GitHub, Gmail, AWS Console

📸 截图: [状态准备完成](reports/screenshots/search_test_state_ready.png)

---

## 测试步骤

### Step 1: search_existing ✅ PASS
**描述**: 搜索已存在的密码 GitHub
**耗时**: 8.2 秒

**操作记录**:
1. 点击搜索图标 ✓
2. 输入 "GitHub" ✓
3. 验证搜索结果 ✓

**验证结果**:
- ✅ found: true
- ✅ result_count: 1
- ✅ first_result_title: "GitHub"

📸 截图: [搜索结果](reports/screenshots/search_test_step1.png)

---

### Step 2: view_details ✅ PASS
**描述**: 点击搜索结果进入详情页
**耗时**: 3.5 秒

**验证结果**:
- ✅ screen: PasswordDetailScreen
- ✅ title: "GitHub"
- ✅ username: "test@github.com"

📸 截图: [密码详情页](reports/screenshots/search_test_step2.png)

---

### Step 3: search_nonexistent ✅ PASS
**描述**: 返回主页，搜索不存在的密码
**耗时**: 5.1 秒

**验证结果**:
- ✅ found: false
- ✅ message: "No results found"

📸 截图: [无搜索结果](reports/screenshots/search_test_step3.png)

---

## 总结

✅ **所有步骤通过**
✅ **无异常或崩溃**
✅ **UI 显示符合预期**

**下一步建议**: 可以继续执行其他场景测试
```

### 汇总报告示例

```markdown
# APWD E2E 测试汇总报告

**执行时间**: 2026-03-23 14:30:00
**总耗时**: 8 分 32 秒
**总场景数**: 7
**通过**: 6
**失败**: 1

---

## 执行结果

| 场景 | 状态 | 耗时 | 报告 |
|------|------|------|------|
| base_setup | ✅ PASS | 25s | [查看](reports/base_setup.md) |
| standard_state | ✅ PASS | 68s | [查看](reports/standard_state.md) |
| search_test | ✅ PASS | 45s | [查看](reports/search_test.md) |
| password_crud_test | ✅ PASS | 92s | [查看](reports/password_crud_test.md) |
| groups_test | ✅ PASS | 78s | [查看](reports/groups_test.md) |
| webdav_test | ❌ FAIL | 120s | [查看](reports/webdav_test.md) |
| export_import_test | ✅ PASS | 85s | [查看](reports/export_import_test.md) |

---

## 失败详情

### webdav_test - WebDAV 备份和恢复

**失败步骤**: Step 3 - 测试连接

**错误信息**:
```
无法连接到 WebDAV 服务器
Connection timeout after 30s
```

**可能原因**:
- WebDAV 测试服务器未运行
- 网络连接问题
- 服务器地址配置错误

**建议操作**:
1. 确认 WebDAV 服务器是否运行
2. 检查网络连接
3. 验证服务器地址配置

---

## 测试覆盖

- ✅ 首次安装流程
- ✅ 密码 CRUD 操作
- ✅ 搜索功能
- ✅ 分组管理
- ❌ WebDAV 备份恢复（环境问题）
- ✅ 本地导出导入

---

## 下一步建议

1. 修复 WebDAV 服务器连接问题
2. 重新执行 webdav_test 场景
3. 考虑添加性能测试场景
```

---

## 测试配置文件 (config.yaml)

完整的 `tests/e2e/config.yaml` 结构定义：

```yaml
# tests/e2e/config.yaml
# APWD E2E 测试全局配置

# 模拟器配置
simulator:
  platform: "ios"  # ios 或 android
  device_id: "auto"  # "auto" 自动查找，或具体 UUID
  device_name: "iPhone 15"  # device_id 为 auto 时使用
  os_version: "17.0"

# 应用配置
app:
  bundle_id: "com.apwd.app"
  build_path: "build/ios/iphonesimulator/Runner.app"
  launch_timeout: 30  # 应用启动超时（秒）

# Claude 配置
claude:
  model: "claude-sonnet-4-6"  # 可指定模型
  temperature: 0.0  # 确定性执行
  max_retries: 3

# 测试报告配置
reporting:
  output_dir: "tests/e2e/reports"
  screenshot_format: "png"
  screenshot_dir: "tests/e2e/reports/screenshots"
  save_video: false  # 是否录制测试视频
  cleanup_screenshots_on_success: false  # 成功后是否清理截图

# 超时配置
timeouts:
  step_default: 30  # 默认步骤超时（秒）
  state_preparation: 120  # 状态准备超时
  test_scenario: 300  # 单个场景超时

# WebDAV 测试配置（可选）
webdav_test:
  enabled: true
  url: "${WEBDAV_TEST_URL}"  # 支持环境变量
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

**环境变量支持**:
- config.yaml 中使用 `${VAR_NAME}` 引用环境变量
- Claude 在读取配置时自动替换
- 示例：`url: "${WEBDAV_TEST_URL}"` → `url: "https://webdav.test.local"`

---

## 使用方式

### 方式1: Claude CLI 直接执行单个场景

```bash
# 在 Claude CLI/Code 中输入：
执行测试场景 tests/e2e/scenarios/search_test.yaml
```

Claude 会自动：
1. 读取 YAML 文件
2. 准备依赖状态
3. 执行测试步骤
4. 生成报告

### 方式2: 批量执行所有场景

```bash
# 在 Claude CLI/Code 中输入：
执行 APWD 完整 E2E 测试套件
```

Claude 会：
1. 扫描所有测试场景
2. 按依赖顺序执行
3. 生成汇总报告

### 方式3: 通过便捷脚本（可选）

```bash
#!/bin/bash
# tests/e2e/run_tests.sh

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

claude -p "$PROMPT"
```

使用方式:
```bash
./tests/e2e/run_tests.sh
# 交互式选择场景后自动执行
```

---

## 实施路径

### Phase 1: 基础设施（第1周）

**目标**: 搭建框架和工具

**任务**:
1. 创建目录结构
   ```bash
   mkdir -p tests/e2e/{scenarios,utils,reports/screenshots}
   ```

2. 编写 Python 辅助脚本
   - prepare_standard_state.py
   - clean_app_data.py

3. 创建 YAML schema 文档和验证方式
   - 文档化 YAML 字段和结构（本规范中已包含）
   - 验证方式：Claude 读取 YAML 时自动校验必填字段
   - 可选工具：使用 `pyyaml` 或 `jsonschema` 做格式检查
   - 如不实现工具，依赖 Claude 的语义理解和错误提示

4. 编写测试配置文件 config.yaml

**交付物**:
- ✅ 完整目录结构
- ✅ Python 脚本能正常执行并返回标准 JSON
- ✅ config.yaml 包含所有必需配置
- ✅ YAML schema 文档（本规范已包含）

---

### Phase 2: 核心场景（第2周）

**目标**: 实现基础流程验证

**任务**:
1. 实现 base_setup.yaml
   - 首次安装流程
   - 主密码设置

2. 实现 standard_state.yaml
   - 状态准备逻辑
   - 数据创建流程

3. 实现 search_test.yaml
   - 验证完整测试流程
   - 报告生成

4. Claude 执行测试并生成第一份报告

**交付物**:
- ✅ 3 个场景 YAML 文件
- ✅ 能成功执行 search_test
- ✅ 生成格式正确的测试报告

---

### Phase 3: 扩展场景（第3周）

**目标**: 覆盖所有核心功能

**任务**:
1. 实现 password_crud_test.yaml
2. 实现 groups_test.yaml
3. 实现 webdav_test.yaml
4. 实现 export_import_test.yaml
5. 添加边界情况测试

**交付物**:
- ✅ 7 个完整场景
- ✅ 边界情况覆盖
- ✅ 批量执行功能

---

### Phase 4: 优化和工具（第4周）

**目标**: 提升易用性和稳定性

**任务**:
1. 完善错误处理
2. 优化报告格式
3. 添加 run_tests.sh 便捷脚本
4. 编写使用文档
5. 性能优化（减少等待时间）

**交付物**:
- ✅ 稳定的测试系统
- ✅ 完善的文档
- ✅ 便捷的启动脚本

---

## 成功标准

1. **解决负面案例**
   - ✅ 不会重复设置主密码
   - ✅ 清晰的状态声明和操作路径
   - ✅ 有序的流程执行

2. **测试覆盖**
   - ✅ 7 个核心场景全部覆盖
   - ✅ 关键边界情况测试
   - ✅ 错误处理验证

3. **可用性**
   - ✅ 可单独执行任一场景
   - ✅ 可批量执行完整套件
   - ✅ 报告清晰易读

4. **稳定性**
   - ✅ 失败自动重试
   - ✅ 明确的错误提示
   - ✅ 状态准备可靠

5. **效率**
   - ✅ 状态准备快速（混合模式）
   - ✅ Python 辅助确定性逻辑
   - ✅ Claude 专注 UI 操作

---

## 技术债务和未来改进

### 当前已知限制

1. **WebDAV 测试依赖外部服务器**
   - 需要手动启动测试服务器
   - 考虑使用 Docker 容器自动化

2. **截图对比未实现**
   - 当前仅保存截图，无自动对比
   - 可引入视觉回归测试工具

3. **性能测试缺失**
   - 未测试大量数据场景（1000+ 密码）
   - 未测试加载时间和响应时间

### 未来增强方向

1. **AI 测试生成**
   - 基于应用截图自动生成测试场景
   - Claude 探索性测试发现问题

2. **持续集成**
   - GitHub Actions 集成（CI/CD）
   - 自动执行回归测试

3. **多平台支持**
   - Android 模拟器测试
   - 真机测试支持

4. **测试数据管理**
   - 测试数据版本化
   - 支持自定义测试数据集

---

## 附录

### 相关文档

- [APWD 项目架构](../../CLAUDE.md)
- [mobile-mcp 使用指南](../../docs/MOBILE_MCP_SETUP.md)
- [传统 UI 测试文档](../../test/CLAUDE.md)

### 参考资料

- [mobile-mcp GitHub](https://github.com/mobile-next/mobile-mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [YAML 规范](https://yaml.org/spec/)

### 术语表

- **E2E**: End-to-End，端到端测试
- **MCP**: Model Context Protocol，模型上下文协议
- **YAML**: YAML Ain't Markup Language，配置文件格式
- **Claude CLI**: Claude 命令行工具
- **mobile-mcp**: 移动模拟器控制的 MCP 服务器
- **standard_state**: 标准测试状态（3个密码 + 2个分组）
