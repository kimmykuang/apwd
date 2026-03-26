#!/bin/bash
# tests/e2e/utils/start_simulator.sh
# 启动模拟器并等待 WebDriverAgent 就绪

set -e  # 遇到错误立即退出

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_DEVICE_NAME="iPhone 16"
DEFAULT_WAIT_TIME=15
MAX_RETRIES=3

# 读取参数
DEVICE_NAME="${1:-$DEFAULT_DEVICE_NAME}"
WAIT_TIME="${2:-$DEFAULT_WAIT_TIME}"

echo -e "${YELLOW}Starting E2E Test Environment...${NC}"

# 1. 查找设备ID
echo "Finding device: $DEVICE_NAME"
DEVICE_ID=$(xcrun simctl list devices | grep "$DEVICE_NAME" | grep -v "unavailable" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}✗ Device '$DEVICE_NAME' not found${NC}"
    echo "Available devices:"
    xcrun simctl list devices | grep "iPhone"
    exit 1
fi

echo -e "${GREEN}✓ Found device: $DEVICE_ID${NC}"

# 2. 检查设备状态
DEVICE_STATE=$(xcrun simctl list devices | grep "$DEVICE_ID" | sed 's/.* (\(.*\))/\1/')

if [ "$DEVICE_STATE" == "Booted" ]; then
    echo -e "${GREEN}✓ Device already booted${NC}"
else
    # 3. 启动设备
    echo "Booting device..."
    xcrun simctl boot "$DEVICE_ID"
    echo -e "${GREEN}✓ Device boot command sent${NC}"
fi

# 4. CRITICAL: 等待 WebDriverAgent 初始化
echo -e "${YELLOW}⏳ Waiting ${WAIT_TIME}s for WebDriverAgent to initialize...${NC}"
echo "This wait is CRITICAL - do not skip!"

for i in $(seq 1 $WAIT_TIME); do
    echo -n "."
    sleep 1
done
echo ""

# 5. 验证设备连接
echo "Verifying device connection..."

RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if command -v mobile-mcp &> /dev/null; then
        # 使用 mobile-mcp 验证
        if mobile-mcp list-devices 2>&1 | grep -q "online"; then
            echo -e "${GREEN}✓ WebDriverAgent is ready!${NC}"
            echo -e "${GREEN}✓ Device is online and ready for testing${NC}"
            exit 0
        fi
    else
        # 没有 mobile-mcp，只能假设已就绪
        echo -e "${YELLOW}⚠ mobile-mcp not installed, assuming device is ready${NC}"
        exit 0
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo -e "${YELLOW}⚠ Device not ready, retrying in 5 seconds... ($RETRY_COUNT/$MAX_RETRIES)${NC}"
        sleep 5
    fi
done

# 6. 最终失败
echo -e "${RED}✗ Failed to verify device connection after $MAX_RETRIES retries${NC}"
echo ""
echo "Troubleshooting steps:"
echo "1. Check if Xcode is installed: xcodebuild -version"
echo "2. Check simulator status: xcrun simctl list devices"
echo "3. Try manually: xcrun simctl boot '$DEVICE_ID'"
echo "4. Check mobile-mcp: mobile-mcp list-devices"
echo ""
exit 1
