# APWD - Android 真机测试环境配置

**最后更新**: 2026-03-21
**适用于**: macOS, Android 6.0+

---

## 📋 当前状态

根据 `flutter doctor` 检查结果：
- ❌ Android toolchain 未安装
- ❌ Android SDK 未找到
- ❌ ADB 工具未安装

---

## 🎯 需要安装的组件

### 1. Android Studio（必需）

**作用**: 提供 Android SDK、构建工具、ADB 等核心组件

**安装方法1: Homebrew（推荐）**

```bash
# 安装 Android Studio
brew install --cask android-studio

# 等待安装完成（约 1-2 分钟）
```

**安装方法2: 手动下载**

1. 访问: https://developer.android.com/studio
2. 下载 macOS 版本（约 1GB）
3. 拖动到 Applications 文件夹

---

### 2. Android SDK 配置

**首次启动 Android Studio**:

```bash
# 方法1: 命令行启动
open -a "Android Studio"

# 方法2: 从 Applications 文件夹打开
```

**安装向导步骤**:

1. ✅ **欢迎页面** → 点击 "Next"
2. ✅ **Install Type** → 选择 "Standard"（标准安装）
3. ✅ **SDK Components** → 确认勾选：
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device
4. ✅ **下载组件** → 等待下载（约 3-4 GB，需要 15-30 分钟）
5. ✅ **完成** → 点击 "Finish"

**安装位置**（默认）:
```
~/Library/Android/sdk
```

---

### 3. 配置环境变量

**添加到 Shell 配置文件**:

```bash
# 打开配置文件（根据您使用的 shell）
# 如果使用 zsh（macOS 默认）:
nano ~/.zshrc

# 如果使用 bash:
nano ~/.bash_profile
```

**添加以下内容**:

```bash
# Android SDK
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

**保存并重新加载**:

```bash
# 保存文件（Ctrl+X, Y, Enter）

# 重新加载配置
source ~/.zshrc  # 或 source ~/.bash_profile
```

---

### 4. 配置 Flutter Android SDK

```bash
# 让 Flutter 知道 Android SDK 位置
flutter config --android-sdk ~/Library/Android/sdk

# 验证配置
flutter doctor -v
```

**期望输出**:
```
[✓] Android toolchain - develop for Android devices (Android SDK version 34.x.x)
    • Android SDK at ~/Library/Android/sdk
    • Platform android-34, build-tools 34.0.0
    • Java binary at: /Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java
    • Java version OpenJDK Runtime Environment (build 17.x.x)
```

---

## 📱 Android 手机配置

### 1. 启用开发者选项

**步骤**（大多数 Android 手机通用）:

1. 打开 **设置** → **关于手机**
2. 找到 **版本号** 或 **内部版本号**
3. **连续点击 7 次** 版本号
4. 看到提示 "您已处于开发者模式"

**不同品牌位置**:
- **小米**: 设置 → 我的设备 → 全部参数 → MIUI 版本（点击7次）
- **华为**: 设置 → 关于手机 → 版本号（点击7次）
- **OPPO**: 设置 → 关于手机 → 版本号（点击7次）
- **vivo**: 设置 → 更多设置 → 关于手机 → 软件版本号（点击7次）
- **三星**: 设置 → 关于手机 → 软件信息 → 版本号（点击7次）

---

### 2. 启用 USB 调试

**步骤**:

1. 打开 **设置** → **系统** → **开发者选项**
2. 开启 **开发者选项** 总开关
3. 开启 **USB 调试**
4. （可选）开启 **USB 安装**（允许通过 USB 安装应用）

**重要设置**（推荐）:

```
✅ USB 调试
✅ USB 安装
✅ 保持唤醒状态（充电时屏幕不会休眠）
❌ 不要开启 "验证应用通过 USB 安装"（会阻止调试）
```

---

### 3. 连接手机到电脑

**使用 USB 数据线连接**:

1. 用 **USB 数据线** 连接手机到 Mac
2. 手机屏幕会弹出 "允许 USB 调试吗？"
3. 勾选 **"一律允许使用这台计算机进行调试"**
4. 点击 **"允许"**

**验证连接**:

```bash
# 检查设备是否连接
adb devices

# 应该看到类似输出:
# List of devices attached
# ABC123456789    device
```

**如果显示 "unauthorized"**:
- 手机上没有授权
- 重新插拔 USB
- 在手机上点击"允许"

**如果看不到设备**:
```bash
# 重启 ADB 服务
adb kill-server
adb start-server

# 再次检查
adb devices
```

---

## ✅ 验证安装

### 完整验证脚本

```bash
# 1. 检查 Flutter
echo "=== Flutter ==="
flutter --version

# 2. 检查 Android SDK
echo -e "\n=== Android SDK ==="
echo $ANDROID_HOME
ls $ANDROID_HOME

# 3. 检查 ADB
echo -e "\n=== ADB ==="
which adb
adb version

# 4. 检查连接的设备
echo -e "\n=== Connected Devices ==="
adb devices

# 5. 运行 Flutter Doctor
echo -e "\n=== Flutter Doctor ==="
flutter doctor -v
```

**保存为脚本并运行**:

```bash
# 创建验证脚本
cat > verify_android.sh << 'EOF'
#!/bin/bash
echo "=== Flutter ==="
flutter --version
echo -e "\n=== Android SDK ==="
echo $ANDROID_HOME
ls $ANDROID_HOME
echo -e "\n=== ADB ==="
which adb
adb version
echo -e "\n=== Connected Devices ==="
adb devices
echo -e "\n=== Flutter Doctor ==="
flutter doctor -v
EOF

# 执行验证
chmod +x verify_android.sh
./verify_android.sh
```

---

## 🚀 运行 APWD 应用

### 方法1: Flutter Run（推荐）

```bash
# 1. 确认设备已连接
flutter devices

# 应该看到:
# Android SDK built for arm64 (mobile) • ABC123456789 • android-arm64 • Android 14 (API 34)

# 2. 运行应用
flutter run

# Flutter 会自动选择连接的 Android 设备
```

---

### 方法2: 指定设备运行

```bash
# 获取设备 ID
DEVICE_ID=$(adb devices | grep device | head -1 | awk '{print $1}')

# 运行应用
flutter run -d $DEVICE_ID
```

---

### 方法3: 构建 APK 并手动安装

```bash
# 1. 构建 Debug APK
flutter build apk --debug

# APK 位置:
# build/app/outputs/flutter-apk/app-debug.apk

# 2. 安装到手机
adb install build/app/outputs/flutter-apk/app-debug.apk

# 3. 启动应用
adb shell am start -n com.example.apwd/.MainActivity
```

---

## ⚠️ Debug 模式 vs Release 模式（重要！）

### 问题：为什么断开 USB 后应用显示 "Lost connection to device"？

当使用 `flutter run` 运行应用时，应用处于 **Debug 模式**：
- ✅ Flutter 通过 ADB 保持与设备的连接（用于 hot reload、调试）
- ❌ 当 USB 断开时，Flutter 显示 "Lost connection to device"
- ❌ 看起来像是应用崩溃，但其实是**调试连接断开**

**这不是 Bug！这是 Debug 模式的正常行为。**

---

### 解决方案：使用 Release 模式测试

真实用户使用的是 **Release 模式**，不需要 USB 连接。

#### 方法1: 构建 Release APK（推荐用于真机测试）

```bash
# 1. 完全卸载旧版本
adb uninstall com.apwd.apwd

# 2. 构建 Release APK
flutter build apk --release

# 3. 安装到手机
adb install build/app/outputs/flutter-apk/app-release.apk

# 4. 现在可以拔掉 USB 线了！
# 在手机上打开应用，设置主密码，关闭应用，重新打开输入密码
# 应用会正常工作，不会有 "Lost connection" 错误
```

---

#### 方法2: Profile 模式（保留部分调试功能）

```bash
# 运行 Profile 模式
flutter run --profile -d <设备ID>

# 断开 USB 后应用会继续运行
```

---

#### 方法3: Release 模式直接运行

```bash
# 运行 Release 模式
flutter run --release -d <设备ID>

# 注意：Release 模式没有 hot reload
```

---

### Debug vs Release 对比

| 特性 | Debug 模式 | Release 模式 |
|-----|-----------|-------------|
| **命令** | `flutter run` | `flutter run --release` |
| **Hot Reload** | ✅ 支持 | ❌ 不支持 |
| **需要 USB** | ✅ 必须保持连接 | ❌ 不需要 |
| **性能** | 较慢（未优化） | 快速（已优化） |
| **应用大小** | 较大 | 较小 |
| **调试功能** | ✅ 完整 | ❌ 无 |
| **真实使用场景** | ❌ 开发测试 | ✅ 最终用户 |
| **断开 USB** | 显示连接丢失 | 正常运行 |

---

### 推荐的测试流程

**开发阶段**（快速迭代）：
```bash
# 使用 Debug 模式，保持 USB 连接
flutter run -d <设备ID>

# 可以使用 hot reload (按 r)
```

**真机测试**（完整功能测试）：
```bash
# 1. 构建 Release APK
flutter build apk --release

# 2. 安装
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 3. 拔掉 USB，在手机上测试所有功能
```

---

### 常见问题

#### Q: 为什么我设置主密码后，断开 USB 输入密码显示 "invalid password"？

A: 这通常是因为：
1. **Debug 模式连接丢失**：改用 Release APK 测试
2. **旧的 secure storage 数据**：完全卸载应用再安装

**解决步骤**：
```bash
# 1. 完全卸载（清除所有数据）
adb uninstall com.apwd.apwd

# 2. 安装 Release 版本
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# 3. 拔掉 USB 线

# 4. 在手机上测试：
#    - 设置主密码
#    - 关闭应用
#    - 重新打开并输入密码
#    - ✅ 应该能成功解锁
```

---

#### Q: Debug 模式下能测试密码功能吗？

A: 可以，但**必须保持 USB 连接**：
- ✅ 设置主密码
- ✅ 不要断开 USB
- ✅ 在应用内关闭并重新打开（不要完全退出）
- ✅ 输入密码测试

如果要测试完整的"关闭应用重新打开"流程，必须使用 **Release APK**。

---

## 🧪 运行自动化测试（真机）

### 集成测试

```bash
# 确保设备已连接
adb devices

# 运行集成测试
flutter test integration_test/app_test.dart
```

---

### 查看应用日志

```bash
# 实时查看日志
adb logcat | grep -i flutter

# 只看错误
adb logcat *:E | grep -i flutter

# 清除日志并重新开始
adb logcat -c && adb logcat | grep -i flutter
```

---

## 🔧 常用 ADB 命令

### 设备管理

```bash
# 查看连接的设备
adb devices

# 重启 ADB 服务
adb kill-server
adb start-server

# 查看设备信息
adb shell getprop ro.build.version.release  # Android 版本
adb shell getprop ro.product.model          # 设备型号
```

---

### 应用管理

```bash
# 安装应用
adb install app-debug.apk

# 卸载应用
adb uninstall com.example.apwd

# 查看已安装的应用
adb shell pm list packages | grep apwd

# 启动应用
adb shell am start -n com.example.apwd/.MainActivity

# 停止应用
adb shell am force-stop com.example.apwd
```

---

### 文件操作

```bash
# 从手机复制文件到电脑
adb pull /sdcard/Download/file.txt ~/Desktop/

# 从电脑复制文件到手机
adb push ~/Desktop/file.txt /sdcard/Download/

# 查看应用数据目录
adb shell run-as com.example.apwd ls /data/data/com.example.apwd/
```

---

### 截图和录屏

```bash
# 截图
adb shell screencap /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ~/Desktop/

# 录屏（最长 3 分钟）
adb shell screenrecord /sdcard/recording.mp4
# 按 Ctrl+C 停止录制
adb pull /sdcard/recording.mp4 ~/Desktop/
```

---

## 🐛 常见问题

### 问题1: adb: command not found

**原因**: 环境变量未配置

**解决**:
```bash
# 检查 Android SDK 是否存在
ls ~/Library/Android/sdk

# 添加到 PATH
export PATH=$PATH:~/Library/Android/sdk/platform-tools

# 或重新配置环境变量（见上文）
```

---

### 问题2: device unauthorized

**原因**: 手机未授权 USB 调试

**解决**:
1. 重新插拔 USB 线
2. 手机上会再次弹出授权对话框
3. 勾选 "一律允许"，点击 "允许"
4. 运行 `adb devices` 验证

---

### 问题3: no devices/emulators found

**原因**: 设备未连接或 ADB 未识别

**解决**:
```bash
# 1. 重启 ADB
adb kill-server
adb start-server

# 2. 检查 USB 线是否支持数据传输
# 有些充电线不支持数据传输

# 3. 尝试不同的 USB 端口

# 4. 检查手机的 USB 模式
# 设置 → USB → 选择 "文件传输" 或 "MTP"
```

---

### 问题4: Gradle 构建失败

**原因**: Gradle 下载慢或配置问题

**解决**:
```bash
# 1. 清理 Gradle 缓存
cd android
./gradlew clean

# 2. 重新构建
flutter clean
flutter pub get
flutter build apk --debug

# 3. 如果还是失败，配置国内镜像（可选）
# 编辑 android/build.gradle
```

---

### 问题5: 手机找不到"开发者选项"

**原因**: 不同品牌位置不同

**解决**:
- 搜索 "您的手机品牌 + 开发者选项"
- 或在设置中搜索 "开发者"

---

### 问题6: Java 版本警告（源值 8 已过时）

**症状**:
```
警告: [options] 源值 8 已过时，将在未来发行版中删除
警告: [options] 目标值 8 已过时，将在未来发行版中删除
```

**原因**: Gradle 使用了旧的 Java 版本

**解决**:

1. 在 `android/gradle.properties` 中添加：
```properties
org.gradle.java.home=/Applications/Android Studio.app/Contents/jbr/Contents/Home
```

2. 清理并重新构建：
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

### 问题7: "Lost connection to device" 断开 USB 后应用停止

**症状**:
- 使用 `flutter run` 运行应用
- 断开 USB 线后显示 "Lost connection to device"
- 看起来像应用崩溃

**原因**: Debug 模式需要保持 USB 连接进行调试

**解决**: 使用 Release 模式测试（详见上文 "Debug 模式 vs Release 模式" 章节）

```bash
# 构建并安装 Release APK
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 现在可以断开 USB，应用会正常运行
```

---

### 问题8: 设置主密码后重新打开显示 "invalid password"

**可能原因**:
1. **Debug 模式连接丢失**（最常见）
2. 重装应用后旧的 secure storage 数据未清除
3. 真的输入了错误密码

**解决步骤**:

```bash
# 1. 完全卸载应用（清除所有数据）
adb uninstall com.apwd.apwd

# 2. 构建并安装 Release 版本
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# 3. 断开 USB 线

# 4. 在手机上测试完整流程
```

---

## 📊 安装时间估计

| 步骤 | 时间 |
|-----|------|
| 下载 Android Studio | 5-10 分钟 |
| 首次启动配置 | 15-30 分钟 |
| 配置环境变量 | 2 分钟 |
| 手机开发者设置 | 3 分钟 |
| 验证和测试 | 5 分钟 |
| **总计** | **30-50 分钟** |

---

## ✅ 安装清单

**电脑端**:
- [ ] 安装 Android Studio
- [ ] 配置 Android SDK
- [ ] 配置环境变量
- [ ] 验证 `flutter doctor`
- [ ] 验证 `adb devices`

**手机端**:
- [ ] 启用开发者选项
- [ ] 启用 USB 调试
- [ ] 启用 USB 安装
- [ ] 连接并授权电脑

**测试**:
- [ ] 运行 `adb devices` 看到设备
- [ ] 运行 `flutter run` 成功启动应用
- [ ] 应用在手机上正常运行

---

## 🎯 快速开始命令

```bash
# 1. 安装 Android Studio
brew install --cask android-studio

# 2. 打开并完成配置向导
open -a "Android Studio"

# 3. 配置环境变量
echo 'export ANDROID_HOME=~/Library/Android/sdk' >> ~/.zshrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.zshrc
source ~/.zshrc

# 4. 配置 Flutter
flutter config --android-sdk ~/Library/Android/sdk

# 5. 连接手机并授权

# 6. 验证
adb devices
flutter doctor -v

# 7. 运行应用
flutter run
```

---

## 📚 相关文档

- [iOS 环境配置](./IOS_SETUP.md)
- [测试文档](../testing/TESTING.md)
- [README.md](../../README.md)

---

## 🔗 官方资源

- [Android Studio 下载](https://developer.android.com/studio)
- [Flutter Android 设置](https://flutter.dev/docs/get-started/install/macos#android-setup)
- [ADB 用户指南](https://developer.android.com/tools/adb)

---

**维护者**: AI Agent
**最后更新**: 2026-03-21
**测试设备**: Android 6.0+
