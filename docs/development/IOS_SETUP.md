# APWD - iOS 开发环境配置

**最后更新**: 2026-03-21
**适用于**: Xcode 14+, iOS 12.0+

---

## 📱 iOS 环境设置

### 1. 安装 Xcode

**方法1: App Store（推荐）**

1. 打开 App Store
2. 搜索 "Xcode"
3. 点击"获取"
4. 等待下载（约 15GB，需要 1-2 小时）

**方法2: Apple 开发者网站**

访问: https://developer.apple.com/download/
下载 Xcode 14.x+

**安装后配置**:

```bash
# 设置 Xcode 路径
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# 首次启动配置
sudo xcodebuild -runFirstLaunch

# 接受许可协议
sudo xcodebuild -license accept

# 验证安装
xcodebuild -version
```

---

### 2. 安装 iOS Runtime

**为什么需要**: iOS Runtime 是 iOS 模拟器的操作系统，没有它无法运行 iOS 模拟器。

**方法1: 通过 Xcode GUI（推荐）**

1. 打开 Xcode
2. 进入 `Xcode` -> `Settings` (或 `Preferences`)
3. 点击 `Platforms` 标签
4. 找到 `iOS` 平台（如 iOS 18.2）
5. 点击右侧的**下载图标** (↓)
6. 等待下载完成（约 8GB，需要 30-60 分钟）

**方法2: 命令行安装**

```bash
# 下载 iOS Platform
xcodebuild -downloadPlatform iOS

# 或安装特定版本
xcodebuild -downloadPlatform iOS -buildVersion 18.2
```

**验证安装**:

```bash
# 查看已安装的 Runtimes
xcrun simctl list runtimes

# 应该看到类似:
# == Runtimes ==
# iOS 18.2 (18.2 - 22C5131e) - com.apple.CoreSimulator.SimRuntime.iOS-18-2
```

---

### 3. 验证模拟器

```bash
# 查看所有可用的模拟器
xcrun simctl list devices available

# 应该看到:
# == Devices ==
# -- iOS 18.2 --
#     iPhone 16 Pro (UDID) (Shutdown)
#     iPhone 16 (UDID) (Shutdown)
#     ...
```

---

## 🚀 iOS 模拟器操作

### 启动和关闭模拟器

```bash
# 启动特定模拟器
xcrun simctl boot "iPhone 16 Pro"

# 打开 Simulator 应用（图形界面）
open -a Simulator

# 同时启动模拟器并打开应用
xcrun simctl boot "iPhone 16 Pro" && open -a Simulator

# 关闭特定模拟器
xcrun simctl shutdown "iPhone 16 Pro"

# 关闭所有模拟器
xcrun simctl shutdown all
```

---

### 安装和管理应用

```bash
# 安装应用到模拟器
xcrun simctl install "iPhone 16 Pro" build/ios/iphonesimulator/Runner.app

# 使用 Flutter 安装
flutter install -d "iPhone 16 Pro"

# 卸载应用
xcrun simctl uninstall "iPhone 16 Pro" com.example.apwd

# 启动应用
xcrun simctl launch "iPhone 16 Pro" com.example.apwd

# 停止应用
xcrun simctl terminate "iPhone 16 Pro" com.example.apwd
```

---

### 清理和重置

```bash
# 清理应用数据（卸载应用）
xcrun simctl uninstall "iPhone 16 Pro" com.example.apwd

# 清除模拟器所有数据（恢复出厂设置）
xcrun simctl erase "iPhone 16 Pro"

# 清除所有模拟器数据
xcrun simctl erase all
```

---

### 截图和日志

```bash
# 截图
xcrun simctl io "iPhone 16 Pro" screenshot screenshot.png

# 实时查看应用日志
xcrun simctl spawn "iPhone 16 Pro" log stream --predicate 'processImagePath contains "Runner"' --level debug

# 查看最近10分钟的日志
xcrun simctl spawn "iPhone 16 Pro" log show --predicate 'subsystem contains "flutter"' --last 10m
```

---

## 🎯 APWD 项目专用命令

### 快速启动 APWD

```bash
# 清理并重新运行
xcrun simctl uninstall "iPhone 16 Pro" com.example.apwd && \
flutter run -d "iPhone 16 Pro"

# 直接运行（如果已安装）
flutter run -d "iPhone 16 Pro"
```

---

### 查看 APWD 日志

```bash
# 查看应用日志（过滤关键字）
xcrun simctl spawn "iPhone 16 Pro" log stream \
  --predicate 'processImagePath contains "Runner"' \
  --level debug | grep -E "(error|Error|EXCEPTION|password|group)"
```

---

### 清理 APWD 数据

```bash
# 卸载应用（会删除数据库）
xcrun simctl uninstall "iPhone 16 Pro" com.example.apwd

# 重新安装并运行
flutter run -d "iPhone 16 Pro"
```

---

### 查看数据库文件

```bash
# 获取应用数据目录
DATA_DIR=$(xcrun simctl get_app_container "iPhone 16 Pro" com.example.apwd data)

# 打开数据目录
open "$DATA_DIR"

# 查找数据库文件
find "$DATA_DIR" -name "*.db"

# 使用 SQLite 查看数据库（需要 SQLCipher）
# 注意：加密数据库需要密钥才能打开
sqlite3 "$DATA_DIR/Documents/password_manager.db"
```

---

## 🧪 运行自动化测试

### 集成测试

```bash
# 运行集成测试
flutter test integration_test/app_test.dart -d "iPhone 16 Pro"

# 运行完整自闭环测试
python3 autonomous_test_runner.py ios
```

---

### 完整的清理重装流程

```bash
# 1. 卸载旧应用
xcrun simctl uninstall "iPhone 16 Pro" com.example.apwd

# 2. 构建新应用
flutter build ios --simulator --debug

# 3. 安装新应用
xcrun simctl install "iPhone 16 Pro" build/ios/iphonesimulator/Runner.app

# 4. 启动应用
xcrun simctl launch "iPhone 16 Pro" com.example.apwd
```

---

## 🔧 常见问题

### 问题1: iOS Runtime 未安装

**症状**:
```bash
$ xcrun simctl list runtimes
== Runtimes ==
(空)
```

**解决**: 在 Xcode -> Settings -> Platforms 中下载 iOS Runtime

---

### 问题2: 模拟器无法启动

**症状**: 启动命令无响应

**解决**:
```bash
# 强制关闭所有模拟器进程
killall Simulator

# 清除模拟器缓存
xcrun simctl shutdown all
xcrun simctl erase all
```

---

### 问题3: 应用安装失败

**症状**: `flutter run` 报错

**解决**:
```bash
# 清理 Flutter 缓存
flutter clean

# 重新获取依赖
flutter pub get

# 重新构建
flutter build ios --simulator --debug
```

---

### 问题4: 找不到设备

**症状**: `xcrun simctl list devices` 显示设备不可用

**解决**:
```bash
# 确认设备存在
xcrun simctl list devices available

# 如果没有 iPhone 16 Pro，使用其他可用设备
xcrun simctl list devices available | grep "iPhone"

# 创建新设备（如果需要）
xcrun simctl create "My iPhone" "iPhone 16 Pro" "iOS-18-2"
```

---

## 💡 高级技巧

### 使用 UDID 而不是名称

```bash
# 获取 UDID
UDID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

# 使用 UDID 操作
xcrun simctl boot $UDID
```

---

### 批量操作多个模拟器

```bash
# 关闭所有 iPhone 模拟器
xcrun simctl list devices | grep "iPhone" | grep Booted | \
  grep -oE '\([A-F0-9-]+\)' | tr -d '()' | \
  xargs -I {} xcrun simctl shutdown {}
```

---

### 录屏

```bash
# 开始录屏
xcrun simctl io "iPhone 16 Pro" recordVideo ~/Desktop/recording.mp4

# 停止录制（按 Ctrl+C）
```

---

## 📚 参考资料

### 查看完整的 simctl 帮助

```bash
# 查看所有命令
xcrun simctl help

# 查看特定命令的帮助
xcrun simctl help boot
xcrun simctl help install
xcrun simctl help launch
```

---

## 📊 下载信息

| 组件 | 大小 | 时间估计 |
|------|------|----------|
| Xcode | ~15 GB | 1-2 小时 |
| iOS Runtime | ~8 GB | 30-60 分钟 |

---

## ✅ 快速验证清单

```bash
# 1. 验证 Xcode
xcodebuild -version

# 2. 验证 iOS Runtime
xcrun simctl list runtimes | grep iOS

# 3. 验证模拟器
xcrun simctl list devices available | grep iPhone

# 4. 验证 Flutter
flutter doctor -v

# 5. 运行测试应用
flutter run -d "iPhone 16 Pro"
```

---

**维护者**: AI Agent
**联系方式**: 查看 README.md
