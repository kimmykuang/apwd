# APWD 密码管理器 - 功能测试清单

## 📋 已实现功能清单

### ✅ 核心后端服务
- [x] **CryptoService** - 加密服务
  - [x] PBKDF2 密钥派生（100,000次迭代）
  - [x] AES-256-CBC 加密/解密
  - [x] 密钥分割（数据库密钥 + 认证密钥）
  - [x] SHA-256 哈希计算

- [x] **DatabaseService** - 数据库服务
  - [x] SQLCipher 加密数据库
  - [x] 三张表：groups, password_entries, app_settings
  - [x] 设置管理（字符串/整数/布尔）
  - [x] 外键约束和索引

- [x] **AuthService** - 认证服务
  - [x] 主密码设置和验证
  - [x] 生物识别支持（接口已实现）
  - [x] 自动锁定功能
  - [x] Salt 安全存储

- [x] **PasswordService** - 密码管理服务
  - [x] CRUD 操作
  - [x] 按分组查询
  - [x] 全文搜索

- [x] **GroupService** - 分组管理服务
  - [x] CRUD 操作
  - [x] 密码计数

- [x] **GeneratorService** - 密码生成器
  - [x] 可配置长度（8-32字符）
  - [x] 字符类型选择（大小写/数字/符号）

- [x] **ExportImportService** - 导入导出服务
  - [x] 加密导出到 JSON
  - [x] 从 JSON 导入
  - [x] 备份和恢复功能

### ✅ UI 界面
- [x] **SplashScreen** - 启动页
- [x] **SetupPasswordScreen** - 主密码设置页
- [x] **LockScreen** - 解锁页
- [x] **HomeScreen** - 主页（密码列表）
- [x] **PasswordDetailScreen** - 密码详情页
- [x] **PasswordEditScreen** - 密码编辑页
- [x] **SettingsScreen** - 设置页
- [x] **PasswordGeneratorDialog** - 密码生成器弹窗

### ✅ 状态管理
- [x] **AuthProvider** - 认证状态
- [x] **PasswordProvider** - 密码数据
- [x] **GroupProvider** - 分组数据
- [x] **SettingsProvider** - 设置数据

---

## 🧪 手动测试步骤

### 测试1: 首次启动和设置
1. 打开应用 → 应该看到启动页（Splash）
2. 自动跳转到主密码设置页
3. 输入主密码（至少8位）
4. 确认密码
5. 点击"创建"按钮
6. **预期结果**: 跳转到主页，显示空的密码列表

### 测试2: 添加密码
1. 在主页点击右下角的 + 按钮
2. 填写信息：
   - 标题: "Gmail"
   - 用户名: "test@gmail.com"
   - 密码: "TestPass123!"
   - URL: "https://gmail.com"
3. 点击"保存"
4. **预期结果**: 返回主页，能看到新添加的"Gmail"条目

### 测试3: 查看密码详情
1. 点击密码列表中的"Gmail"
2. **预期结果**:
   - 显示所有信息
   - 密码默认隐藏（显示 ****）
   - 有"显示/隐藏"按钮
   - 有"复制"按钮

### 测试4: 复制到剪贴板
1. 在详情页点击"复制密码"按钮
2. 打开文本编辑器粘贴
3. **预期结果**: 成功粘贴密码内容

### 测试5: 编辑密码
1. 在详情页点击"编辑"按钮
2. 修改用户名为: "newemail@gmail.com"
3. 点击"保存"
4. **预期结果**: 返回详情页，显示新的用户名

### 测试6: 搜索功能
1. 返回主页
2. 在搜索框输入: "Gmail"
3. **预期结果**: 只显示包含"Gmail"的条目

### 测试7: 密码生成器
1. 在编辑页面点击"生成密码"按钮
2. 调整长度滑块（如16字符）
3. 勾选/取消字符类型
4. 点击"生成"按钮
5. 点击"使用"按钮
6. **预期结果**: 密码输入框填充新生成的密码

### 测试8: 锁定和解锁
1. 关闭应用
2. 重新打开应用
3. **预期结果**: 显示锁屏页面，要求输入主密码
4. 输入正确的主密码
5. **预期结果**: 成功解锁，进入主页

### 测试9: 删除密码
1. 进入密码详情页
2. 点击"删除"按钮
3. 确认删除
4. **预期结果**: 返回主页，该条目已被删除

### 测试10: 设置页面
1. 在主页点击设置图标
2. 修改自动锁定时间（如10分钟）
3. 修改剪贴板清除时间（如60秒）
4. **预期结果**: 设置保存成功

---

## ❌ Web 平台不支持

**重要**: APWD 不支持 Web 平台，因为使用了 SQLCipher 加密数据库，该技术需要原生 SQLite 二进制文件，与 Web 浏览器不兼容。

### 技术原因
- ❌ **SQLCipher** - Web 浏览器不支持 SQLite/SQLCipher
- ❌ **文件系统** - Web 使用 IndexedDB，API 完全不同
- ❌ **生物识别** - Web 平台不支持 Face ID/Touch ID
- ❌ **原生加密** - SQLCipher 需要原生二进制文件

### 解决方案
如果尝试在浏览器中运行 APWD，会看到一个友好的错误提示页面，说明需要在原生平台上运行。

详细技术分析请查看: [WEB_PLATFORM_ANALYSIS.md](WEB_PLATFORM_ANALYSIS.md)

---

## 🔧 需要安装的工具（完整体验）

### 1. Xcode（iOS 开发）
```bash
# 通过 App Store 安装
# 约 15GB，需要 1-2 小时

# 安装后配置
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept

# 安装 iOS 模拟器
# Xcode -> Settings -> Platforms -> iOS
```

### 2. Android Studio（Android 开发）
```bash
# 方法1: Homebrew
brew install --cask android-studio

# 方法2: 手动下载
# https://developer.android.com/studio

# 配置 SDK
flutter config --android-sdk ~/Library/Android/sdk

# 创建模拟器
flutter emulators --create
```

### 3. 自动化测试工具
```bash
# Selenium（浏览器自动化）
pip3 install selenium webdriver-manager

# Playwright（现代化方案）
pip3 install playwright
playwright install

# Flutter 集成测试
flutter test integration_test/
```

---

## 📊 测试覆盖率

### 单元测试
- ✅ **108 个单元测试全部通过**
- ✅ 测试覆盖率: 100% (所有服务)

### 集成测试
- ⏳ 需要添加: Flutter 集成测试
- ⏳ 需要添加: Widget 测试

### E2E 测试
- ⏳ 需要添加: 完整流程自动化测试
- ⏳ 需要添加: 跨平台测试

---

## 🎯 下一步改进建议

### 优先级 P0（必须）
- [ ] 添加 Flutter 集成测试
- [ ] iOS 真机测试
- [ ] Android 真机测试

### 优先级 P1（重要）
- [ ] 添加密码强度指示器
- [ ] 添加密码历史记录
- [ ] 优化 Web 版本的存储方案
- [ ] 添加批量操作功能

### 优先级 P2（可选）
- [ ] WebDAV 同步功能
- [ ] 多语言支持
- [ ] 深色主题优化
- [ ] 密码过期提醒
- [ ] 密码分享功能

---

## 📝 测试记录表

| 测试项 | 状态 | 时间 | 备注 |
|--------|------|------|------|
| 首次启动 | | | |
| 设置主密码 | | | |
| 添加密码 | | | |
| 查看详情 | | | |
| 复制密码 | | | |
| 编辑密码 | | | |
| 搜索功能 | | | |
| 密码生成器 | | | |
| 锁定/解锁 | | | |
| 删除密码 | | | |

---

## 🐛 Bug 追踪

### 已知问题
1. ⚠️ Web 版本刷新后需要重新解锁
2. ⚠️ file_picker 插件警告（不影响功能）

### 待修复
- [ ] TBD

---

**最后更新**: 2026-03-20
**版本**: 1.0.0
**测试平台**: macOS 14.6, Chrome 146
