#!/bin/bash

echo "🔍 验证 APWD 自动化测试环境配置"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 计数器
REQUIRED_PASSED=0
REQUIRED_TOTAL=0
OPTIONAL_PASSED=0
OPTIONAL_TOTAL=0

# 检查函数
check_required() {
    REQUIRED_TOTAL=$((REQUIRED_TOTAL + 1))
    if eval "$2" &> /dev/null; then
        echo -e "${GREEN}✅ $1${NC}"
        REQUIRED_PASSED=$((REQUIRED_PASSED + 1))
        if [ ! -z "$3" ]; then
            echo "   $3"
        fi
        return 0
    else
        echo -e "${RED}❌ $1${NC}"
        if [ ! -z "$4" ]; then
            echo -e "   ${YELLOW}→ $4${NC}"
        fi
        return 1
    fi
}

check_optional() {
    OPTIONAL_TOTAL=$((OPTIONAL_TOTAL + 1))
    if eval "$2" &> /dev/null; then
        echo -e "${GREEN}✅ $1${NC}"
        OPTIONAL_PASSED=$((OPTIONAL_PASSED + 1))
        if [ ! -z "$3" ]; then
            echo "   $3"
        fi
        return 0
    else
        echo -e "${YELLOW}⚠️  $1${NC}"
        if [ ! -z "$4" ]; then
            echo "   → $4"
        fi
        return 1
    fi
}

echo "📦 必需工具检查"
echo "------------------------------------------"

# Flutter
check_required \
    "Flutter SDK" \
    "command -v flutter" \
    "$(flutter --version 2>/dev/null | head -1)" \
    "安装: https://docs.flutter.dev/get-started/install"

# Python3
check_required \
    "Python 3" \
    "command -v python3" \
    "$(python3 --version 2>/dev/null)" \
    "安装: brew install python3"

# Git
check_required \
    "Git" \
    "command -v git" \
    "$(git --version 2>/dev/null)" \
    "安装: brew install git"

echo ""
echo "📱 iOS 测试环境（推荐）"
echo "------------------------------------------"

# Xcode
if check_optional \
    "Xcode" \
    "command -v xcodebuild" \
    "$(xcodebuild -version 2>/dev/null | head -1)" \
    "通过 App Store 安装 Xcode"; then

    # iOS 模拟器
    SIM_COUNT=$(xcrun simctl list devices 2>/dev/null | grep "iPhone" | grep -c "Shutdown\|Booted" || echo "0")
    check_optional \
        "iOS 模拟器" \
        "[ $SIM_COUNT -gt 0 ]" \
        "$SIM_COUNT 个可用设备" \
        "在 Xcode -> Settings -> Platforms 中下载 iOS"

    # xcrun
    check_optional \
        "xcrun 命令" \
        "command -v xcrun" \
        "iOS 模拟器控制工具" \
        "Xcode 命令行工具"
fi

echo ""
echo "🤖 Android 测试环境（可选）"
echo "------------------------------------------"

# Android SDK
if [ -d "$ANDROID_HOME" ] || [ -d ~/Library/Android/sdk ]; then
    ANDROID_HOME=${ANDROID_HOME:-~/Library/Android/sdk}
    check_optional \
        "Android SDK" \
        "[ -d $ANDROID_HOME ]" \
        "$ANDROID_HOME" \
        "安装 Android Studio"
else
    check_optional \
        "Android SDK" \
        "false" \
        "" \
        "安装 Android Studio 或设置 ANDROID_HOME"
fi

# adb
check_optional \
    "ADB (Android Debug Bridge)" \
    "command -v adb" \
    "$(adb version 2>/dev/null | head -1)" \
    "添加到 PATH: export PATH=\$PATH:\$ANDROID_HOME/platform-tools"

# emulator
check_optional \
    "Android Emulator" \
    "command -v emulator" \
    "" \
    "添加到 PATH: export PATH=\$PATH:\$ANDROID_HOME/emulator"

# AVD
if command -v emulator &> /dev/null; then
    AVD_COUNT=$(emulator -list-avds 2>/dev/null | wc -l | tr -d ' ')
    check_optional \
        "Android Virtual Devices (AVD)" \
        "[ $AVD_COUNT -gt 0 ]" \
        "$AVD_COUNT 个可用设备" \
        "创建 AVD: avdmanager create avd ..."
fi

echo ""
echo "🧪 测试工具检查"
echo "------------------------------------------"

# Integration test 文件
check_required \
    "集成测试文件" \
    "[ -f integration_test/app_test.dart ]" \
    "integration_test/app_test.dart" \
    "文件已创建，无需操作"

# 自动化脚本
check_required \
    "自动化测试脚本" \
    "[ -f autonomous_test_runner.py ]" \
    "autonomous_test_runner.py" \
    "文件已创建，无需操作"

# 脚本可执行权限
chmod +x autonomous_test_runner.py 2>/dev/null
check_optional \
    "脚本可执行权限" \
    "[ -x autonomous_test_runner.py ]" \
    "" \
    "运行: chmod +x autonomous_test_runner.py"

echo ""
echo "=========================================="
echo "📊 检查结果汇总"
echo "=========================================="
echo ""
echo -e "必需工具: ${GREEN}$REQUIRED_PASSED${NC} / $REQUIRED_TOTAL 通过"
echo -e "可选工具: ${GREEN}$OPTIONAL_PASSED${NC} / $OPTIONAL_TOTAL 可用"
echo ""

# 建议
if [ $REQUIRED_PASSED -eq $REQUIRED_TOTAL ]; then
    echo -e "${GREEN}✅ 必需工具已全部安装${NC}"
else
    echo -e "${RED}❌ 请先安装所有必需工具${NC}"
fi

echo ""

if [ $OPTIONAL_PASSED -eq 0 ]; then
    echo -e "${YELLOW}⚠️  未找到任何测试平台（iOS/Android）${NC}"
    echo ""
    echo "建议操作："
    echo "1. 安装 Xcode (iOS 测试)"
    echo "   - 打开 App Store"
    echo "   - 搜索并下载 Xcode"
    echo "   - 大小约 15GB，需要 1-2 小时"
    echo ""
    echo "2. 或者安装 Android Studio (Android 测试)"
    echo "   - 运行: brew install --cask android-studio"
    echo "   - 启动后选择 Standard 安装"
    echo ""
elif command -v xcodebuild &> /dev/null; then
    echo -e "${GREEN}✅ iOS 测试环境已就绪${NC}"
    echo ""
    echo "可以运行测试了："
    echo "  ./autonomous_test_runner.py ios"
    echo ""
    if command -v emulator &> /dev/null; then
        echo -e "${GREEN}✅ Android 测试环境也已就绪${NC}"
        echo ""
        echo "可以测试所有平台："
        echo "  ./autonomous_test_runner.py ios android"
        echo ""
    fi
elif command -v emulator &> /dev/null; then
    echo -e "${GREEN}✅ Android 测试环境已就绪${NC}"
    echo ""
    echo "可以运行测试了："
    echo "  ./autonomous_test_runner.py android"
    echo ""
fi

echo "=========================================="
echo "📚 更多信息"
echo "=========================================="
echo ""
echo "查看详细配置指南:"
echo "  cat AUTONOMOUS_TESTING_SETUP.md"
echo ""
echo "手动运行 Flutter 测试:"
echo "  flutter test integration_test/app_test.dart"
echo ""
echo "=========================================="
