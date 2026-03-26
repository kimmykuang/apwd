# Mock WebDAV Server for E2E Testing

## 概述

为了支持 WebDAV 功能的自动化测试，我们提供了一个本地 Mock WebDAV 服务器。该服务器基于 `wsgidav`，可以在测试时自动启动，无需配置外部 WebDAV 服务器。

## 快速开始

### 1. 启动服务器

```bash
cd tests/e2e
./webdav_manager.sh start
```

### 2. 查看状态

```bash
./webdav_manager.sh status
```

### 3. 停止服务器

```bash
./webdav_manager.sh stop
```

## 连接信息

| 参数 | 值 |
|------|-----|
| **URL** | `http://127.0.0.1:8080/` |
| **用户名** | `testuser` |
| **密码** | `testpass123` |
| **根目录** | `tests/e2e/reports/webdav_test_data/` |

## 配置说明

在 `config.yaml` 中已配置 Mock 服务器：

```yaml
webdav_test:
  use_mock_server: true  # 使用 Mock 服务器
  mock_server:
    enabled: true
    url: "http://127.0.0.1:8080"
    username: "testuser"
    password: "testpass123"
    remote_path: "/APWD_Test"
    auto_start: true   # 测试时自动启动
    auto_stop: true    # 测试完成后自动停止
```

## 文件说明

### 1. `mock_webdav_server.py`
WebDAV 服务器实现脚本，基于 `wsgidav` 包。

**功能**:
- 自动安装依赖 (`wsgidav`, `cheroot`)
- 配置简单认证 (用户名/密码)
- 支持所有标准 WebDAV 操作 (PROPFIND, GET, PUT, DELETE 等)

### 2. `webdav_manager.sh`
服务器管理脚本，提供启动/停止/状态查询功能。

**命令**:
- `start` - 启动服务器（后台运行）
- `stop` - 停止服务器
- `restart` - 重启服务器
- `status` - 查看服务器状态

**特性**:
- 自动 PID 管理
- 日志记录
- 进程检测
- 优雅关闭

## 测试用法

### 手动测试

```bash
# 1. 启动服务器
./webdav_manager.sh start

# 2. 运行 WebDAV 测试场景
./run_tests.sh
# 选择 "4. webdav_test - WebDAV 备份"

# 3. 测试完成后停止服务器
./webdav_manager.sh stop
```

### 自动测试

测试框架会根据 `config.yaml` 中的 `auto_start` 和 `auto_stop` 配置，自动管理服务器生命周期：

```yaml
mock_server:
  auto_start: true   # 测试开始前自动启动
  auto_stop: true    # 测试结束后自动停止
```

## 手动连接测试

### 使用 curl

```bash
# PROPFIND 请求（列出目录）
curl -u testuser:testpass123 http://127.0.0.1:8080/ \
  -X PROPFIND --header "Depth: 1"

# PUT 请求（上传文件）
curl -u testuser:testpass123 http://127.0.0.1:8080/test.txt \
  -X PUT --data "Hello WebDAV"

# GET 请求（下载文件）
curl -u testuser:testpass123 http://127.0.0.1:8080/test.txt

# DELETE 请求（删除文件）
curl -u testuser:testpass123 http://127.0.0.1:8080/test.txt \
  -X DELETE
```

### 使用 macOS Finder

1. 打开 Finder
2. 按 `Cmd+K` 打开"连接服务器"
3. 输入: `http://127.0.0.1:8080`
4. 输入用户名 `testuser` 和密码 `testpass123`
5. 可以像本地文件夹一样操作

## 日志和数据位置

| 项目 | 路径 |
|------|------|
| **服务器日志** | `tests/e2e/reports/webdav_server.log` |
| **PID 文件** | `tests/e2e/reports/webdav_server.pid` |
| **数据目录** | `tests/e2e/reports/webdav_test_data/` |

所有这些文件都已添加到 `.gitignore`，不会被提交到版本控制。

## 故障排除

### 问题 1: 服务器启动失败

**检查**:
```bash
cat tests/e2e/reports/webdav_server.log
```

**常见原因**:
- 端口 8080 已被占用
- Python 包未正确安装
- 权限问题

**解决方案**:
```bash
# 检查端口占用
lsof -i :8080

# 重新安装依赖
pip3 install wsgidav cheroot --force-reinstall

# 检查权限
ls -l mock_webdav_server.py webdav_manager.sh
```

### 问题 2: 连接被拒绝

**检查服务器状态**:
```bash
./webdav_manager.sh status
```

**解决方案**:
- 确保服务器已启动
- 检查防火墙设置
- 确认URL使用 `http://` 而非 `https://`

### 问题 3: 认证失败

**确认凭据**:
- 用户名: `testuser`
- 密码: `testpass123`
- 区分大小写

## 优势

相比使用真实 WebDAV 服务器：

✅ **零配置** - 无需外部服务器设置
✅ **快速启动** - 2-3 秒即可启动
✅ **隔离环境** - 测试数据独立，不影响生产
✅ **自动化友好** - 可编程控制启动/停止
✅ **跨平台** - macOS, Linux 都支持
✅ **易于调试** - 本地日志，完全可控

## 限制

⚠️ **仅用于测试** - 不应在生产环境使用
⚠️ **单线程** - 并发性能有限
⚠️ **HTTP 协议** - 不支持 HTTPS (测试环境可接受)
⚠️ **简单认证** - 仅基本认证，无 OAuth 等高级认证

## 迁移到真实服务器

如果需要测试真实 WebDAV 服务器，修改 `config.yaml`:

```yaml
webdav_test:
  use_mock_server: false  # 禁用 Mock 服务器
  real_server:
    enabled: true         # 启用真实服务器
    url: "https://your-webdav-server.com"
    username: "${WEBDAV_TEST_USER}"
    password: "${WEBDAV_TEST_PASSWORD}"
    remote_path: "/APWD_Test"
```

然后设置环境变量：

```bash
export WEBDAV_TEST_USER="your_username"
export WEBDAV_TEST_PASSWORD="your_password"
```

## 依赖

- **Python 3.7+**
- **wsgidav** - WebDAV 服务器实现
- **cheroot** - WSGI HTTP 服务器

依赖会在首次运行时自动安装。

## 维护

定期清理测试数据：

```bash
# 删除所有测试数据
rm -rf tests/e2e/reports/webdav_test_data/*

# 删除日志文件
rm -f tests/e2e/reports/webdav_server.log

# 清理 PID 文件
rm -f tests/e2e/reports/webdav_server.pid
```

---

**版本**: 1.0.0
**最后更新**: 2026-03-26
**维护者**: APWD E2E Test Team
