#!/usr/bin/env python3
"""
Mock WebDAV Server for E2E Testing
启动一个本地 WebDAV 服务器用于测试 WebDAV 备份/恢复功能
"""

import sys
import os
from pathlib import Path

def install_wsgidav():
    """安装 wsgidav 包"""
    print("📦 检测到 wsgidav 未安装，正在安装...")
    import subprocess
    try:
        subprocess.check_call([
            sys.executable, "-m", "pip", "install",
            "wsgidav", "cheroot", "-q"
        ])
        print("✅ wsgidav 安装成功")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ 安装失败: {e}")
        return False

def main():
    # 检查 wsgidav 是否已安装
    try:
        import wsgidav
    except ImportError:
        if not install_wsgidav():
            sys.exit(1)
        # 重新导入
        import wsgidav

    from wsgidav.wsgidav_app import WsgiDAVApp
    from cheroot import wsgi

    # 配置 WebDAV 服务器
    script_dir = Path(__file__).parent.parent
    webdav_root = script_dir / "reports" / "webdav_test_data"
    webdav_root.mkdir(parents=True, exist_ok=True)

    config = {
        "host": "127.0.0.1",
        "port": 8080,
        "provider_mapping": {
            "/": str(webdav_root)
        },
        "simple_dc": {
            "user_mapping": {
                "*": {
                    "testuser": {
                        "password": "testpass123",
                        "description": "Test user for E2E testing",
                    }
                }
            }
        },
        "verbose": 1,
    }

    print("╔════════════════════════════════════════════════════════╗")
    print("║        Mock WebDAV Server for E2E Testing         ║")
    print("╚════════════════════════════════════════════════════════╝")
    print()
    print(f"📁 WebDAV Root: {webdav_root}")
    print(f"🌐 Server URL: http://127.0.0.1:8080/")
    print(f"👤 Username: testuser")
    print(f"🔑 Password: testpass123")
    print()
    print("✅ WebDAV 服务器已启动")
    print("💡 按 Ctrl+C 停止服务器")
    print()

    # 创建 WSGI 应用
    app = WsgiDAVApp(config)

    # 启动服务器
    server = wsgi.Server(
        bind_addr=(config["host"], config["port"]),
        wsgi_app=app,
    )

    try:
        server.start()
    except KeyboardInterrupt:
        print("\n🛑 正在停止 WebDAV 服务器...")
        server.stop()
        print("✅ 服务器已停止")

if __name__ == "__main__":
    main()
