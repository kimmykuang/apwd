#!/bin/bash
# tests/e2e/webdav_manager.sh
# 管理 Mock WebDAV 服务器的启动和停止

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/reports/webdav_server.pid"
LOG_FILE="$SCRIPT_DIR/reports/webdav_server.log"
PYTHON_SCRIPT="$SCRIPT_DIR/mock_webdav_server.py"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

start_server() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠ WebDAV 服务器已经在运行 (PID: $PID)${NC}"
            return 0
        else
            # PID 文件存在但进程不在，清理
            rm -f "$PID_FILE"
        fi
    fi

    echo -e "${YELLOW}🚀 正在启动 Mock WebDAV 服务器...${NC}"

    # 在后台启动服务器
    nohup python3 "$PYTHON_SCRIPT" > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!

    # 保存 PID
    echo "$SERVER_PID" > "$PID_FILE"

    # 等待服务器启动
    sleep 2

    # 验证服务器是否启动成功
    if ps -p "$SERVER_PID" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ WebDAV 服务器已启动${NC}"
        echo -e "${GREEN}   PID: $SERVER_PID${NC}"
        echo -e "${GREEN}   URL: http://127.0.0.1:8080/${NC}"
        echo -e "${GREEN}   用户名: testuser${NC}"
        echo -e "${GREEN}   密码: testpass123${NC}"
        echo -e "${GREEN}   日志: $LOG_FILE${NC}"
        return 0
    else
        echo -e "${RED}❌ WebDAV 服务器启动失败${NC}"
        echo -e "${RED}   查看日志: cat $LOG_FILE${NC}"
        rm -f "$PID_FILE"
        return 1
    fi
}

stop_server() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}⚠ WebDAV 服务器未运行${NC}"
        return 0
    fi

    PID=$(cat "$PID_FILE")

    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}🛑 正在停止 WebDAV 服务器 (PID: $PID)...${NC}"
        kill "$PID" 2>/dev/null || true

        # 等待进程结束
        for i in {1..10}; do
            if ! ps -p "$PID" > /dev/null 2>&1; then
                break
            fi
            sleep 0.5
        done

        # 如果还在运行，强制杀死
        if ps -p "$PID" > /dev/null 2>&1; then
            kill -9 "$PID" 2>/dev/null || true
        fi

        echo -e "${GREEN}✅ WebDAV 服务器已停止${NC}"
    else
        echo -e "${YELLOW}⚠ 进程已不存在 (PID: $PID)${NC}"
    fi

    rm -f "$PID_FILE"
}

status_server() {
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}WebDAV 服务器: 未运行${NC}"
        return 1
    fi

    PID=$(cat "$PID_FILE")

    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}WebDAV 服务器: 运行中${NC}"
        echo -e "  PID: $PID"
        echo -e "  URL: http://127.0.0.1:8080/"
        echo -e "  日志: $LOG_FILE"
        return 0
    else
        echo -e "${RED}WebDAV 服务器: 已停止${NC}"
        echo -e "${YELLOW}  (PID 文件存在但进程不在)${NC}"
        rm -f "$PID_FILE"
        return 1
    fi
}

case "${1:-}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 1
        start_server
        ;;
    status)
        status_server
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        echo ""
        echo "Commands:"
        echo "  start   - 启动 Mock WebDAV 服务器"
        echo "  stop    - 停止 Mock WebDAV 服务器"
        echo "  restart - 重启 Mock WebDAV 服务器"
        echo "  status  - 查看服务器状态"
        exit 1
        ;;
esac
