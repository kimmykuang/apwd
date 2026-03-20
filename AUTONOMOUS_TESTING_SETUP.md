# 自闭环自动化测试环境配置指南

## 🎯 目标

让 Claude/AI Agent 能够完全自主地：
1. ✅ 启动模拟器（iOS/Android）
2. ✅ 运行应用
3. ✅ 执行自动化测试
4. ✅ 收集截图和日志
5. ✅ 分析问题
6. ✅ 修复代码
7. ✅ 重新测试验证

**完全无需人工干预**

---

## 📦 必需工具清单

### 1. iOS 模拟器支持（推荐优先安装）

#### ✅ Xcode（必需）

**为什么需要**:
- 提供 iOS 模拟器
- 允许命令行启动和控制模拟器
- 支持自动化截图和日志收集

**安装步骤**:

```bash
# 方法1: 通过 App Store 安装（推荐）
# 1. 打开 App Store
# 2. 搜索 "Xcode"
# 3. 点击"获取"并等待下载（约15GB，需要1-2小时）

# 方法2: 命令行下载（需要 Apple ID）
# 访问: https://developer.apple.com/download/
# 下载 Xcode 15.x.xip

# 安装后配置
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept

# 验证安装
xcodebuild -version
# 应该显示: Xcode 15.x

# 安装 iOS 模拟器
# Xcode -> Settings -> Platforms -> iOS 17.x (下载)
```

**自动化能力**:
```bash
# 列出所有模拟器
xcrun simctl list devices

# 启动特定模拟器
xcrun simctl boot "iPhone 15 Pro"

# 安装应用
xcrun simctl install booted /path/to/app.app

# 启动应用
xcrun simctl launch booted com.example.apwd

# 截图
xcrun simctl io booted screenshot screenshot.png

# 获取日志
xcrun simctl spawn booted log stream --predicate 'subsystem contains "com.example.apwd"'

# 关闭模拟器
xcrun simctl shutdown all
```

---

### 2. Android 模拟器支持（可选，跨平台测试）

#### ✅ Android Studio（推荐）或 Android SDK

**为什么需要**:
- 提供 Android 模拟器（AVD）
- 支持命令行控制
- 完整的调试和日志工具

**安装步骤**:

```bash
# 方法1: Homebrew 安装（推荐）
brew install --cask android-studio

# 方法2: 手动下载
# 访问: https://developer.android.com/studio
# 下载并安装（约1GB）

# 首次启动 Android Studio
# 1. 选择 "Standard" 安装类型
# 2. 等待 Android SDK、Platform Tools 下载（约4GB）
# 3. 完成后关闭 Android Studio

# 配置环境变量
echo 'export ANDROID_HOME=~/Library/Android/sdk' >> ~/.zshrc
echo 'export PATH=$PATH:$ANDROID_HOME/emulator' >> ~/.zshrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.zshrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' >> ~/.zshrc
source ~/.zshrc

# 配置 Flutter
flutter config --android-sdk ~/Library/Android/sdk

# 验证安装
flutter doctor -v
# 应该显示: Android toolchain ✓
```

**创建和管理模拟器**:

```bash
# 列出可用的系统镜像
sdkmanager --list | grep system-images

# 下载 Android 14 系统镜像（推荐）
sdkmanager "system-images;android-34;google_apis;arm64-v8a"

# 创建 AVD（Android Virtual Device）
avdmanager create avd \
  --name "Pixel_7_API_34" \
  --package "system-images;android-34;google_apis;arm64-v8a" \
  --device "pixel_7"

# 列出所有 AVD
avdmanager list avd

# 启动模拟器（命令行，无窗口）
emulator -avd Pixel_7_API_34 -no-window -no-audio -no-boot-anim &

# 启动模拟器（有窗口）
emulator -avd Pixel_7_API_34 &

# 等待启动完成
adb wait-for-device

# 安装应用
flutter install -d emulator-5554

# 截图
adb exec-out screencap -p > screenshot.png

# 获取日志
adb logcat *:E  # 只显示错误
adb logcat | grep -i flutter

# 关闭模拟器
adb emu kill
```

---

### 3. Flutter 集成测试框架（必需）

#### ✅ integration_test 包（Flutter 自带）

**为什么需要**:
- 原生 Flutter 测试支持
- 可以模拟用户操作
- 自动化截图和断言
- 无需额外配置

**配置步骤**:

```bash
# 1. 添加依赖（已在 pubspec.yaml 中）
# dev_dependencies:
#   integration_test:
#     sdk: flutter

# 2. 创建测试目录
mkdir -p integration_test

# 3. 创建测试文件（见下文示例）
```

**测试文件示例**: `integration_test/app_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:apwd/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('APWD 完整流程测试', () {
    testWidgets('场景1: 首次设置主密码', (WidgetTester tester) async {
      // 1. 启动应用
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // 2. 等待启动页完成
      await tester.pumpAndSettle(Duration(seconds: 2));

      // 3. 应该看到设置密码页面
      expect(find.text('设置主密码'), findsOneWidget);

      // 4. 输入主密码
      final passwordField = find.byType(TextField).first;
      await tester.enterText(passwordField, 'TestPassword123!');
      await tester.pumpAndSettle();

      // 5. 输入确认密码
      final confirmField = find.byType(TextField).at(1);
      await tester.enterText(confirmField, 'TestPassword123!');
      await tester.pumpAndSettle();

      // 6. 点击创建按钮
      final createButton = find.text('创建');
      await tester.tap(createButton);
      await tester.pumpAndSettle(Duration(seconds: 2));

      // 7. 应该进入主页
      expect(find.text('密码列表'), findsOneWidget);

      // 截图
      await binding.takeScreenshot('01_main_screen');
    });

    testWidgets('场景2: 添加密码条目', (WidgetTester tester) async {
      // 继续使用已登录的状态...

      // 1. 点击添加按钮
      final addButton = find.byIcon(Icons.add);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 2. 填写标题
      final titleField = find.byKey(Key('title_field'));
      await tester.enterText(titleField, 'Gmail');

      // 3. 填写用户名
      final usernameField = find.byKey(Key('username_field'));
      await tester.enterText(usernameField, 'test@gmail.com');

      // 4. 填写密码
      final passwordField = find.byKey(Key('password_field'));
      await tester.enterText(passwordField, 'SecurePassword123!');

      // 5. 保存
      final saveButton = find.text('保存');
      await tester.tap(saveButton);
      await tester.pumpAndSettle(Duration(seconds: 1));

      // 6. 验证保存成功
      expect(find.text('Gmail'), findsOneWidget);

      // 截图
      await binding.takeScreenshot('02_password_added');
    });
  });
}
```

**运行测试**:

```bash
# iOS 模拟器
flutter test integration_test/app_test.dart -d iPhone

# Android 模拟器
flutter test integration_test/app_test.dart -d emulator-5554

# 生成测试报告（JSON格式）
flutter test integration_test/app_test.dart \
  --machine > test_results.json

# 截图保存在:
# build/integration_test/screenshots/
```

---

### 4. 自动化测试控制脚本（必需）

#### ✅ Python 自动化脚本

**为什么需要**:
- 编排整个测试流程
- 启动/关闭模拟器
- 收集结果
- 分析错误
- 生成报告

**脚本示例**: `autonomous_test_runner.py`

```python
#!/usr/bin/env python3
"""
APWD 自闭环自动化测试运行器
完全自主运行，无需人工干预
"""

import subprocess
import time
import json
import os
from pathlib import Path
from datetime import datetime

class AutonomousTestRunner:
    def __init__(self):
        self.project_dir = Path(__file__).parent
        self.results_dir = self.project_dir / "test_results"
        self.results_dir.mkdir(exist_ok=True)
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    def run_command(self, cmd, shell=False):
        """运行命令并返回结果"""
        print(f"🔧 执行: {cmd}")
        result = subprocess.run(
            cmd if shell else cmd.split(),
            capture_output=True,
            text=True,
            cwd=self.project_dir
        )
        return result

    def setup_ios_simulator(self):
        """启动 iOS 模拟器"""
        print("\n📱 启动 iOS 模拟器...")

        # 1. 列出可用的模拟器
        result = self.run_command("xcrun simctl list devices available")

        # 2. 选择 iPhone 15 Pro（或第一个可用的 iPhone）
        devices = [line for line in result.stdout.split('\n')
                  if 'iPhone' in line and 'Shutdown' in line]

        if not devices:
            print("❌ 没有找到可用的 iOS 模拟器")
            return None

        # 提取设备 ID
        device_line = devices[0]
        device_id = device_line.split('(')[1].split(')')[0]
        device_name = device_line.split('(')[0].strip()

        print(f"   选择设备: {device_name} ({device_id})")

        # 3. 启动模拟器
        self.run_command(f"xcrun simctl boot {device_id}")
        print("   等待模拟器启动...")
        time.sleep(15)

        return device_id

    def setup_android_emulator(self):
        """启动 Android 模拟器"""
        print("\n🤖 启动 Android 模拟器...")

        # 1. 列出可用的 AVD
        result = self.run_command("emulator -list-avds")
        avds = [line.strip() for line in result.stdout.split('\n') if line.strip()]

        if not avds:
            print("❌ 没有找到可用的 Android 模拟器")
            return None

        avd_name = avds[0]
        print(f"   选择 AVD: {avd_name}")

        # 2. 启动模拟器（后台）
        subprocess.Popen(
            f"emulator -avd {avd_name} -no-window -no-audio -no-boot-anim",
            shell=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

        print("   等待模拟器启动...")
        self.run_command("adb wait-for-device")
        time.sleep(10)

        return "emulator-5554"

    def run_flutter_tests(self, device_id, platform):
        """运行 Flutter 集成测试"""
        print(f"\n🧪 在 {platform} 上运行测试...")

        # 1. 构建并安装应用
        print("   构建应用...")
        if platform == "ios":
            build_cmd = f"flutter build ios --debug --simulator"
        else:
            build_cmd = f"flutter build apk --debug"

        build_result = self.run_command(build_cmd)

        # 2. 运行集成测试
        print("   运行集成测试...")
        test_result = self.run_command(
            f"flutter test integration_test/app_test.dart -d {device_id}"
        )

        # 3. 保存测试结果
        result_file = self.results_dir / f"{platform}_{self.timestamp}_result.txt"
        result_file.write_text(test_result.stdout + "\n" + test_result.stderr)

        # 4. 收集截图
        screenshots_src = self.project_dir / "build" / "integration_test" / "screenshots"
        if screenshots_src.exists():
            screenshots_dst = self.results_dir / f"{platform}_{self.timestamp}_screenshots"
            screenshots_dst.mkdir(exist_ok=True)
            self.run_command(f"cp -r {screenshots_src}/* {screenshots_dst}/", shell=True)
            print(f"   📸 截图已保存到: {screenshots_dst}")

        return test_result.returncode == 0

    def collect_logs(self, device_id, platform):
        """收集设备日志"""
        print(f"\n📋 收集 {platform} 日志...")

        log_file = self.results_dir / f"{platform}_{self.timestamp}_logs.txt"

        if platform == "ios":
            result = self.run_command(
                f"xcrun simctl spawn {device_id} log show --predicate 'subsystem contains \"flutter\"' --last 5m"
            )
        else:
            result = self.run_command("adb logcat -d -s flutter:V")

        log_file.write_text(result.stdout)
        print(f"   日志已保存到: {log_file}")

    def analyze_results(self, platform, success):
        """分析测试结果"""
        print(f"\n📊 分析 {platform} 测试结果...")

        result_file = self.results_dir / f"{platform}_{self.timestamp}_result.txt"
        content = result_file.read_text()

        # 提取测试统计
        passed = content.count("✓")
        failed = content.count("✗")

        analysis = {
            "platform": platform,
            "timestamp": self.timestamp,
            "success": success,
            "tests_passed": passed,
            "tests_failed": failed,
            "errors": []
        }

        # 提取错误信息
        if not success:
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if 'ERROR' in line or 'FAIL' in line or 'Exception' in line:
                    analysis["errors"].append({
                        "line": i,
                        "message": line.strip()
                    })

        # 保存分析结果
        analysis_file = self.results_dir / f"{platform}_{self.timestamp}_analysis.json"
        analysis_file.write_text(json.dumps(analysis, indent=2))

        return analysis

    def cleanup_simulator(self, device_id, platform):
        """清理模拟器"""
        print(f"\n🧹 清理 {platform} 模拟器...")

        if platform == "ios":
            self.run_command(f"xcrun simctl shutdown {device_id}")
        else:
            self.run_command("adb emu kill")

    def generate_report(self, results):
        """生成测试报告"""
        print("\n📄 生成测试报告...")

        report = f"""
# APWD 自动化测试报告
**生成时间**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

## 测试结果汇总

"""
        for platform, analysis in results.items():
            status = "✅ 通过" if analysis["success"] else "❌ 失败"
            report += f"""
### {platform.upper()}
- **状态**: {status}
- **通过**: {analysis["tests_passed"]} 个测试
- **失败**: {analysis["tests_failed"]} 个测试
"""
            if analysis["errors"]:
                report += "\n**错误列表**:\n"
                for error in analysis["errors"][:5]:  # 只显示前5个
                    report += f"- {error['message']}\n"

        report += f"""

## 测试制品
- 测试结果: `test_results/`
- 截图: `test_results/*_screenshots/`
- 日志: `test_results/*_logs.txt`
- 分析: `test_results/*_analysis.json`

---
*此报告由自动化测试系统生成*
"""

        report_file = self.results_dir / f"test_report_{self.timestamp}.md"
        report_file.write_text(report)
        print(f"   报告已保存到: {report_file}")

        return report_file

    def run_full_test_cycle(self, platforms=["ios"]):
        """运行完整的测试周期"""
        print("\n" + "="*60)
        print("🚀 APWD 自闭环自动化测试")
        print("="*60)

        results = {}

        for platform in platforms:
            print(f"\n\n{'='*60}")
            print(f"测试平台: {platform.upper()}")
            print("="*60)

            try:
                # 1. 启动模拟器
                if platform == "ios":
                    device_id = self.setup_ios_simulator()
                else:
                    device_id = self.setup_android_emulator()

                if not device_id:
                    continue

                # 2. 运行测试
                success = self.run_flutter_tests(device_id, platform)

                # 3. 收集日志
                self.collect_logs(device_id, platform)

                # 4. 分析结果
                analysis = self.analyze_results(platform, success)
                results[platform] = analysis

                # 5. 清理
                self.cleanup_simulator(device_id, platform)

            except Exception as e:
                print(f"❌ {platform} 测试失败: {str(e)}")
                results[platform] = {
                    "success": False,
                    "error": str(e)
                }

        # 6. 生成报告
        report_file = self.generate_report(results)

        print("\n" + "="*60)
        print("✅ 自动化测试完成！")
        print(f"📄 查看报告: {report_file}")
        print("="*60)

        return results

if __name__ == "__main__":
    runner = AutonomousTestRunner()

    # 运行 iOS 和 Android 测试
    results = runner.run_full_test_cycle(platforms=["ios", "android"])

    # 检查是否所有测试都通过
    all_passed = all(r.get("success", False) for r in results.values())
    exit(0 if all_passed else 1)
```

**使用方法**:
```bash
chmod +x autonomous_test_runner.py
./autonomous_test_runner.py
```

---

## 🔄 完整的自闭环工作流程

### Claude/AI Agent 可以完全自主执行：

```bash
# 1. 启动测试运行器
python3 autonomous_test_runner.py

# 脚本将自动：
# ✅ 启动 iOS 模拟器
# ✅ 构建应用
# ✅ 安装到模拟器
# ✅ 运行集成测试
# ✅ 收集截图（每个测试步骤）
# ✅ 收集设备日志
# ✅ 分析测试结果
# ✅ 识别失败的测试
# ✅ 提取错误信息
# ✅ 生成详细报告
# ✅ 关闭模拟器

# 2. 如果发现错误，AI Agent 可以：
# - 读取 test_results/*_analysis.json
# - 查看截图定位问题
# - 读取日志了解错误详情
# - 修改代码修复问题
# - 重新运行测试验证修复

# 3. 迭代直到所有测试通过
```

---

## 📋 安装优先级建议

### 最小配置（iOS Only）
```bash
# 1. 安装 Xcode（必需）
# 2. 配置 iOS 模拟器
# 3. 创建集成测试
# 4. 运行自动化脚本
```

### 完整配置（iOS + Android）
```bash
# 1. 安装 Xcode
# 2. 安装 Android Studio
# 3. 创建 Android AVD
# 4. 配置环境变量
# 5. 创建集成测试
# 6. 运行自动化脚本
```

---

## 🎯 验证安装

运行以下命令验证所有工具都已正确安装：

```bash
# 创建验证脚本
cat > verify_setup.sh << 'EOF'
#!/bin/bash

echo "🔍 验证自动化测试环境..."

# 1. Flutter
echo -n "Flutter: "
if command -v flutter &> /dev/null; then
    echo "✅ $(flutter --version | head -1)"
else
    echo "❌ 未安装"
fi

# 2. Xcode
echo -n "Xcode: "
if command -v xcodebuild &> /dev/null; then
    echo "✅ $(xcodebuild -version | head -1)"
else
    echo "❌ 未安装"
fi

# 3. iOS 模拟器
echo -n "iOS 模拟器: "
SIM_COUNT=$(xcrun simctl list devices | grep "iPhone" | grep -c "Shutdown")
if [ $SIM_COUNT -gt 0 ]; then
    echo "✅ $SIM_COUNT 个可用"
else
    echo "❌ 没有可用的模拟器"
fi

# 4. Android SDK
echo -n "Android SDK: "
if [ -d "$ANDROID_HOME" ]; then
    echo "✅ $ANDROID_HOME"
else
    echo "❌ 未配置"
fi

# 5. Android 模拟器
echo -n "Android 模拟器: "
if command -v emulator &> /dev/null; then
    AVD_COUNT=$(emulator -list-avds | wc -l)
    echo "✅ $AVD_COUNT 个可用"
else
    echo "❌ 未安装"
fi

echo ""
echo "📊 建议："
if ! command -v xcodebuild &> /dev/null; then
    echo "⚠️  安装 Xcode 以支持 iOS 自动化测试"
fi
if ! command -v emulator &> /dev/null; then
    echo "⚠️  安装 Android Studio 以支持 Android 自动化测试"
fi
EOF

chmod +x verify_setup.sh
./verify_setup.sh
```

---

## 📖 使用示例

### 场景1: 首次设置

```bash
# 1. 安装 Xcode
# 2. 运行验证脚本
./verify_setup.sh

# 3. 创建集成测试
# （使用上面提供的示例代码）

# 4. 首次运行测试
python3 autonomous_test_runner.py
```

### 场景2: 发现并修复 Bug

```bash
# 1. 运行测试（自动发现问题）
python3 autonomous_test_runner.py

# 2. 查看分析结果
cat test_results/ios_*_analysis.json

# 3. 查看截图
open test_results/ios_*_screenshots/

# 4. AI Agent 分析并修复代码
# （读取错误信息，修改代码，提交）

# 5. 验证修复
python3 autonomous_test_runner.py

# 6. 重复直到所有测试通过
```

---

## 🎉 总结

安装完成后，Claude/AI Agent 将能够：

✅ **完全自主运行测试** - 无需人工启动模拟器
✅ **自动收集问题** - 截图、日志、错误信息
✅ **自动分析问题** - JSON 格式的结构化数据
✅ **自动修复代码** - 基于错误信息修改代码
✅ **自动验证修复** - 重新运行测试确认
✅ **生成详细报告** - Markdown 格式，易于阅读

**完全自闭环，零人工干预！**

---

**下一步**: 选择安装 Xcode（iOS）或 Android Studio（Android），然后运行 `verify_setup.sh` 验证环境。
