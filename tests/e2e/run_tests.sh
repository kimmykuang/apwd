#!/bin/bash
# tests/e2e/run_tests.sh
# APWD E2E 测试便捷启动脚本

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 启动 APWD E2E 测试"
echo ""
echo "可选场景："
echo "  1. search_test - 搜索功能"
echo "  2. password_crud_test - 密码 CRUD"
echo "  3. groups_test - 分组管理"
echo "  4. webdav_test - WebDAV 备份"
echo "  5. export_import_test - 导出导入"
echo "  6. all - 执行所有测试"
echo ""
read -p "请选择 (1-6): " choice

case $choice in
  1) SCENARIO="search_test.yaml" ;;
  2) SCENARIO="password_crud_test.yaml" ;;
  3) SCENARIO="groups_test.yaml" ;;
  4) SCENARIO="webdav_test.yaml" ;;
  5) SCENARIO="export_import_test.yaml" ;;
  6) SCENARIO="all" ;;
  *) echo -e "${RED}无效选择${NC}"; exit 1 ;;
esac

if [ "$SCENARIO" = "all" ]; then
  PROMPT="执行 APWD 完整 E2E 测试套件，生成汇总报告"
else
  PROMPT="执行测试场景 tests/e2e/scenarios/$SCENARIO"
fi

echo ""
echo -e "${YELLOW}📱 准备测试环境...${NC}"
echo ""

# CRITICAL: 启动模拟器并等待 WebDriverAgent
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/utils/start_simulator.sh" ]; then
  echo -e "${YELLOW}正在启动模拟器并等待 WebDriverAgent 初始化...${NC}"
  "$SCRIPT_DIR/utils/start_simulator.sh" "iPhone 16" 15

  if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 模拟器启动失败，无法继续测试${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}⚠ 启动脚本不存在，跳过自动启动${NC}"
  echo -e "${YELLOW}⚠ 请确保模拟器已启动并等待至少 15 秒${NC}"
  read -p "按回车继续..."
fi

echo ""
echo -e "${GREEN}✓ 环境准备完成${NC}"
echo ""
echo -e "${YELLOW}📱 正在启动测试...${NC}"
echo ""

# 调用 Claude CLI
claude -p "$PROMPT"
