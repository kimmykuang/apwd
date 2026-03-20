#!/usr/bin/env python3
"""
APWD 自闭环自动化测试运行器
完全自主运行，无需人工干预
"""

import subprocess
import time
import json
import os
import shutil
from pathlib import Path
from datetime import datetime

class AutonomousTestRunner:
    def __init__(self):
        self.project_dir = Path(__file__).parent
        self.results_dir = self.project_dir / "test_results"
        self.results_dir.mkdir(exist_ok=True)
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    def run_command(self, cmd, shell=False, cwd=None):
        """运行命令并返回结果"""
        print(f"🔧 执行: {cmd if isinstance(cmd, str) else ' '.join(cmd)}")
        result = subprocess.run(
            cmd if shell else (cmd.split() if isinstance(cmd, str) else cmd),
            capture_output=True,
            text=True,
            cwd=cwd or self.project_dir
        )
        return result

    def setup_ios_simulator(self):
        """启动 iOS 模拟器"""
        print("\n📱 设置 iOS 模拟器...")

        # 1. 列出可用的模拟器
        result = self.run_command("xcrun simctl list devices available")

        # 2. 查找可用的 iPhone 模拟器
        devices = []
        for line in result.stdout.split('\n'):
            if 'iPhone' in line and '(' in line and ')' in line:
                # 提取设备名称和 UUID
                parts = line.split('(')
                if len(parts) >= 2:
                    device_name = parts[0].strip()
                    uuid_part = parts[1].split(')')[0]
                    devices.append((device_name, uuid_part))

        if not devices:
            print("❌ 没有找到可用的 iOS 模拟器")
            print("   请在 Xcode 中安装 iOS 模拟器")
            return None

        # 选择第一个设备
        device_name, device_id = devices[0]
        print(f"   选择设备: {device_name}")
        print(f"   设备 ID: {device_id}")

        # 3. 关闭所有运行中的模拟器
        print("   关闭现有模拟器...")
        self.run_command("xcrun simctl shutdown all")
        time.sleep(2)

        # 4. 启动选中的模拟器
        print("   启动模拟器...")
        self.run_command(f"xcrun simctl boot {device_id}")
        print("   等待模拟器启动...")
        time.sleep(20)

        # 5. 验证模拟器已启动
        result = self.run_command(f"xcrun simctl list devices | grep {device_id}")
        if "Booted" in result.stdout:
            print("   ✅ 模拟器已成功启动")
            return device_id
        else:
            print("   ⚠️  模拟器可能未完全启动，继续尝试...")
            return device_id

    def setup_android_emulator(self):
        """启动 Android 模拟器"""
        print("\n🤖 设置 Android 模拟器...")

        # 1. 列出可用的 AVD
        result = self.run_command(["emulator", "-list-avds"])
        avds = [line.strip() for line in result.stdout.split('\n') if line.strip()]

        if not avds:
            print("❌ 没有找到可用的 Android 模拟器")
            print("   请创建 AVD: avdmanager create avd ...")
            return None

        avd_name = avds[0]
        print(f"   选择 AVD: {avd_name}")

        # 2. 关闭现有模拟器
        print("   关闭现有模拟器...")
        subprocess.run(["adb", "emu", "kill"], capture_output=True)
        time.sleep(2)

        # 3. 启动模拟器（后台，无窗口）
        print("   启动模拟器...")
        subprocess.Popen(
            ["emulator", "-avd", avd_name, "-no-window", "-no-audio", "-no-boot-anim"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

        print("   等待设备连接...")
        self.run_command(["adb", "wait-for-device"])
        print("   等待系统启动...")
        time.sleep(20)

        # 4. 获取设备 ID
        result = self.run_command(["adb", "devices"])
        lines = result.stdout.split('\n')
        for line in lines[1:]:
            if 'emulator' in line and 'device' in line:
                device_id = line.split()[0]
                print(f"   ✅ 模拟器已启动: {device_id}")
                return device_id

        return "emulator-5554"  # 默认值

    def run_flutter_tests(self, device_id, platform):
        """运行 Flutter 集成测试"""
        print(f"\n🧪 在 {platform} 上运行测试...")

        # 1. 运行集成测试
        print("   运行集成测试（这可能需要几分钟）...")
        test_cmd = [
            "flutter", "test",
            "integration_test/app_test.dart",
            "-d", device_id
        ]

        test_result = self.run_command(test_cmd)

        # 2. 保存测试输出
        result_file = self.results_dir / f"{platform}_{self.timestamp}_result.txt"
        result_file.write_text(
            f"=== STDOUT ===\n{test_result.stdout}\n\n"
            f"=== STDERR ===\n{test_result.stderr}\n\n"
            f"=== EXIT CODE ===\n{test_result.returncode}"
        )
        print(f"   测试结果已保存: {result_file}")

        # 3. 收集截图
        self.collect_screenshots(platform)

        # 4. 判断测试是否通过
        success = test_result.returncode == 0 and "All tests passed" in test_result.stdout

        if success:
            print("   ✅ 所有测试通过！")
        else:
            print("   ❌ 测试失败，请查看日志")

        return success

    def collect_screenshots(self, platform):
        """收集测试截图"""
        print("   📸 收集截图...")

        # Flutter 集成测试截图位置
        screenshots_src = self.project_dir / "build" / platform / "screenshots"

        # 也检查其他可能的位置
        alt_locations = [
            self.project_dir / "build" / "integration_test" / "screenshots",
            self.project_dir / "screenshots",
        ]

        screenshots_dst = self.results_dir / f"{platform}_{self.timestamp}_screenshots"
        screenshots_dst.mkdir(exist_ok=True)

        found_screenshots = False

        # 尝试所有可能的位置
        for src in [screenshots_src] + alt_locations:
            if src.exists() and any(src.iterdir()):
                for screenshot in src.glob("*"):
                    if screenshot.is_file():
                        shutil.copy2(screenshot, screenshots_dst / screenshot.name)
                        found_screenshots = True
                print(f"   从 {src} 复制截图")

        if found_screenshots:
            count = len(list(screenshots_dst.glob("*")))
            print(f"   ✅ 已收集 {count} 张截图到: {screenshots_dst}")
        else:
            print(f"   ⚠️  未找到截图文件")

    def collect_logs(self, device_id, platform):
        """收集设备日志"""
        print(f"\n📋 收集 {platform} 日志...")

        log_file = self.results_dir / f"{platform}_{self.timestamp}_logs.txt"

        try:
            if platform == "ios":
                # iOS 日志
                result = self.run_command([
                    "xcrun", "simctl", "spawn", device_id,
                    "log", "show",
                    "--predicate", 'subsystem contains "flutter"',
                    "--last", "10m"
                ])
            else:
                # Android 日志
                result = self.run_command(["adb", "logcat", "-d", "-s", "flutter:V", "Flutter:V"])

            log_file.write_text(result.stdout)
            print(f"   ✅ 日志已保存: {log_file}")
        except Exception as e:
            print(f"   ⚠️  收集日志失败: {str(e)}")

    def analyze_results(self, platform, success):
        """分析测试结果并生成JSON报告"""
        print(f"\n📊 分析 {platform} 测试结果...")

        result_file = self.results_dir / f"{platform}_{self.timestamp}_result.txt"
        content = result_file.read_text() if result_file.exists() else ""

        # 提取测试统计
        passed = content.count("✓") + content.count("✅")
        failed = content.count("✗") + content.count("❌")

        analysis = {
            "platform": platform,
            "timestamp": self.timestamp,
            "success": success,
            "tests_passed": passed,
            "tests_failed": failed,
            "errors": [],
            "warnings": []
        }

        # 提取错误和警告
        lines = content.split('\n')
        for i, line in enumerate(lines):
            line_lower = line.lower()
            if any(keyword in line_lower for keyword in ['error', 'exception', 'failed', 'fail']):
                if line.strip():
                    analysis["errors"].append({
                        "line": i + 1,
                        "message": line.strip()[:200]  # 限制长度
                    })
            elif 'warning' in line_lower:
                if line.strip():
                    analysis["warnings"].append({
                        "line": i + 1,
                        "message": line.strip()[:200]
                    })

        # 限制错误和警告数量
        analysis["errors"] = analysis["errors"][:10]
        analysis["warnings"] = analysis["warnings"][:10]

        # 保存分析结果
        analysis_file = self.results_dir / f"{platform}_{self.timestamp}_analysis.json"
        analysis_file.write_text(json.dumps(analysis, indent=2, ensure_ascii=False))
        print(f"   ✅ 分析结果已保存: {analysis_file}")

        return analysis

    def cleanup_simulator(self, device_id, platform):
        """清理模拟器"""
        print(f"\n🧹 清理 {platform} 模拟器...")

        try:
            if platform == "ios":
                self.run_command(f"xcrun simctl shutdown {device_id}")
                print("   ✅ iOS 模拟器已关闭")
            else:
                self.run_command(["adb", "emu", "kill"])
                print("   ✅ Android 模拟器已关闭")
        except Exception as e:
            print(f"   ⚠️  清理失败: {str(e)}")

    def generate_report(self, results):
        """生成Markdown测试报告"""
        print("\n📄 生成测试报告...")

        report = f"""# APWD 自动化测试报告

**生成时间**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

## 📊 测试结果汇总

"""

        total_passed = 0
        total_failed = 0

        for platform, analysis in results.items():
            if "error" in analysis:
                report += f"""
### ❌ {platform.upper()} - 运行失败

**错误**: {analysis['error']}

"""
                continue

            status = "✅ 通过" if analysis["success"] else "❌ 失败"
            total_passed += analysis["tests_passed"]
            total_failed += analysis["tests_failed"]

            report += f"""
### {status} {platform.upper()}

- **通过**: {analysis["tests_passed"]} 个测试
- **失败**: {analysis["tests_failed"]} 个测试
"""

            if analysis["errors"]:
                report += "\n**错误列表**:\n"
                for error in analysis["errors"][:5]:
                    report += f"- Line {error['line']}: {error['message']}\n"

            if analysis["warnings"]:
                report += "\n**警告列表**:\n"
                for warning in analysis["warnings"][:3]:
                    report += f"- Line {warning['line']}: {warning['message']}\n"

        report += f"""

## 📈 总体统计

- **总测试数**: {total_passed + total_failed}
- **通过**: {total_passed}
- **失败**: {total_failed}
- **成功率**: {(total_passed / max(total_passed + total_failed, 1) * 100):.1f}%

## 📁 测试制品

```
test_results/
├── {self.timestamp}_report.md          # 本报告
├── *_result.txt                        # 测试输出
├── *_logs.txt                          # 设备日志
├── *_analysis.json                     # 结构化分析
└── *_screenshots/                      # 测试截图
```

## 🔍 如何使用这些结果

1. **查看失败原因**: 阅读 `*_result.txt` 中的错误信息
2. **查看截图**: 打开 `*_screenshots/` 查看每个测试步骤的截图
3. **查看详细日志**: 阅读 `*_logs.txt` 了解完整的应用日志
4. **程序化分析**: 读取 `*_analysis.json` 进行自动化问题分析

---

*此报告由 APWD 自动化测试系统生成*
*Claude/AI Agent 可以读取这些结果并自动修复问题*
"""

        report_file = self.results_dir / f"{self.timestamp}_report.md"
        report_file.write_text(report)
        print(f"   ✅ 报告已保存: {report_file}")

        return report_file

    def run_full_test_cycle(self, platforms=None):
        """运行完整的测试周期"""
        if platforms is None:
            # 自动检测可用平台
            platforms = []
            if shutil.which("xcodebuild"):
                platforms.append("ios")
            if shutil.which("emulator"):
                platforms.append("android")

            if not platforms:
                print("❌ 没有找到可用的测试平台")
                print("   请安装 Xcode (iOS) 或 Android Studio (Android)")
                return {}

        print("\n" + "="*60)
        print("🚀 APWD 自闭环自动化测试")
        print("="*60)
        print(f"测试平台: {', '.join(platforms)}")

        results = {}

        for platform in platforms:
            print(f"\n\n{'='*60}")
            print(f"测试平台: {platform.upper()}")
            print("="*60)

            device_id = None

            try:
                # 1. 启动模拟器
                if platform == "ios":
                    device_id = self.setup_ios_simulator()
                else:
                    device_id = self.setup_android_emulator()

                if not device_id:
                    results[platform] = {"error": "无法启动模拟器"}
                    continue

                # 2. 运行测试
                success = self.run_flutter_tests(device_id, platform)

                # 3. 收集日志
                self.collect_logs(device_id, platform)

                # 4. 分析结果
                analysis = self.analyze_results(platform, success)
                results[platform] = analysis

            except Exception as e:
                print(f"❌ {platform} 测试失败: {str(e)}")
                import traceback
                traceback.print_exc()
                results[platform] = {
                    "success": False,
                    "error": str(e)
                }

            finally:
                # 5. 清理（无论成功失败都要清理）
                if device_id:
                    self.cleanup_simulator(device_id, platform)

        # 6. 生成报告
        report_file = self.generate_report(results)

        print("\n" + "="*60)
        print("✅ 自动化测试完成！")
        print(f"📄 查看报告: {report_file}")
        print("="*60)

        # 打印快速摘要
        all_passed = all(r.get("success", False) for r in results.values() if "error" not in r)
        if all_passed:
            print("\n🎉 所有测试通过！应用运行正常。")
        else:
            print("\n⚠️  发现问题，请查看报告了解详情。")

        return results

def main():
    """主函数"""
    import sys

    runner = AutonomousTestRunner()

    # 解析命令行参数
    platforms = None
    if len(sys.argv) > 1:
        platforms = [p.lower() for p in sys.argv[1:] if p.lower() in ['ios', 'android']]

    # 运行测试
    results = runner.run_full_test_cycle(platforms=platforms)

    # 返回退出代码
    if not results:
        sys.exit(2)  # 没有可用平台

    all_passed = all(r.get("success", False) for r in results.values() if "error" not in r)
    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()
