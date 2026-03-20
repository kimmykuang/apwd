# iOS Runtime 未安装问题

## 🔍 问题诊断

**状态**: Xcode 16.2 已安装 ✅
**问题**: iOS Runtime 未安装 ❌

```bash
$ xcrun simctl list runtimes
== Runtimes ==
(空的 - 没有可用的 iOS runtime)
```

## 📦 需要安装 iOS Runtime

### 方法1: 通过 Xcode GUI（推荐，最简单）

1. **打开 Xcode**

2. **进入 Settings/Preferences**:
   - 菜单: `Xcode` -> `Settings...` (或 `Preferences...`)
   - 或快捷键: `Cmd + ,`

3. **进入 Platforms 标签页**:
   - 点击顶部的 `Platforms` 标签

4. **下载 iOS Runtime**:
   - 找到 `iOS` 平台（通常是最新版本，如 iOS 18.2）
   - 点击右侧的 **下载图标** (↓)
   - 等待下载完成（约 7-8 GB，需要 30-60 分钟）

5. **验证安装**:
   ```bash
   xcrun simctl list runtimes
   # 应该看到类似:
   # iOS 18.2 (18.2 - 22C5131e) - com.apple.CoreSimulator.SimRuntime.iOS-18-2
   ```

---

### 方法2: 命令行安装（更快，推荐给高级用户）

```bash
# 1. 列出可下载的 runtime
xcodebuild -downloadPlatform iOS

# 2. 或者使用 xcrun 安装
xcrun simctl runtime add "iOS"

# 3. 验证
xcrun simctl list runtimes
```

---

### 方法3: 手动安装特定版本

```bash
# 安装 iOS 18.x runtime（推荐）
xcodebuild -downloadPlatform iOS -buildVersion 18.2

# 或安装 iOS 17.x runtime
xcodebuild -downloadPlatform iOS -buildVersion 17.5
```

---

## ✅ 安装完成后

### 1. 验证 Runtime 已安装

```bash
xcrun simctl list runtimes
```

**预期输出**:
```
== Runtimes ==
iOS 18.2 (18.2 - 22C5131e) - com.apple.CoreSimulator.SimRuntime.iOS-18-2
  Identifier: com.apple.CoreSimulator.SimRuntime.iOS-18-2
  Version: 18.2
  ...
```

### 2. 验证模拟器可用

```bash
xcrun simctl list devices | grep "iPhone" | grep -v "unavailable"
```

**预期输出**:
```
iPhone 16 Pro (xxx-xxx-xxx) (Shutdown)
iPhone 16 (xxx-xxx-xxx) (Shutdown)
iPhone 15 Pro (xxx-xxx-xxx) (Shutdown)
...
```

### 3. 重新运行验证脚本

```bash
./verify_setup.sh
```

**预期看到**:
```
✅ iOS 模拟器
   X 个可用设备  # X > 0
```

### 4. 启动自动化测试

```bash
./autonomous_test_runner.py ios
```

---

## 🎯 快速操作指南

```bash
# 1. 打开 Xcode
open -a Xcode

# 2. 在 Xcode 中:
#    Xcode -> Settings -> Platforms -> 下载 iOS

# 3. 下载完成后，关闭 Xcode

# 4. 验证安装
xcrun simctl list runtimes

# 5. 运行自动化测试
./autonomous_test_runner.py ios
```

---

## 💡 为什么需要 iOS Runtime？

- **Xcode** = 开发工具和编译器
- **iOS Runtime** = 模拟器的操作系统

就像你需要：
- 安装 VirtualBox（虚拟机软件）
- 再下载 macOS.iso（操作系统镜像）

Xcode 是虚拟机软件，iOS Runtime 是操作系统镜像。

---

## 📊 下载信息

| Runtime | 大小 | 时间估计 |
|---------|------|----------|
| iOS 18.x | ~8 GB | 30-60 分钟 |
| iOS 17.x | ~7 GB | 30-60 分钟 |

---

## 🔧 常见问题

### Q: 下载很慢怎么办？
A: iOS Runtime 下载速度取决于 Apple 服务器。可以：
- 等待非高峰时段下载
- 确保网络连接稳定
- 使用有线网络而非 WiFi

### Q: 需要下载哪个版本？
A: 推荐下载最新的稳定版本（如 iOS 18.2）

### Q: 可以同时安装多个 Runtime 吗？
A: 可以！如果需要测试不同 iOS 版本的兼容性

### Q: 下载后占用多少空间？
A: 每个 iOS Runtime 约占用 8-10 GB

---

**下一步**: 在 Xcode 中下载 iOS Runtime，完成后运行 `./autonomous_test_runner.py ios`
