# 密码管理应用设计文档 (APWD - A Password Manager)

**创建日期：** 2026-03-19
**版本：** 1.0
**状态：** 设计阶段

## 1. 项目概述

### 1.1 目标

构建一个轻量级、安全的跨平台密码管理应用，专注于本地存储和简单易用。不提供自动表单填充功能，仅提供密码的安全存储、查询和管理。

### 1.2 核心理念

- **One Password, All Passwords**：用户只需记住一个主密码，即可访问所有存储的密码
- **移动优先**：优先支持iOS和Android平台
- **安全至上**：使用行业标准加密算法，本地加密存储
- **轻量简洁**：专注核心功能，避免过度工程化
- **离线优先**：无需网络连接，100%本地运行

### 1.3 非目标

- 不提供浏览器插件或自动表单填充
- 初始版本不提供云同步（预留WebDAV扩展能力）
- 不提供密码共享或多用户功能
- 不提供密码强度检测和安全审计（后续版本可考虑）

## 2. 技术选型

### 2.1 核心技术栈

**框架：** Flutter 3.x
- 真正的跨平台，一套代码支持iOS和Android
- 原生性能，流畅的用户体验
- 活跃的社区和丰富的生态
- Dart语言简单易学
- 打包体积小（约15-20MB）

**加密方案：** AES-256 + PBKDF2
- AES-256：行业标准对称加密算法
- PBKDF2：密钥派生函数，100000迭代（防暴力破解）
- SQLCipher：透明数据库加密

### 2.2 关键依赖

| 依赖包 | 用途 | 说明 |
|--------|------|------|
| sqflite_sqlcipher | 加密数据库 | SQLite + AES-256透明加密 |
| local_auth | 生物识别 | Face ID / Touch ID / 指纹 |
| flutter_secure_storage | 安全存储 | Keychain(iOS) / KeyStore(Android) |
| crypto | 加密工具 | PBKDF2、SHA-256实现 |
| provider | 状态管理 | 轻量级状态管理 |
| path_provider | 文件路径 | 获取应用目录 |
| share_plus | 文件分享 | 导出文件分享 |
| file_picker | 文件选择 | 导入文件选择 |
| intl | 国际化 | 时间格式化和多语言 |

## 3. 系统架构

### 3.1 整体架构

```
┌─────────────────────────────────────────────────────┐
│                   UI Layer (Flutter)                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ 锁屏页面 │  │ 列表页面 │  │ 详情页面 │  ...     │
│  └──────────┘  └──────────┘  └──────────┘          │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│              Business Logic Layer                    │
│  ┌──────────────┐  ┌──────────────┐                │
│  │ AuthService  │  │PasswordSvc   │  ...           │
│  └──────────────┘  └──────────────┘                │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│                   Data Layer                         │
│  ┌──────────────┐  ┌──────────────┐                │
│  │  SQLCipher   │  │SecureStorage │  ┌──────────┐  │
│  │   Database   │  │   (Keychain) │  │local_auth│  │
│  └──────────────┘  └──────────────┘  └──────────┘  │
└─────────────────────────────────────────────────────┘
```

**三层职责：**

1. **UI Layer**：纯展示逻辑，不包含业务规则
2. **Business Logic Layer**：所有业务逻辑和数据转换
3. **Data Layer**：数据持久化和加密存储

### 3.2 项目目录结构

```
apwd/
├── lib/
│   ├── main.dart                          # 应用入口
│   ├── models/                            # 数据模型
│   │   ├── password_entry.dart
│   │   ├── group.dart
│   │   └── app_settings.dart
│   ├── services/                          # 业务逻辑服务
│   │   ├── database_service.dart          # 数据库管理
│   │   ├── crypto_service.dart            # 加密解密
│   │   ├── auth_service.dart              # 认证和会话管理
│   │   ├── password_service.dart          # 密码CRUD
│   │   ├── group_service.dart             # 分组CRUD
│   │   ├── generator_service.dart         # 密码生成器
│   │   └── export_import_service.dart     # 导入导出
│   ├── providers/                         # 状态管理
│   │   ├── auth_provider.dart
│   │   └── password_provider.dart
│   ├── screens/                           # 页面
│   │   ├── splash_screen.dart             # 启动页
│   │   ├── setup_password_screen.dart     # 首次设置主密码
│   │   ├── lock_screen.dart               # 锁屏页
│   │   ├── home_screen.dart               # 主界面框架
│   │   ├── group_list_screen.dart         # 分组列表
│   │   ├── password_list_screen.dart      # 密码列表
│   │   ├── password_detail_screen.dart    # 密码详情
│   │   ├── password_edit_screen.dart      # 密码编辑
│   │   ├── search_screen.dart             # 搜索
│   │   └── settings_screen.dart           # 设置
│   ├── widgets/                           # 可复用组件
│   │   ├── password_field.dart            # 密码输入框
│   │   ├── password_generator_dialog.dart # 密码生成器对话框
│   │   └── ...
│   └── utils/                             # 工具类
│       ├── constants.dart
│       └── validators.dart
├── test/                                  # 单元测试
├── integration_test/                      # 集成测试
├── assets/                                # 资源文件
├── docs/                                  # 文档
└── pubspec.yaml                           # 依赖配置
```

## 4. 数据模型设计

### 4.1 数据库表结构

#### 4.1.1 groups 表（分组）

```sql
CREATE TABLE groups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,              -- 分组名称，如"工作"、"个人"、"银行"
  icon TEXT,                        -- 图标名称（Flutter Icons的名称）
  sort_order INTEGER DEFAULT 0,    -- 排序顺序，数字越小越靠前
  created_at INTEGER NOT NULL,     -- 创建时间戳（毫秒）
  updated_at INTEGER NOT NULL      -- 更新时间戳（毫秒）
);

-- 初始数据（首次启动创建）
INSERT INTO groups (name, icon, sort_order, created_at, updated_at) VALUES
  ('未分类', 'folder', 0, <timestamp>, <timestamp>),
  ('工作', 'work', 1, <timestamp>, <timestamp>),
  ('个人', 'person', 2, <timestamp>, <timestamp>),
  ('银行', 'account_balance', 3, <timestamp>, <timestamp>);
```

#### 4.1.2 password_entries 表（密码条目）

```sql
CREATE TABLE password_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id INTEGER NOT NULL,       -- 所属分组ID（外键）
  title TEXT NOT NULL,              -- 标题/网站名称，如"GitHub"
  url TEXT,                         -- 网址（可选），如"https://github.com"
  username TEXT,                    -- 用户名/邮箱
  password TEXT NOT NULL,           -- 密码（已加密）
  notes TEXT,                       -- 备注（可选）
  created_at INTEGER NOT NULL,     -- 创建时间戳
  updated_at INTEGER NOT NULL,     -- 更新时间戳
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);

-- 索引优化
CREATE INDEX idx_group_id ON password_entries(group_id);
CREATE INDEX idx_title ON password_entries(title);
CREATE INDEX idx_updated_at ON password_entries(updated_at DESC);
```

#### 4.1.3 app_settings 表（应用设置）

```sql
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- 设置项说明：
-- 'auto_lock_timeout': 自动锁定时间（秒），默认'300'（5分钟）
-- 'biometric_enabled': 生物识别开关，'true' / 'false'
-- 'master_password_hash': 主密码的PBKDF2哈希（用于验证）
-- 'password_salt': 密码派生盐值（Base64编码）
-- 'clipboard_clear_timeout': 剪贴板清理时间（秒），默认'30'
-- 'first_launch_completed': 首次启动完成标记，'true' / 'false'
```

### 4.2 Dart 数据模型

#### 4.2.1 Group Model

```dart
class Group {
  final int? id;
  final String name;
  final String? icon;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    this.id,
    required this.name,
    this.icon,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap();
  factory Group.fromMap(Map<String, dynamic> map);
  Group copyWith({...});
}
```

#### 4.2.2 PasswordEntry Model

```dart
class PasswordEntry {
  final int? id;
  final int groupId;
  final String title;
  final String? url;
  final String? username;
  final String password;      // 加密后的密码
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordEntry({
    this.id,
    required this.groupId,
    required this.title,
    this.url,
    this.username,
    required this.password,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap();
  factory PasswordEntry.fromMap(Map<String, dynamic> map);
  PasswordEntry copyWith({...});
}
```

#### 4.2.3 AppSettings Model

```dart
class AppSettings {
  final int autoLockTimeout;      // 秒
  final bool biometricEnabled;
  final int clipboardClearTimeout; // 秒

  AppSettings({
    this.autoLockTimeout = 300,
    this.biometricEnabled = false,
    this.clipboardClearTimeout = 30,
  });
}
```

## 5. 加密安全设计

### 5.1 加密流程

#### 5.1.1 首次设置主密码

```
用户输入主密码
    ↓
生成随机盐值（32字节）
    ↓
PBKDF2 派生（100000迭代）
    ├─→ 派生密钥1（32字节）→ SQLCipher数据库密钥
    └─→ 派生密钥2（32字节）→ SHA-256哈希 → 存储用于验证
    ↓
初始化SQLCipher数据库
    ↓
（可选）存储派生密钥1到SecureStorage（用于生物识别）
```

**实现细节：**

```dart
// 生成盐值
final salt = crypto.generateRandomBytes(32);

// PBKDF2派生
final pbkdf2 = crypto.Pbkdf2(
  macAlgorithm: crypto.Hmac.sha256(),
  iterations: 100000,
  bits: 512, // 64字节输出
);

final derivedKey = await pbkdf2.deriveKey(
  secretKey: crypto.SecretKey(masterPassword.codeUnits),
  nonce: salt,
);

// 分割密钥
final dbKey = derivedKey.bytes.sublist(0, 32);  // 数据库密钥
final authKey = derivedKey.bytes.sublist(32, 64); // 认证密钥

// 保存认证哈希
final authHash = crypto.sha256.convert(authKey);
await settingsService.set('master_password_hash', base64.encode(authHash.bytes));
await settingsService.set('password_salt', base64.encode(salt));
```

#### 5.1.2 解锁验证流程

```
用户输入主密码（或生物识别）
    ↓
读取存储的盐值
    ↓
使用相同参数进行PBKDF2派生
    ↓
比对哈希值
    ├─→ 正确：使用派生密钥打开数据库
    └─→ 错误：提示重新输入
```

#### 5.1.3 生物识别集成

```
用户启用生物识别
    ↓
派生数据库密钥
    ↓
存储到SecureStorage（系统级加密）
    ↓
下次解锁：
    ├─→ 生物识别成功 → 从SecureStorage读取密钥 → 打开数据库
    └─→ 生物识别失败/取消 → 回退到主密码输入
```

**安全性说明：**
- iOS的Keychain和Android的KeyStore都提供系统级硬件加密
- 生物识别失败不会泄露任何密钥信息
- 用户始终可以通过主密码访问

### 5.2 数据加密层次

**三层加密保护：**

1. **数据库层加密**：SQLCipher透明加密整个数据库文件
2. **字段层加密**：密码字段额外AES加密（可选，初版可省略）
3. **传输层加密**：导出文件使用主密码加密

### 5.3 安全威胁防护

| 威胁 | 防护措施 |
|------|----------|
| 暴力破解 | PBKDF2 100000迭代，连续错误延迟 |
| 中间人攻击 | 纯本地应用，无网络通信 |
| 内存嗅探 | 密码仅在显示时解密，使用后立即清理 |
| 屏幕截图 | Android设置FLAG_SECURE，iOS自动保护 |
| 剪贴板窃取 | 30秒自动清理剪贴板 |
| 数据库盗取 | 数据库文件加密，无主密码无法解密 |
| 应用内窥探 | 后台自动锁定，需重新认证 |

## 6. 功能设计

### 6.1 用户流程

#### 6.1.1 首次启动流程

```
启动App
    ↓
检测是否首次启动
    ↓
显示欢迎页（说明安全特性）
    ↓
设置主密码页
    ├─ 输入主密码（至少8位）
    ├─ 显示强度指示器
    └─ 输入确认密码
    ↓
（可选）启用生物识别页
    ├─ 说明生物识别的便利性
    └─ 用户选择是否启用
    ↓
初始化数据库和加密密钥
    ↓
进入主界面
```

#### 6.1.2 日常使用流程

```
启动App
    ↓
显示锁屏页
    ├─ 生物识别（如已启用）
    │   ├─ 成功 → 进入主界面
    │   └─ 失败/取消 → 显示主密码输入
    └─ 主密码输入
        ├─ 正确 → 进入主界面
        └─ 错误 → 提示重试（5次后延迟30秒）
```

#### 6.1.3 主界面导航

**底部导航栏（3个Tab）：**

1. **密码** - 默认页
   - 显示分组列表
   - 点击分组 → 密码条目列表
   - 点击条目 → 密码详情页

2. **搜索**
   - 搜索框（实时过滤）
   - 搜索范围：标题、用户名、URL、备注
   - 结果列表 → 点击 → 密码详情页

3. **设置**
   - 安全设置
   - 导入导出
   - 关于

### 6.2 核心功能详细设计

#### 6.2.1 密码列表页

**UI布局：**
```
┌─────────────────────────────┐
│  ← 分组名称          + 新建 │
├─────────────────────────────┤
│ [搜索框]                    │
├─────────────────────────────┤
│ [图标] 标题                 │
│        用户名               │
├─────────────────────────────┤
│ [图标] 标题                 │
│        用户名               │
├─────────────────────────────┤
│ ...                         │
└─────────────────────────────┘
```

**功能：**
- 按更新时间倒序排列
- 左滑删除（需二次确认）
- 点击进入详情页
- 搜索框实时过滤当前列表

#### 6.2.2 密码详情页

**UI布局：**
```
┌─────────────────────────────┐
│  ← 标题              编辑 │
├─────────────────────────────┤
│ 标题：GitHub                │
│ 网址：https://github.com    │
│ 用户名：user@example.com    │
│ 密码：••••••••  [👁] [📋]  │
│ 备注：个人开发账号           │
│                             │
│ 创建时间：2026-03-15 10:30  │
│ 更新时间：2026-03-19 14:20  │
└─────────────────────────────┘
```

**交互：**
- 👁 图标：显示/隐藏密码明文
- 📋 图标：复制密码到剪贴板（30秒后自动清空）
- 长按密码字段：直接复制
- 点击网址：打开浏览器（可选）

#### 6.2.3 密码编辑页

**UI布局：**
```
┌─────────────────────────────┐
│  ← 编辑密码      取消  保存 │
├─────────────────────────────┤
│ 分组：[下拉选择]             │
│ 标题：[输入框]               │
│ 网址：[输入框]               │
│ 用户名：[输入框]             │
│ 密码：[输入框] [生成]        │
│ 备注：[多行输入框]           │
└─────────────────────────────┘
```

**验证规则：**
- 标题：必填，最长100字符
- 密码：必填，最长1000字符
- 其他字段：可选

#### 6.2.4 密码生成器

**弹出对话框UI：**
```
┌─────────────────────────────┐
│       密码生成器            │
├─────────────────────────────┤
│ 长度：[12] ————●————         │
│       8              32     │
├─────────────────────────────┤
│ ☑ 大写字母 (A-Z)            │
│ ☑ 小写字母 (a-z)            │
│ ☑ 数字 (0-9)                │
│ ☑ 特殊字符 (!@#$%...)       │
├─────────────────────────────┤
│ 预览：aB3$kL9mP2qR           │
│                [刷新]       │
├─────────────────────────────┤
│       [取消]  [使用该密码]   │
└─────────────────────────────┘
```

**生成逻辑：**
```dart
String generatePassword({
  required int length,
  required bool uppercase,
  required bool lowercase,
  required bool digits,
  required bool symbols,
}) {
  const uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  const digitChars = '0123456789';
  const symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  String charset = '';
  if (uppercase) charset += uppercaseChars;
  if (lowercase) charset += lowercaseChars;
  if (digits) charset += digitChars;
  if (symbols) charset += symbolChars;

  if (charset.isEmpty) return '';

  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}
```

**默认配置：**
- 长度：16位
- 包含：大写、小写、数字、特殊字符

#### 6.2.5 搜索功能

**搜索范围：**
- 标题（title）
- 用户名（username）
- 网址（url）
- 备注（notes）

**搜索逻辑：**
- 实时搜索（输入即搜索）
- 大小写不敏感
- 支持部分匹配
- 按相关性排序（标题匹配优先）

**SQL查询示例：**
```sql
SELECT * FROM password_entries
WHERE
  LOWER(title) LIKE LOWER('%' || ? || '%') OR
  LOWER(username) LIKE LOWER('%' || ? || '%') OR
  LOWER(url) LIKE LOWER('%' || ? || '%') OR
  LOWER(notes) LIKE LOWER('%' || ? || '%')
ORDER BY
  CASE
    WHEN LOWER(title) LIKE LOWER('%' || ? || '%') THEN 1
    WHEN LOWER(username) LIKE LOWER('%' || ? || '%') THEN 2
    ELSE 3
  END,
  updated_at DESC
LIMIT 50;
```

#### 6.2.6 分组管理

**功能：**
- 新建分组：输入名称，选择图标
- 重命名分组：长按分组名
- 删除分组：
  - 如果分组中有密码，提示选择操作：
    - 移动到"未分类"
    - 一并删除（需二次确认）
  - 空分组直接删除
- 排序分组：拖拽调整顺序

**内置分组：**
- "未分类"分组不可删除，可重命名

#### 6.2.7 导出功能

**导出流程：**
```
设置页 → 点击"导出数据"
    ↓
验证主密码
    ↓
生成导出文件（.apwd格式）
    ├─ 读取所有分组和密码
    ├─ 序列化为JSON
    ├─ 使用主密码派生密钥加密
    └─ 添加签名和版本信息
    ↓
保存到本地 / 分享
```

**导出文件格式（.apwd）：**
```json
{
  "version": "1.0",
  "timestamp": 1710849600000,
  "salt": "<base64-encoded-salt>",
  "iv": "<base64-encoded-iv>",
  "encrypted_data": "<base64-encoded-encrypted-json>",
  "signature": "<hmac-signature>"
}
```

**加密后的数据结构：**
```json
{
  "groups": [
    {
      "id": 1,
      "name": "工作",
      "icon": "work",
      "sort_order": 1
    }
  ],
  "password_entries": [
    {
      "id": 1,
      "group_id": 1,
      "title": "GitHub",
      "url": "https://github.com",
      "username": "user@example.com",
      "password": "decrypted-password",
      "notes": "备注",
      "created_at": 1710000000000,
      "updated_at": 1710849600000
    }
  ]
}
```

#### 6.2.8 导入功能

**导入流程：**
```
设置页 → 点击"导入数据"
    ↓
选择.apwd文件
    ↓
验证主密码
    ↓
解密和验证签名
    ↓
显示导入预览：
    ├─ X个分组
    └─ Y个密码
    ↓
用户选择导入模式：
    ├─ 合并（保留现有数据，添加新数据）
    └─ 替换（清空现有数据，导入新数据）
    ↓
执行导入（数据库事务）
    ↓
显示结果统计
```

**冲突处理（合并模式）：**
- 分组名称冲突：保留现有分组
- 密码ID冲突：生成新ID插入

#### 6.2.9 自动锁定

**锁定触发条件：**
1. App进入后台超过设定时间（默认5分钟）
2. 用户手动锁定（设置页"立即锁定"按钮）
3. App完全关闭后重新打开

**实现机制：**
```dart
class AutoLockService {
  Timer? _lockTimer;
  DateTime? _lastActiveTime;

  void onAppLifecycleStateChange(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastActiveTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final elapsed = DateTime.now().difference(_lastActiveTime!);
      if (elapsed.inSeconds > _autoLockTimeout) {
        _lock();
      }
    }
  }

  void onUserActivity() {
    _lastActiveTime = DateTime.now();
  }

  void _lock() {
    // 清除内存中的敏感数据
    authProvider.lock();
    // 导航到锁屏页
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LockScreen()),
      (route) => false,
    );
  }
}
```

### 6.3 设置页面

**设置项：**

1. **安全设置**
   - 自动锁定时间：1分钟 / 5分钟 / 15分钟 / 30分钟 / 从不
   - 生物识别开关
   - 修改主密码
   - 立即锁定（按钮）

2. **数据管理**
   - 导出数据
   - 导入数据
   - 清除所有数据（危险操作，需二次确认）

3. **其他设置**
   - 剪贴板清理时间：15秒 / 30秒 / 1分钟 / 从不
   - 屏幕截图保护（Android）

4. **关于**
   - 应用版本
   - 开源许可
   - 隐私政策（说明：所有数据本地存储，不上传任何信息）
   - GitHub链接（可选）

## 7. 错误处理与边界情况

### 7.1 错误处理策略

#### 7.1.1 主密码错误

**场景：** 用户输入错误的主密码

**处理：**
```dart
int _failedAttempts = 0;
DateTime? _lockoutUntil;

Future<bool> verifyMasterPassword(String password) async {
  // 检查是否在锁定期
  if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
    final remaining = _lockoutUntil!.difference(DateTime.now());
    throw AuthException('请等待 ${remaining.inSeconds} 秒后重试');
  }

  final isValid = await _cryptoService.verifyPassword(password);

  if (isValid) {
    _failedAttempts = 0;
    _lockoutUntil = null;
    return true;
  } else {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(Duration(seconds: 30));
      _failedAttempts = 0;
      throw AuthException('密码错误次数过多，请等待30秒后重试');
    }
    throw AuthException('密码错误，还可尝试 ${5 - _failedAttempts} 次');
  }
}
```

**用户体验：**
- 显示剩余尝试次数
- 锁定期间显示倒计时
- 提供"忘记密码？"链接（说明：无法找回，只能清除数据重新开始）

#### 7.1.2 数据库损坏

**场景：** 数据库文件损坏或加密密钥错误

**处理：**
```dart
Future<void> openDatabase() async {
  try {
    _db = await openSQLCipherDatabase(path, password: dbKey);
    // 验证数据库完整性
    await _db.rawQuery('PRAGMA integrity_check');
  } on DatabaseException catch (e) {
    if (e.isCorruptionError()) {
      // 备份损坏的数据库
      final corruptedPath = '$path.corrupted.${DateTime.now().millisecondsSinceEpoch}';
      await File(path).copy(corruptedPath);

      // 提示用户
      throw DatabaseCorruptedException(
        '数据库文件已损坏。损坏的文件已备份到：\n$corruptedPath\n\n'
        '请尝试导入之前的备份文件，或联系开发者寻求帮助。'
      );
    }
    rethrow;
  }
}
```

**用户选择：**
1. 导入备份文件
2. 清除数据重新开始
3. 保存日志并联系技术支持（如果有）

#### 7.1.3 生物识别失败

**场景：** 生物识别硬件故障或识别失败

**处理：**
```dart
Future<bool> authenticateWithBiometric() async {
  try {
    final isAuthenticated = await _localAuth.authenticate(
      localizedReason: '使用生物识别解锁',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    return isAuthenticated;
  } on PlatformException catch (e) {
    if (e.code == 'NotAvailable') {
      // 生物识别不可用，自动回退到主密码
      return false;
    } else if (e.code == 'LockedOut') {
      throw AuthException('生物识别已锁定，请使用主密码解锁');
    }
    rethrow;
  }
}
```

**UI反馈：**
- 显示"使用主密码"按钮（始终可用）
- 生物识别失败后自动显示密码输入框

#### 7.1.4 导入文件错误

**场景：** 导入文件格式错误、密码错误或版本不兼容

**处理：**
```dart
Future<ImportResult> importFromFile(String filePath, String password) async {
  try {
    // 读取文件
    final file = File(filePath);
    if (!await file.exists()) {
      throw ImportException('文件不存在');
    }

    final content = await file.readAsString();
    final json = jsonDecode(content);

    // 验证版本
    final version = json['version'] as String;
    if (!_isSupportedVersion(version)) {
      throw ImportException('不支持的文件版本：$version');
    }

    // 解密数据
    final decryptedData = await _cryptoService.decryptExportData(
      json,
      password,
    );

    // 验证签名
    if (!_verifySignature(json, decryptedData)) {
      throw ImportException('文件签名验证失败，文件可能已被篡改');
    }

    return ImportResult.success(decryptedData);
  } on FormatException {
    throw ImportException('文件格式错误');
  } on CryptoException {
    throw ImportException('密码错误或文件已损坏');
  }
}
```

**用户反馈：**
- 清晰的错误信息
- 建议操作（检查文件、验证密码等）
- 不影响现有数据（事务回滚）

#### 7.1.5 存储空间不足

**场景：** 设备存储空间不足导致写入失败

**处理：**
```dart
Future<void> savePasswordEntry(PasswordEntry entry) async {
  try {
    await _db.transaction((txn) async {
      await txn.insert('password_entries', entry.toMap());
    });
  } on DatabaseException catch (e) {
    if (e.isDiskFullError()) {
      throw StorageException(
        '设备存储空间不足，请清理后重试'
      );
    }
    rethrow;
  }
}
```

**预防措施：**
- 在重要操作前检查可用空间
- 数据库使用WAL模式减少空间占用
- 定期清理临时文件

### 7.2 边界情况处理

#### 7.2.1 空数据状态

**场景：** 首次使用，没有任何密码

**UI处理：**
```
┌─────────────────────────────┐
│      欢迎使用密码管理器      │
│                             │
│    [插图：空文件夹]          │
│                             │
│  还没有保存任何密码          │
│                             │
│    [+ 添加第一个密码]       │
│                             │
│ 或者从备份文件导入            │
│    [📥 导入数据]            │
└─────────────────────────────┘
```

#### 7.2.2 删除分组

**场景：** 删除包含密码的分组

**处理流程：**
```dart
Future<void> deleteGroup(int groupId) async {
  final passwordCount = await _getPasswordCountInGroup(groupId);

  if (passwordCount > 0) {
    final action = await _showDeleteGroupDialog(
      groupName: group.name,
      passwordCount: passwordCount,
    );

    if (action == DeleteGroupAction.moveToUncategorized) {
      await _movePasswordsToGroup(groupId, _uncategorizedGroupId);
      await _deleteGroupById(groupId);
    } else if (action == DeleteGroupAction.deleteAll) {
      // 需要二次确认
      final confirmed = await _showConfirmDialog(
        '确定要删除分组"${group.name}"及其中的 $passwordCount 个密码吗？\n\n此操作无法撤销！'
      );
      if (confirmed) {
        await _deleteGroupById(groupId); // CASCADE删除密码
      }
    }
  } else {
    await _deleteGroupById(groupId);
  }
}
```

**用户选择：**
- 移动密码到"未分类"（推荐）
- 一并删除所有密码（危险，红色按钮）
- 取消操作

#### 7.2.3 搜索无结果

**UI处理：**
```
┌─────────────────────────────┐
│  [搜索框："github"]          │
├─────────────────────────────┤
│                             │
│    [插图：空搜索]            │
│                             │
│  未找到匹配的密码            │
│                             │
│  尝试其他关键词或            │
│    [+ 新建密码]             │
└─────────────────────────────┘
```

#### 7.2.4 修改主密码

**场景：** 用户需要修改主密码

**处理流程：**
```
设置页 → 点击"修改主密码"
    ↓
输入当前主密码（验证）
    ↓
输入新主密码
    ↓
确认新主密码
    ↓
显示警告：
    "修改主密码将重新加密所有数据，
     建议先导出备份。是否继续？"
    ↓
[取消] [已备份，继续]
    ↓
后台执行重加密（显示进度）:
    ├─ 导出所有明文数据到内存
    ├─ 使用新主密码派生新密钥
    ├─ 重新初始化数据库
    ├─ 写入所有数据
    └─ 更新SecureStorage中的密钥
    ↓
完成，提示用户重新登录
```

**技术实现：**
```dart
Future<void> changeMasterPassword(
  String oldPassword,
  String newPassword,
) async {
  // 1. 验证旧密码
  if (!await verifyMasterPassword(oldPassword)) {
    throw AuthException('当前密码错误');
  }

  // 2. 导出所有数据到内存
  final groups = await _groupService.getAllGroups();
  final passwords = await _passwordService.getAllPasswords();

  // 3. 派生新密钥
  final newSalt = crypto.generateRandomBytes(32);
  final newKeys = await _cryptoService.deriveKeys(newPassword, newSalt);

  // 4. 关闭当前数据库
  await _db.close();

  // 5. 删除旧数据库
  await File(_dbPath).delete();

  // 6. 用新密钥初始化新数据库
  await _initializeDatabaseWithKey(newKeys.dbKey);

  // 7. 写入所有数据
  await _db.transaction((txn) async {
    for (final group in groups) {
      await txn.insert('groups', group.toMap());
    }
    for (final password in passwords) {
      await txn.insert('password_entries', password.toMap());
    }
  });

  // 8. 更新设置
  await _settingsService.set('password_salt', base64.encode(newSalt));
  await _settingsService.set('master_password_hash',
    base64.encode(crypto.sha256.convert(newKeys.authKey).bytes));

  // 9. 更新SecureStorage
  if (await _settingsService.getBool('biometric_enabled')) {
    await _secureStorage.write(
      key: 'db_key',
      value: base64.encode(newKeys.dbKey),
    );
  }
}
```

#### 7.2.5 剪贴板清理

**场景：** 复制密码后自动清理剪贴板

**实现：**
```dart
Timer? _clipboardClearTimer;

void copyPasswordToClipboard(String password) async {
  await Clipboard.setData(ClipboardData(text: password));

  // 显示提示
  _showSnackBar('密码已复制，${_clipboardClearTimeout}秒后自动清空');

  // 取消之前的定时器
  _clipboardClearTimer?.cancel();

  // 设置新的定时器
  _clipboardClearTimer = Timer(
    Duration(seconds: _clipboardClearTimeout),
    () async {
      // 只有当前剪贴板内容是密码时才清空
      final currentClipboard = await Clipboard.getData('text/plain');
      if (currentClipboard?.text == password) {
        await Clipboard.setData(ClipboardData(text: ''));
      }
    },
  );
}
```

## 8. 测试策略

### 8.1 单元测试

**测试范围：**

1. **CryptoService**
   ```dart
   test('PBKDF2 key derivation is deterministic', () {
     final service = CryptoService();
     final password = 'test_password';
     final salt = Uint8List.fromList([1, 2, 3, 4]);

     final key1 = service.deriveKey(password, salt);
     final key2 = service.deriveKey(password, salt);

     expect(key1, equals(key2));
   });

   test('AES encryption and decryption', () {
     final service = CryptoService();
     final plaintext = 'sensitive_data';

     final encrypted = service.encrypt(plaintext, key);
     final decrypted = service.decrypt(encrypted, key);

     expect(decrypted, equals(plaintext));
   });
   ```

2. **GeneratorService**
   ```dart
   test('generated password meets requirements', () {
     final service = GeneratorService();

     final password = service.generate(
       length: 16,
       uppercase: true,
       lowercase: true,
       digits: true,
       symbols: false,
     );

     expect(password.length, equals(16));
     expect(password, matches(RegExp(r'^[A-Za-z0-9]+$')));
     expect(password, matches(RegExp(r'[A-Z]'))); // 包含大写
     expect(password, matches(RegExp(r'[a-z]'))); // 包含小写
     expect(password, matches(RegExp(r'[0-9]'))); // 包含数字
   });
   ```

3. **PasswordService**
   ```dart
   test('CRUD operations work correctly', () async {
     final service = PasswordService(db);

     final entry = PasswordEntry(
       groupId: 1,
       title: 'Test',
       password: 'test123',
       createdAt: DateTime.now(),
       updatedAt: DateTime.now(),
     );

     // Create
     final id = await service.create(entry);
     expect(id, isPositive);

     // Read
     final retrieved = await service.getById(id);
     expect(retrieved.title, equals('Test'));

     // Update
     final updated = retrieved.copyWith(title: 'Updated');
     await service.update(updated);
     final retrieved2 = await service.getById(id);
     expect(retrieved2.title, equals('Updated'));

     // Delete
     await service.delete(id);
     expect(() => service.getById(id), throwsException);
   });
   ```

### 8.2 集成测试

**测试场景：**

1. **完整的认证流程**
   ```dart
   testWidgets('complete authentication flow', (tester) async {
     await tester.pumpWidget(MyApp());

     // 首次启动 - 设置主密码
     await tester.enterText(find.byKey('password_field'), 'test_password_123');
     await tester.enterText(find.byKey('confirm_password_field'), 'test_password_123');
     await tester.tap(find.byKey('submit_button'));
     await tester.pumpAndSettle();

     // 应该进入主界面
     expect(find.byType(HomeScreen), findsOneWidget);

     // 锁定应用
     await tester.tap(find.byKey('lock_button'));
     await tester.pumpAndSettle();

     // 应该显示锁屏
     expect(find.byType(LockScreen), findsOneWidget);

     // 解锁
     await tester.enterText(find.byKey('unlock_password_field'), 'test_password_123');
     await tester.tap(find.byKey('unlock_button'));
     await tester.pumpAndSettle();

     // 应该返回主界面
     expect(find.byType(HomeScreen), findsOneWidget);
   });
   ```

2. **密码管理流程**
   ```dart
   testWidgets('create, edit, and delete password', (tester) async {
     await tester.pumpWidget(MyApp());
     await _setupAndUnlock(tester);

     // 创建密码
     await tester.tap(find.byIcon(Icons.add));
     await tester.pumpAndSettle();

     await tester.enterText(find.byKey('title_field'), 'GitHub');
     await tester.enterText(find.byKey('username_field'), 'user@example.com');
     await tester.enterText(find.byKey('password_field'), 'secret123');
     await tester.tap(find.byKey('save_button'));
     await tester.pumpAndSettle();

     // 应该在列表中看到新密码
     expect(find.text('GitHub'), findsOneWidget);

     // 编辑密码
     await tester.tap(find.text('GitHub'));
     await tester.pumpAndSettle();
     await tester.tap(find.byIcon(Icons.edit));
     await tester.pumpAndSettle();

     await tester.enterText(find.byKey('title_field'), 'GitHub Updated');
     await tester.tap(find.byKey('save_button'));
     await tester.pumpAndSettle();

     expect(find.text('GitHub Updated'), findsOneWidget);

     // 删除密码
     await tester.drag(find.text('GitHub Updated'), Offset(-500, 0));
     await tester.pumpAndSettle();
     await tester.tap(find.byKey('delete_confirm_button'));
     await tester.pumpAndSettle();

     expect(find.text('GitHub Updated'), findsNothing);
   });
   ```

3. **导出导入流程**
   ```dart
   testWidgets('export and import data', (tester) async {
     // ... 创建一些测试数据 ...

     // 导出
     await tester.tap(find.text('导出数据'));
     await tester.pumpAndSettle();
     // ... 验证主密码 ...
     // ... 保存文件 ...

     // 清空数据
     await _clearAllData();

     // 导入
     await tester.tap(find.text('导入数据'));
     await tester.pumpAndSettle();
     // ... 选择文件 ...
     // ... 验证主密码 ...

     // 数据应该恢复
     expect(find.text('GitHub'), findsOneWidget);
   });
   ```

### 8.3 手动测试清单

**设备和场景：**

| 测试项 | iOS | Android | 说明 |
|--------|-----|---------|------|
| Face ID / Touch ID | ✓ | - | 测试各种失败场景 |
| 指纹识别 | - | ✓ | 测试各种失败场景 |
| 屏幕截图保护 | 自动 | ✓ | Android需手动验证 |
| 后台自动锁定 | ✓ | ✓ | 测试不同超时时间 |
| App切换器遮罩 | ✓ | ✓ | 后台截图模糊处理 |
| 横屏适配 | ✓ | ✓ | UI是否正常显示 |
| 大字体模式 | ✓ | ✓ | 可访问性 |
| 暗黑模式 | ✓ | ✓ | 主题切换 |
| 低端设备性能 | - | ✓ | 测试旧设备流畅度 |
| 剪贴板清理 | ✓ | ✓ | 验证30秒后清空 |
| 导出文件打开 | ✓ | ✓ | 使用其他app打开 |

**压力测试：**
- 创建1000+密码条目，测试列表滚动流畅度
- 长时间后台，测试自动锁定可靠性
- 快速切换页面，测试内存泄漏

## 9. 性能优化

### 9.1 数据库优化

**索引策略：**
```sql
-- 分组查询优化
CREATE INDEX idx_group_id ON password_entries(group_id);

-- 搜索优化
CREATE INDEX idx_title ON password_entries(title);
CREATE INDEX idx_username ON password_entries(username);

-- 时间排序优化
CREATE INDEX idx_updated_at ON password_entries(updated_at DESC);
```

**查询优化：**
- 使用分页查询（LIMIT/OFFSET）
- 避免SELECT *，只查询需要的字段
- 使用事务批量操作

### 9.2 UI性能

**列表优化：**
```dart
// 使用ListView.builder懒加载
ListView.builder(
  itemCount: passwords.length,
  itemBuilder: (context, index) {
    return PasswordListItem(password: passwords[index]);
  },
);

// 避免在build中创建对象
class PasswordListItem extends StatelessWidget {
  final PasswordEntry password;
  const PasswordListItem({required this.password});

  @override
  Widget build(BuildContext context) {
    // ... 复用对象，减少GC压力
  }
}
```

**图片和资源：**
- 使用Flutter内置Icons，避免加载图片文件
- 不使用大型图片资源，保持app轻量

### 9.3 内存管理

**敏感数据清理：**
```dart
// 密码使用完立即清理
String? _cachedPassword;

void showPassword() {
  _cachedPassword = _decryptPassword(entry.password);
  setState(() {});
}

void hidePassword() {
  _cachedPassword = null; // 清理引用，让GC回收
  setState(() {});
}

@override
void dispose() {
  _cachedPassword = null;
  super.dispose();
}
```

**数据库连接：**
- 全局单例Database实例
- App生命周期结束时关闭连接

## 10. 未来扩展规划

### 10.1 WebDAV同步（预留架构）

**设计原则：**
- 加密文件上传，不上传明文
- 冲突检测和合并策略
- 本地优先，离线可用

**接口设计：**
```dart
abstract class SyncService {
  Future<void> uploadBackup(String filePath);
  Future<String> downloadBackup();
  Future<SyncStatus> checkSyncStatus();
  Future<void> resolveConflict(ConflictResolution resolution);
}

class WebDAVSyncService implements SyncService {
  final String serverUrl;
  final String username;
  final String password;

  // ... 实现 ...
}
```

**UI入口：**
- 设置页 → 同步设置
- 配置WebDAV服务器信息
- 手动/自动同步选项

### 10.2 桌面版支持

**优势：**
- Flutter天然支持macOS、Windows、Linux
- 代码复用率90%以上
- 需要适配的部分：
  - 窗口管理
  - 键盘快捷键
  - 系统托盘集成

### 10.3 密码强度检测

**功能：**
- 分析密码强度（弱/中/强）
- 检测常见密码
- 建议更新弱密码

### 10.4 密码泄露检测

**方案：**
- 集成Have I Been Pwned API
- 使用k-匿名技术保护隐私
- 仅检查密码哈希前缀

### 10.5 双因素认证（2FA）

**功能：**
- 存储TOTP密钥
- 生成6位验证码
- 倒计时显示

## 11. 安全审计与合规

### 11.1 安全最佳实践

**已实现：**
- ✅ 密码加盐哈希（PBKDF2 100000迭代）
- ✅ 数据库全盘加密（SQLCipher AES-256）
- ✅ 安全存储（Keychain/KeyStore）
- ✅ 自动锁定
- ✅ 剪贴板自动清理
- ✅ 防截图（Android FLAG_SECURE）

**建议审计：**
- 第三方安全审计（如有预算）
- 开源社区审查
- 定期更新依赖库

### 11.2 隐私保护

**数据收集：**
- ❌ 不收集任何用户数据
- ❌ 不使用分析工具
- ❌ 不连接任何服务器（初版）
- ✅ 所有数据本地存储

**隐私政策：**
```
本应用承诺：
1. 所有数据仅存储在您的设备上
2. 不收集、不上传任何个人信息
3. 不使用任何第三方追踪或分析服务
4. 主密码仅您一人知道，开发者无法访问
5. 开源代码，欢迎审计
```

## 12. 开发里程碑

### 12.1 MVP（最小可行产品）- v0.1

**功能范围：**
- ✅ 主密码设置和验证
- ✅ 生物识别（可选）
- ✅ 密码CRUD
- ✅ 分组管理
- ✅ 简单搜索
- ✅ 自动锁定
- ✅ 导出/导入（.apwd格式）

**目标：**
- 可用性验证
- 性能测试
- 收集反馈

### 12.2 稳定版 - v1.0

**增强功能：**
- 完善的错误处理
- 单元测试覆盖率>80%
- 集成测试关键流程
- 多语言支持（中英文）
- 暗黑模式
- 完整的文档

### 12.3 扩展版 - v1.x

**新功能：**
- WebDAV同步
- 密码强度检测
- 密码生成历史
- 2FA支持（TOTP）
- 桌面版

## 13. 技术债务和注意事项

### 13.1 已知限制

1. **密码长度限制**：单个密码最长1000字符（数据库TEXT类型）
2. **导出文件大小**：大量密码时文件可能较大，考虑压缩
3. **搜索性能**：1000+条目时LIKE查询可能变慢，考虑全文搜索
4. **生物识别回退**：部分老设备不支持，必须提供主密码选项

### 13.2 技术选型风险

**SQLCipher依赖：**
- 优点：成熟稳定，广泛使用
- 风险：原生依赖，增加打包复杂度
- 缓解：详细文档，CI/CD自动化

**Flutter版本：**
- 优点：活跃社区，快速迭代
- 风险：Breaking changes
- 缓解：锁定主要版本，定期升级

### 13.3 代码质量要求

**强制规范：**
- 所有public方法必须有文档注释
- 关键逻辑必须有单元测试
- 使用flutter_lints静态分析
- PR必须通过CI检查

**推荐实践：**
- 使用sealed class做状态管理
- 优先使用const构造函数
- 避免深层嵌套，提取子组件

## 14. 总结

本设计文档详细描述了一个**轻量、安全、易用**的密码管理应用。核心设计理念：

1. **安全第一**：AES-256加密、PBKDF2密钥派生、生物识别保护
2. **简单易用**：清晰的UI流程、直观的交互、最小学习成本
3. **本地优先**：100%本地运行、无需网络、隐私保护
4. **跨平台**：Flutter一套代码、iOS/Android原生性能
5. **可扩展**：预留WebDAV同步、桌面版、2FA等扩展能力

**技术栈成熟可靠**：Flutter + SQLCipher + local_auth，经过市场验证。

**开发复杂度可控**：三层架构清晰、职责分明、易于维护和测试。

**用户体验友好**：移动优先设计、符合平台规范、流畅自然。

该设计完全满足需求：**移动优先、轻量简洁、安全可靠、无自动填充**。
