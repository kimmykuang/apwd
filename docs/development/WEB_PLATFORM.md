# APWD - Web 平台说明

**最后更新**: 2026-03-21
**状态**: ❌ Web 平台不支持

---

## 🚨 重要说明

**APWD 不支持 Web 平台**

由于技术限制，APWD 密码管理器无法在 Web 浏览器中运行。

---

## ❌ 为什么不支持 Web

### 核心技术限制

APWD 使用 **SQLCipher** 进行加密数据库存储，该技术与 Web 平台不兼容。

| 组件 | 原生平台 | Web 平台 |
|------|----------|----------|
| **数据库** | SQLite + SQLCipher | IndexedDB |
| **加密** | 原生 SQLCipher | 需要 JS 实现 |
| **文件系统** | 本地文件系统 | 虚拟文件系统 |
| **生物识别** | Face ID/Touch ID | ❌ 不支持 |

---

### 技术细节

#### SQLCipher 依赖

APWD 使用 `sqflite_sqlcipher` 包：

```yaml
dependencies:
  sqflite_sqlcipher: ^2.2.0+1
```

**平台支持**:
- ✅ iOS
- ✅ Android
- ✅ macOS
- ✅ Windows
- ✅ Linux
- ❌ Web

#### 失败链路

当在 Web 上尝试设置主密码时：

1. 用户输入主密码
2. 调用 `authProvider.setupMasterPassword()`
3. 调用 `authService.setupMasterPassword()`
4. 调用 `databaseService.initialize()`
5. **失败**: 执行 SQLCipher PRAGMA 命令
   ```dart
   await db.rawQuery("PRAGMA key = \"x'$keyHex'\"");
   ```

**错误原因**: Web 浏览器不支持 SQLite/SQLCipher

---

## ✅ 支持的平台

### 移动平台

**iOS**
- ✅ 完整支持
- 最低版本: iOS 12.0+
- Face ID / Touch ID 支持

**Android**
- ✅ 完整支持
- 最低版本: Android 6.0+ (API 23)
- 指纹识别支持

---

### 桌面平台

**macOS**
- ✅ 完整支持
- 最低版本: macOS 10.14+
- Touch ID 支持

**Windows**
- ✅ 完整支持
- 最低版本: Windows 10+
- Windows Hello 支持

**Linux**
- ✅ 完整支持
- 最低版本: Ubuntu 20.04+

---

## 🚀 如何使用 APWD

### iOS / Android

```bash
# iOS（需要 Xcode 和 iOS 模拟器）
flutter run -d "iPhone 16 Pro"

# Android（需要 Android Studio 和模拟器）
flutter run -d emulator-5554
```

---

### macOS / Windows / Linux

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

---

## 💡 Web 平台的未来

### 可能的解决方案

#### 方案1: 使用 Drift 包

**Drift** (原 Moor) 是一个跨平台的数据库包：

```yaml
dependencies:
  drift: ^2.14.0
  drift_web: ^2.14.0  # Web 支持
```

**优势**:
- ✅ 支持所有平台（包括 Web）
- ✅ 在 Web 上使用 IndexedDB
- ✅ 在原生平台使用 SQLite
- ✅ 类型安全的查询

**挑战**:
- 需要完全重写数据库层
- 需要实现 Web 专用的加密层
- 需要迁移现有数据

---

#### 方案2: Web Crypto API

使用浏览器原生的 Web Crypto API 进行加密：

```dart
import 'dart:html' show window;
import 'package:web/web.dart';

// 使用 SubtleCrypto
final crypto = window.crypto!.subtle;
```

配合 IndexedDB 存储加密后的数据。

**挑战**:
- API 与原生加密不同
- 需要维护两套代码
- 数据格式不兼容

---

### 实施计划（如果未来支持 Web）

#### 阶段1: 评估（1-2 天）
- [ ] 测试 Drift 包
- [ ] 评估 Web Crypto API
- [ ] 制定迁移计划

#### 阶段2: 实现（1-2 周）
- [ ] 重写数据库层
- [ ] 实现 Web 加密
- [ ] 适配现有业务逻辑

#### 阶段3: 测试（3-5 天）
- [ ] 单元测试
- [ ] 集成测试
- [ ] 跨平台测试

#### 阶段4: 迁移（1 周）
- [ ] 数据迁移工具
- [ ] 向后兼容
- [ ] 用户文档

**总时间估计**: 3-4 周

**当前状态**: 未计划

---

## 🔒 安全性考虑

### 为什么不能简单地使用 IndexedDB？

1. **加密强度**: SQLCipher 提供军事级加密，IndexedDB 没有内置加密
2. **密钥管理**: 原生平台有 Keychain/Keystore，Web 只有 LocalStorage（不安全）
3. **数据隔离**: 原生平台的应用沙盒更安全
4. **生物识别**: Web 无法使用 Face ID/Touch ID

---

### Web 平台的安全挑战

**浏览器限制**:
- 无法访问系统 Keychain
- LocalStorage/SessionStorage 不够安全
- 容易被浏览器扩展读取
- XSS 攻击风险更高

**结论**: 对于密码管理器这种对安全性要求极高的应用，原生平台更合适。

---

## 📋 当前实现

### Platform Check

APWD 在启动时检查平台：

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  if (kIsWeb) {
    runApp(const UnsupportedPlatformScreen());
    return;
  }
  runApp(const MyApp());
}
```

---

### Unsupported Platform Screen

当在 Web 上运行时，显示友好的错误提示：

```
╔════════════════════════════════════╗
║   Web Platform Not Supported      ║
╠════════════════════════════════════╣
║                                    ║
║  APWD uses SQLCipher for          ║
║  encrypted storage, which is      ║
║  not compatible with Web.         ║
║                                    ║
║  Please use on:                   ║
║  • iOS / Android                  ║
║  • macOS / Windows / Linux        ║
║                                    ║
╚════════════════════════════════════╝
```

---

## ❓ FAQ

### Q: 可以用 LocalStorage 代替吗？

A: 不推荐。LocalStorage 没有加密，容易被浏览器扩展读取，不适合存储敏感数据。

---

### Q: 可以用云端存储吗？

A: APWD 设计理念是"本地优先"，所有数据都存储在本地设备上，不依赖云端。这是核心安全特性。

---

### Q: 其他密码管理器怎么做的？

A: 大多数主流密码管理器（如 1Password、Bitwarden）使用云同步，数据存储在云端服务器。APWD 选择了本地存储路线，因此 Web 支持更具挑战性。

---

### Q: 未来会支持 Web 吗？

A: 可能会，但不是优先级。需要评估用户需求和实现成本。

---

## 📚 相关文档

- [iOS 环境配置](./IOS_SETUP.md)
- [测试文档](../testing/TESTING.md)
- [README.md](../../README.md)

---

## 🔗 参考资料

- [sqflite_sqlcipher 文档](https://pub.dev/packages/sqflite_sqlcipher)
- [Drift 包（跨平台方案）](https://pub.dev/packages/drift)
- [Web Crypto API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Crypto_API)
- [Flutter 平台检测](https://api.flutter.dev/flutter/foundation/kIsWeb-constant.html)

---

**维护者**: AI Agent
**状态**: Web 平台不支持
**原因**: SQLCipher 不兼容 Web
