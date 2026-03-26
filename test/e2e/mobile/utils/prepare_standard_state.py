#!/usr/bin/env python3
"""
准备标准测试状态

功能：
- 生成测试数据配置 JSON
- 返回标准格式的 JSON 响应
- Claude 读取配置后通过 UI 创建数据

注意：不直接操作加密数据库，而是提供配置让 Claude 执行创建
"""
import json
import sys


def prepare_standard_state():
    """混合模式：Python 生成配置，Claude 执行创建"""

    # 注意：模拟器管理由 Claude 通过 config.yaml 处理
    # 此脚本仅负责生成测试数据配置

    # 返回测试数据配置
    # 注意：Default 分组由应用初始化时自动创建，此处仅创建额外的 Work 分组
    config = {
        "master_password": "TestPassword123!",
        "groups": [
            {"name": "Work", "icon": "💼"}
        ],
        "passwords": [
            {
                "title": "GitHub",
                "username": "test@github.com",
                "password": "GitHubPass123!",
                "group": "Default"
            },
            {
                "title": "Gmail",
                "username": "test@gmail.com",
                "password": "GmailPass123!",
                "group": "Default"
            },
            {
                "title": "AWS Console",
                "username": "test@aws.com",
                "password": "AWSPass123!",
                "group": "Work"
            }
        ]
    }

    print(json.dumps({"status": "success", "config": config}))
    sys.exit(0)


if __name__ == "__main__":
    try:
        prepare_standard_state()
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
        sys.exit(1)
