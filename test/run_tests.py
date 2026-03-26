#!/usr/bin/env python3
"""
APWD 统一测试入口
运行所有类型的测试：单元测试、集成测试、E2E 测试

使用方法:
    python test/run_tests.py --all              # 运行所有测试
    python test/run_tests.py --unit             # 只运行单元测试
    python test/run_tests.py --integration      # 只运行集成测试
    python test/run_tests.py --e2e-mobile       # 只运行移动端 E2E
    python test/run_tests.py --e2e-web          # 只运行 Web E2E
    python test/run_tests.py --e2e-autonomous   # 只运行自主测试运行器

    # 运行特定移动端场景
    python test/run_tests.py --e2e-mobile --scenario webdav_test
"""

import subprocess
import sys
import argparse
import os
from pathlib import Path
from datetime import datetime

# 颜色输出
class Colors:
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color
    BOLD = '\033[1m'

class TestRunner:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.test_dir = self.project_root / "test"
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.results = {
            'unit': None,
            'integration': None,
            'e2e_mobile': None,
            'e2e_web': None,
            'e2e_autonomous': None,
        }

    def print_header(self, message):
        """打印标题"""
        print(f"\n{Colors.BOLD}{Colors.CYAN}{'=' * 60}{Colors.NC}")
        print(f"{Colors.BOLD}{Colors.CYAN}{message}{Colors.NC}")
        print(f"{Colors.BOLD}{Colors.CYAN}{'=' * 60}{Colors.NC}\n")

    def print_success(self, message):
        """打印成功消息"""
        print(f"{Colors.GREEN}✅ {message}{Colors.NC}")

    def print_error(self, message):
        """打印错误消息"""
        print(f"{Colors.RED}❌ {message}{Colors.NC}")

    def print_warning(self, message):
        """打印警告消息"""
        print(f"{Colors.YELLOW}⚠️  {message}{Colors.NC}")

    def print_info(self, message):
        """打印信息消息"""
        print(f"{Colors.BLUE}ℹ️  {message}{Colors.NC}")

    def run_command(self, cmd, cwd=None, shell=False):
        """运行命令并返回结果"""
        try:
            result = subprocess.run(
                cmd if shell else (cmd.split() if isinstance(cmd, str) else cmd),
                cwd=cwd or self.project_root,
                capture_output=True,
                text=True,
                shell=shell
            )
            return result
        except Exception as e:
            self.print_error(f"命令执行失败: {e}")
            return None

    def check_prerequisites(self):
        """检查前置条件"""
        self.print_header("检查测试环境")

        checks = {
            'Flutter': ['flutter', '--version'],
            'Python3': ['python3', '--version'],
            'Xcode': ['xcodebuild', '-version'],
        }

        all_ok = True
        for name, cmd in checks.items():
            result = self.run_command(cmd)
            if result and result.returncode == 0:
                self.print_success(f"{name} 已安装")
            else:
                self.print_warning(f"{name} 未安装或不可用（某些测试可能需要）")
                if name == 'Flutter':
                    all_ok = False

        return all_ok

    def run_unit_tests(self):
        """运行单元测试"""
        self.print_header("运行单元测试 (Flutter Test)")

        cmd = ['flutter', 'test', 'test/unit']
        result = self.run_command(cmd)

        if result and result.returncode == 0:
            self.print_success("单元测试通过")
            self.results['unit'] = True
        else:
            self.print_error("单元测试失败")
            if result:
                print(result.stdout)
                print(result.stderr)
            self.results['unit'] = False

        return self.results['unit']

    def run_integration_tests(self):
        """运行集成测试"""
        self.print_header("运行集成测试 (Flutter Integration Test)")

        cmd = ['flutter', 'test', 'test/integration']
        result = self.run_command(cmd)

        if result and result.returncode == 0:
            self.print_success("集成测试通过")
            self.results['integration'] = True
        else:
            self.print_error("集成测试失败")
            if result:
                print(result.stdout)
                print(result.stderr)
            self.results['integration'] = False

        return self.results['integration']

    def run_e2e_mobile(self, scenario=None):
        """运行移动端 E2E 测试"""
        self.print_header("运行移动端 E2E 测试 (Claude AI + mobile-mcp)")

        mobile_dir = self.test_dir / "e2e" / "mobile"
        run_script = mobile_dir / "run_tests.sh"

        if not run_script.exists():
            self.print_error(f"测试脚本不存在: {run_script}")
            self.results['e2e_mobile'] = False
            return False

        self.print_info(f"测试目录: {mobile_dir}")
        self.print_info("这将启动 iOS 模拟器并使用 Claude AI 执行测试")

        if scenario:
            self.print_info(f"运行场景: {scenario}")
            # 直接使用 claude CLI 运行特定场景
            cmd = f'claude -p "执行测试场景 {mobile_dir}/scenarios/{scenario}.yaml"'
            result = self.run_command(cmd, cwd=mobile_dir, shell=True)
        else:
            # 运行交互式脚本
            self.print_warning("请在打开的交互式菜单中选择测试场景")
            result = subprocess.run(
                ['bash', str(run_script)],
                cwd=mobile_dir
            )
            result = type('obj', (object,), {'returncode': result.returncode})()

        if result and result.returncode == 0:
            self.print_success("移动端 E2E 测试完成")
            self.results['e2e_mobile'] = True
        else:
            self.print_error("移动端 E2E 测试失败或被取消")
            self.results['e2e_mobile'] = False

        return self.results['e2e_mobile']

    def run_e2e_web(self):
        """运行 Web E2E 测试"""
        self.print_header("运行 Web E2E 测试 (Selenium)")

        web_dir = self.test_dir / "e2e" / "web"
        test_script = web_dir / "e2e_test.py"

        if not test_script.exists():
            self.print_error(f"测试脚本不存在: {test_script}")
            self.results['e2e_web'] = False
            return False

        self.print_info(f"测试脚本: {test_script}")
        self.print_warning("确保 Flutter Web 应用正在运行 (flutter run -d chrome)")

        cmd = ['python3', str(test_script)]
        result = self.run_command(cmd, cwd=web_dir)

        if result and result.returncode == 0:
            self.print_success("Web E2E 测试通过")
            self.results['e2e_web'] = True
        else:
            self.print_error("Web E2E 测试失败")
            if result:
                print(result.stdout)
                print(result.stderr)
            self.results['e2e_web'] = False

        return self.results['e2e_web']

    def run_e2e_autonomous(self):
        """运行自主测试运行器"""
        self.print_header("运行自主测试运行器 (Autonomous iOS Test)")

        autonomous_dir = self.test_dir / "e2e" / "autonomous"
        test_script = autonomous_dir / "autonomous_test_runner.py"

        if not test_script.exists():
            self.print_error(f"测试脚本不存在: {test_script}")
            self.results['e2e_autonomous'] = False
            return False

        self.print_info(f"测试脚本: {test_script}")
        self.print_info("这将自动设置 iOS 模拟器并运行完整测试套件")

        cmd = ['python3', str(test_script)]
        result = self.run_command(cmd, cwd=autonomous_dir)

        if result and result.returncode == 0:
            self.print_success("自主测试运行器完成")
            self.results['e2e_autonomous'] = True
        else:
            self.print_error("自主测试运行器失败")
            if result:
                print(result.stdout)
                print(result.stderr)
            self.results['e2e_autonomous'] = False

        return self.results['e2e_autonomous']

    def print_summary(self):
        """打印测试总结"""
        self.print_header("测试结果总结")

        test_names = {
            'unit': '单元测试',
            'integration': '集成测试',
            'e2e_mobile': '移动端 E2E',
            'e2e_web': 'Web E2E',
            'e2e_autonomous': '自主测试',
        }

        total = 0
        passed = 0

        for key, name in test_names.items():
            result = self.results[key]
            if result is not None:
                total += 1
                if result:
                    passed += 1
                    self.print_success(f"{name}: 通过")
                else:
                    self.print_error(f"{name}: 失败")

        print(f"\n{Colors.BOLD}总计: {passed}/{total} 测试类型通过{Colors.NC}\n")

        return passed == total if total > 0 else False

    def run_all(self, args):
        """运行指定的测试"""
        if not self.check_prerequisites():
            self.print_error("环境检查失败，无法运行测试")
            return False

        if args.all or args.unit:
            self.run_unit_tests()

        if args.all or args.integration:
            self.run_integration_tests()

        if args.all or args.e2e_mobile:
            self.run_e2e_mobile(args.scenario)

        if args.all or args.e2e_web:
            self.run_e2e_web()

        if args.all or args.e2e_autonomous:
            self.run_e2e_autonomous()

        return self.print_summary()

def main():
    parser = argparse.ArgumentParser(
        description='APWD 统一测试运行器',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python test/run_tests.py --all                          # 运行所有测试
  python test/run_tests.py --unit --integration           # 只运行 Flutter 测试
  python test/run_tests.py --e2e-mobile                   # 只运行移动端 E2E
  python test/run_tests.py --e2e-mobile --scenario search_test  # 运行特定场景
        """
    )

    parser.add_argument('--all', action='store_true', help='运行所有测试')
    parser.add_argument('--unit', action='store_true', help='运行单元测试')
    parser.add_argument('--integration', action='store_true', help='运行集成测试')
    parser.add_argument('--e2e-mobile', action='store_true', help='运行移动端 E2E 测试')
    parser.add_argument('--e2e-web', action='store_true', help='运行 Web E2E 测试')
    parser.add_argument('--e2e-autonomous', action='store_true', help='运行自主测试运行器')
    parser.add_argument('--scenario', type=str, help='指定移动端 E2E 测试场景')

    args = parser.parse_args()

    # 如果没有指定任何选项，显示帮助
    if not any([args.all, args.unit, args.integration, args.e2e_mobile,
                args.e2e_web, args.e2e_autonomous]):
        parser.print_help()
        sys.exit(1)

    runner = TestRunner()
    success = runner.run_all(args)

    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
