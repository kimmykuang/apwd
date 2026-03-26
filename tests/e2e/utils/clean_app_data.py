#!/usr/bin/env python3
"""
清理应用数据

功能：
- 卸载并重新安装应用以清空数据
- 用于测试场景间的状态隔离

使用：python3 clean_app_data.py <device_id>
"""
import subprocess
import sys
import json


def clean_app_data(device_id, bundle_id="com.apwd.app"):
    """卸载并重新安装应用"""
    try:
        # 卸载应用
        subprocess.run([
            "xcrun", "simctl", "uninstall",
            device_id, bundle_id
        ], check=True)

        # 重新安装（需要提供 .app 路径）
        app_path = "build/ios/iphonesimulator/Runner.app"
        subprocess.run([
            "xcrun", "simctl", "install",
            device_id, app_path
        ], check=True)

        print(json.dumps({"status": "success"}))
        sys.exit(0)

    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    device_id = sys.argv[1] if len(sys.argv) > 1 else None
    if not device_id:
        print(json.dumps({"status": "error", "message": "Missing device_id"}))
        sys.exit(1)
    clean_app_data(device_id)
