#!/bin/bash

# APWD 模拟器快速启动脚本

echo "🚀 启动 iOS 模拟器..."

# 查找最新的 iPhone 模拟器
DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone" | tail -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$DEVICE_ID" ]; then
    echo "❌ 未找到可用的 iPhone 模拟器"
    exit 1
fi

echo "📱 设备 ID: $DEVICE_ID"

# 启动模拟器
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || echo "✓ 模拟器已在运行"

# 打开 Simulator.app
open -a Simulator

echo "✅ 模拟器已启动"
echo ""
echo "接下来："
echo "1. 在 VSCode 中打开项目"
echo "2. 在模拟器中运行 APWD: flutter run -d $DEVICE_ID"
echo "3. 在 Claude Code 中说: '请帮我测试APWD功能'"
