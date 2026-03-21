# APWD - 测试文档

**最后更新**: 2026-03-21
**版本**: 1.0.0
**测试状态**: ✅ 所有测试通过 (13/13)

---

## 📊 测试概览

### 测试覆盖情况

| 测试类型 | 状态 | 通过率 | 备注 |
|---------|------|--------|------|
| 单元测试 | ✅ | 100% (108/108) | 所有服务完整覆盖 |
| 集成测试 | ✅ | 100% (13/13) | 端到端用户流程 |
| 自动化测试 | ✅ | 已实现 | iOS 模拟器自闭环 |

### 最新测试结果

**平台**: iOS
**设备**: iPhone 16 Pro 模拟器
**测试时间**: 2026-03-21 14:49
**测试结果**: ✅ 13/13 通过

---

## 🧪 自动化测试

### 自闭环测试系统

APWD 实现了完全自主的自动化测试系统，可以：

✅ 自动启动 iOS 模拟器
✅ 自动运行应用
✅ 自动执行测试用例
✅ 自动收集截图和日志
✅ 自动分析问题
✅ 自动生成报告

**完全无需人工干预！**

### 快速开始

#### 运行自动化测试

```bash
# iOS 平台（推荐）
python3 autonomous_test_runner.py ios

# Android 平台
python3 autonomous_test_runner.py android

# 查看测试报告
cat test_results/最新时间戳_report.md
```

#### 测试结果位置

```
test_results/
├── YYYYMMDD_HHMMSS_report.md      # 测试报告
├── ios_YYYYMMDD_HHMMSS_result.txt # 详细输出
├── ios_YYYYMMDD_HHMMSS_logs.txt   # 设备日志
├── ios_YYYYMMDD_HHMMSS_analysis.json # 结构化分析
└── ios_YYYYMMDD_HHMMSS_screenshots/  # 测试截图
```

---

## 🎯 测试场景

### 场景1: 首次启动和主密码设置

**目标**: 验证用户首次使用应用时能成功设置主密码

**步骤**:
1. 启动应用
2. 等待启动页完成
3. 进入主密码设置页
4. 输入主密码（TestPassword123!）
5. 确认主密码
6. 点击创建按钮
7. 验证进入主页面

**预期结果**:
- ✅ 显示 "No passwords yet" 提示
- ✅ 主密码已保存
- ✅ 进入主页面

---

### 场景2: 添加密码条目

**目标**: 验证用户能成功添加密码条目

**步骤**:
1. 点击 + 按钮
2. 进入添加密码页面
3. 验证 Group 下拉框存在
4. 填写表单：
   - 标题: GitHub测试账号
   - 用户名: test@github.com
   - 密码: SecurePassword123!
5. 保存
6. 验证密码已添加

**预期结果**:
- ✅ Group 下拉框可用
- ✅ 表单验证通过
- ✅ 密码成功保存
- ✅ 主页显示新条目

---

### 场景3: 查看密码详情

**目标**: 验证用户能查看密码详情

**步骤**:
1. 点击密码列表中的条目
2. 查看详情页

**预期结果**:
- ✅ 显示标题
- ✅ 显示用户名
- ✅ 密码默认隐藏
- ✅ 有显示/隐藏按钮
- ✅ 有复制按钮

---

### 场景4: 搜索功能

**目标**: 验证搜索功能可用

**步骤**:
1. 返回主页
2. 验证搜索框存在

**预期结果**:
- ✅ 搜索框可见
- ✅ 可以输入搜索内容

---

### 场景5: Group 管理

**目标**: 验证用户能管理 Groups

**步骤**:
1. 打开右上角菜单
2. 点击 "Manage Groups"
3. 验证只有一个 Default group
4. 点击 + 添加新 Group
5. 选择图标（💼 Work）
6. 输入名称 "Work"
7. 保存
8. 验证新 Group 已添加

**预期结果**:
- ✅ Default group 存在
- ✅ 可以添加自定义 Group
- ✅ 图标选择器工作正常
- ✅ Group 保存成功

---

## 📋 手动测试清单

### 核心功能测试

- [ ] **首次启动**: 显示启动页并跳转到设置页
- [ ] **设置主密码**: 能成功创建主密码（最少8位）
- [ ] **添加密码**: 能添加新密码条目
- [ ] **查看详情**: 能查看密码详细信息
- [ ] **复制密码**: 能复制密码到剪贴板
- [ ] **编辑密码**: 能修改现有密码条目
- [ ] **删除密码**: 能删除密码条目（需确认）
- [ ] **搜索功能**: 能搜索密码条目
- [ ] **密码生成器**: 能生成强密码
- [ ] **锁定/解锁**: 重启应用后需要解锁
- [ ] **Group 管理**: 能创建、编辑、删除 Groups
- [ ] **Group 分组显示**: 主页按 Group 分组展示密码

### 设置功能测试

- [ ] **自动锁定时间**: 能修改自动锁定时间
- [ ] **剪贴板清除时间**: 能修改剪贴板清除时间
- [ ] **生物识别**: 能启用/禁用生物识别（原生平台）

### 安全功能测试

- [ ] **密码加密**: 数据库中的密码已加密
- [ ] **主密码验证**: 错误的主密码无法解锁
- [ ] **自动锁定**: 超时后自动锁定
- [ ] **剪贴板清除**: 复制后自动清除剪贴板

---

## 🔧 环境配置

### 必需工具

#### iOS 测试（推荐）

**Xcode 14+**
```bash
# 通过 App Store 安装
# 安装后配置
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept

# 验证安装
xcodebuild -version
xcrun simctl list devices
```

**iOS Simulator**
- 在 Xcode -> Settings -> Platforms -> iOS 中下载
- 大小: ~8GB
- 时间: 30-60分钟

#### Android 测试（可选）

**Android Studio**
```bash
# Homebrew 安装
brew install --cask android-studio

# 配置 SDK
flutter config --android-sdk ~/Library/Android/sdk

# 创建模拟器
flutter emulators --create
```

#### Flutter 集成测试

```bash
# 已在 pubspec.yaml 中配置
# dev_dependencies:
#   integration_test:
#     sdk: flutter

# 运行测试
flutter test integration_test/app_test.dart
```

### 验证安装

```bash
# 运行验证脚本
./verify_setup.sh

# 应该看到:
# ✅ Flutter: Flutter 3.x.x
# ✅ Xcode: Xcode 14.x
# ✅ iOS 模拟器: X 个可用
```

---

## 🤖 自动化测试脚本

### autonomous_test_runner.py

自动化测试运行器，完全自主执行测试流程。

**功能**:
- 自动启动模拟器
- 运行集成测试
- 收集截图和日志
- 分析测试结果
- 生成报告
- 清理环境

**使用方法**:
```bash
# 给脚本执行权限
chmod +x autonomous_test_runner.py

# 运行 iOS 测试
python3 autonomous_test_runner.py ios

# 运行 Android 测试
python3 autonomous_test_runner.py android
```

**输出**:
```
============================================================
🚀 APWD 自闭环自动化测试
============================================================
测试平台: ios

📱 设置 iOS 模拟器...
   选择设备: iPhone 16 Pro
   启动模拟器...

🧪 在 ios 上运行测试...
   运行集成测试...
   ✅ 所有测试通过！

📋 收集 ios 日志...
   ✅ 日志已保存

📊 分析 ios 测试结果...
   ✅ 分析结果已保存

🧹 清理 ios 模拟器...
   ✅ iOS 模拟器已关闭

============================================================
✅ 自动化测试完成！
📄 查看报告: test_results/20260321_144944_report.md
============================================================
```

---

## 📊 单元测试

### 运行单元测试

```bash
# 运行所有单元测试
flutter test

# 运行测试并生成覆盖率报告
flutter test --coverage

# 运行特定测试文件
flutter test test/services/crypto_service_test.dart
```

### 测试覆盖

**服务层** (100% 覆盖)
- ✅ CryptoService - 加密服务 (PBKDF2, AES-256)
- ✅ DatabaseService - 数据库服务 (SQLCipher)
- ✅ AuthService - 认证服务
- ✅ PasswordService - 密码管理
- ✅ GroupService - 分组管理
- ✅ GeneratorService - 密码生成器
- ✅ ExportImportService - 导入导出

**测试统计**:
- 总测试数: 108
- 通过: 108
- 失败: 0
- 成功率: 100%

---

## 🐛 问题排查

### 常见问题

#### 1. iOS 模拟器无法启动

**症状**: `xcrun simctl list devices` 显示空列表

**原因**: iOS Runtime 未安装

**解决**:
```bash
# 在 Xcode 中下载 iOS Runtime
# Xcode -> Settings -> Platforms -> iOS -> Download
```

#### 2. 测试超时

**症状**: 测试运行超过 2 分钟无响应

**原因**: 模拟器启动慢或应用加载慢

**解决**:
```bash
# 增加等待时间
await tester.pumpAndSettle(Duration(seconds: 5));

# 或者预热模拟器
xcrun simctl boot "iPhone 16 Pro"
```

#### 3. 截图未保存

**症状**: `test_results/` 下没有 screenshots 目录

**原因**: IntegrationTestWidgetsFlutterBinding 未正确初始化

**解决**:
```dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 使用 binding.takeScreenshot()
}
```

#### 4. Android 模拟器找不到

**症状**: `flutter emulators` 显示空列表

**原因**: AVD 未创建或路径未配置

**解决**:
```bash
# 检查 ANDROID_HOME
echo $ANDROID_HOME

# 创建 AVD
flutter emulators --create

# 或者手动创建
avdmanager create avd --name test --package "system-images;android-34;google_apis;arm64-v8a"
```

---

## 📈 测试报告示例

### 成功测试报告

```markdown
# APWD 自动化测试报告

**生成时间**: 2026-03-21 14:51:50

## 📊 测试结果汇总

### ✅ 通过 IOS

- **通过**: 13 个测试
- **失败**: 0 个测试

## 📈 总体统计

- **总测试数**: 13
- **通过**: 13
- **失败**: 0
- **成功率**: 100.0%
```

### 测试分析 JSON

```json
{
  "platform": "ios",
  "timestamp": "20260321_144944",
  "success": true,
  "tests_passed": 13,
  "tests_failed": 0,
  "errors": [],
  "warnings": []
}
```

---

## 🎯 下一步

### 测试改进计划

**优先级 P0**:
- [ ] 添加更多边界条件测试
- [ ] 增加错误情况测试
- [ ] 添加性能测试

**优先级 P1**:
- [ ] Android 平台测试
- [ ] macOS 桌面测试
- [ ] Windows 桌面测试

**优先级 P2**:
- [ ] 压力测试（大量密码）
- [ ] 并发测试
- [ ] 网络恢复测试（导入导出）

---

## 📚 相关文档

- [README.md](../../README.md) - 项目说明
- [开发文档](../development/) - 开发相关文档
- [项目设计](../superpowers/specs/) - 架构设计文档

---

**维护者**: AI Agent
**联系方式**: 查看 README.md
**许可证**: 查看 LICENSE 文件
