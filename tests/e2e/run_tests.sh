#!/bin/bash
# tests/e2e/run_tests.sh
# APWD E2E 测试便捷启动脚本

set -e

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
  *) echo "无效选择"; exit 1 ;;
esac

if [ "$SCENARIO" = "all" ]; then
  PROMPT="执行 APWD 完整 E2E 测试套件，生成汇总报告"
else
  PROMPT="执行测试场景 tests/e2e/scenarios/$SCENARIO"
fi

echo ""
echo "📱 正在启动测试..."
echo ""

# 调用 Claude CLI
claude -p "$PROMPT"
