# Mobile MCP Setup Guide

使用 AI 直接操作 iOS/Android 模拟器进行测试

## 什么是 Mobile MCP？

[mobile-mcp](https://github.com/mobile-next/mobile-mcp) 是一个 MCP (Model Context Protocol) 服务器，可以让 Claude 直接控制模拟器进行人机交互。

**优势：**
- ✅ 自然语言描述测试场景
- ✅ AI 自动操作模拟器
- ✅ 可以验证视觉效果（截图）
- ✅ 快速探索性测试

## 安装步骤

### 1. 安装依赖

```bash
# 确保有 Node.js 22+
node --version  # 应该 >= 22

# 如果版本太低
brew install node@22

# 确保有 Xcode Command Line Tools (iOS)
xcode-select --install

# 确保有 Android Platform Tools (Android)
brew install android-platform-tools
```

### 2. 安装 mobile-mcp

```bash
# 克隆项目到合适的位置
cd ~/Projects  # 或你喜欢的目录
git clone https://github.com/mobile-next/mobile-mcp.git
cd mobile-mcp

# 安装依赖
npm install

# 构建
npm run build

# 测试运行（可选）
npm start
```

### 3. 配置 Claude Code

#### 方式A：通过配置文件

编辑 `~/.claude/config.json` (如果没有就创建)：

```json
{
  "mcpServers": {
    "mobile": {
      "command": "node",
      "args": ["/Users/YOUR_USERNAME/Projects/mobile-mcp/build/index.js"],
      "env": {}
    }
  }
}
```

**重要：替换路径为你的实际路径！**

#### 方式B：通过 VSCode 设置

1. 打开 VSCode 设置 (Cmd+,)
2. 搜索 "Claude MCP"
3. 添加 MCP 服务器配置

### 4. 重启 VSCode

配置完成后，重启 VSCode 以加载 MCP 服务器。

## 使用方法

### 重要说明：模拟器是独立窗口

⚠️ **mobile-mcp 不会在 VSCode 中打开模拟器 tab**

实际工作方式：
- 📱 模拟器是独立的系统窗口（Simulator.app）
- 💬 在 VSCode 的 Claude Code 中对话
- 🤖 Claude 通过 mobile-mcp API 控制模拟器
- 📸 Claude 会截图并显示在聊天中

你的屏幕布局：
```
┌──────────────────┐    ┌─────────────────────┐
│  VSCode          │    │  iOS Simulator      │
│  (Claude聊天)    │    │  (独立窗口)         │
│                  │    │                     │
│  You: 测试APWD   │    │  [APWD App运行]     │
│                  │    │   ↑ 自动操作        │
│  Claude:         │────→  点击、输入、滑动   │
│  ✓ 已截图        │    │                     │
│  ✓ 点击按钮      │    └─────────────────────┘
│  📸 [截图显示]   │
└──────────────────┘
```

### 启动模拟器

**方式1：使用快速启动脚本（推荐）**

```bash
# 在项目根目录运行
./scripts/start_simulator.sh
```

脚本会自动：
- 找到可用的 iPhone 模拟器
- 启动模拟器
- 打开 Simulator.app
- 显示设备 ID

**方式2：手动启动**

```bash
# iOS 模拟器
open -a Simulator

# 或者列出可用设备
xcrun simctl list devices

# 启动特定设备
xcrun simctl boot <device-uuid>

# Android 模拟器
emulator -list-avds
emulator -avd <avd-name>
```

### 在 Claude Code 中测试

在 VSCode 中打开 Claude Code 聊天，然后说：

```
请帮我测试APWD应用：
1. 在iOS模拟器中打开APWD
2. 设置主密码为 TestPassword123!
3. 添加一个密码条目：
   - 标题：GitHub
   - 用户名：test@github.com
   - 密码：SecurePass123!
4. 截图验证是否成功添加
5. 告诉我测试结果
```

Claude 会自动：
- 调用 mobile-mcp API
- 操作模拟器
- 截图验证
- 报告结果

## 常见使用场景

### 场景1：快速验证新功能

```
帮我测试刚写的WebDAV备份功能：
1. 打开设置
2. 配置WebDAV（使用测试服务器）
3. 创建两个测试密码
4. 点击备份按钮
5. 截图显示备份成功的消息
```

### 场景2：重现Bug

```
帮我重现这个bug：
1. 打开APWD
2. 添加一个密码但不填写用户名
3. 点击保存
4. 查看是否会崩溃
5. 截图错误信息
```

### 场景3：视觉验证

```
检查UI是否正确：
1. 打开密码列表
2. 截图主界面
3. 打开设置页面
4. 截图设置页面
5. 告诉我布局是否合理，按钮是否对齐
```

### 场景4：完整流程测试

```
执行完整的用户流程测试：
1. 首次启动并设置主密码
2. 创建一个Work分组
3. 在Work分组下添加3个密码
4. 搜索其中一个密码
5. 查看密码详情
6. 编辑密码
7. 删除密码
8. 每一步都截图并验证
```

## 最佳实践

### ✅ 适合用 mobile-mcp 的场景

- 开发过程中的快速验证
- 演示功能给他人看
- 探索性测试
- 视觉验证（布局、颜色、间距）
- 一次性的复杂测试流程

### ❌ 不适合用 mobile-mcp 的场景

- CI/CD 自动化测试（用传统测试代码）
- 精确的性能测试
- 需要稳定重复的回归测试
- 大量重复执行的测试

### 推荐组合使用

1. **开发时**：用 mobile-mcp 快速验证
2. **提交前**：运行传统自动化测试
3. **发布前**：两者都运行 + 人工验证

## 故障排除

### mobile-mcp 无法连接模拟器

```bash
# iOS: 检查模拟器是否运行
xcrun simctl list | grep Booted

# Android: 检查adb连接
adb devices
```

### Claude 找不到 mobile-mcp

检查：
1. `~/.claude/config.json` 路径是否正确
2. VSCode 是否已重启
3. mobile-mcp 是否成功构建

```bash
cd ~/Projects/mobile-mcp
ls build/index.js  # 应该存在
```

### 操作太慢

mobile-mcp 需要截图 + AI分析，比传统测试慢。这是正常的。适合探索性测试，不适合大量重复测试。

## 参考资料

- [mobile-mcp GitHub](https://github.com/mobile-next/mobile-mcp)
- [Model Context Protocol 文档](https://modelcontextprotocol.io/)
- [Flutter 测试文档](https://docs.flutter.dev/testing)

## 当前测试策略

我们的APWD项目使用**混合测试策略**：

| 测试类型 | 工具 | 用途 |
|---------|------|------|
| 单元测试 | Flutter Test | 验证业务逻辑 (48个测试) |
| 服务层集成测试 | Flutter Test | 验证服务交互 |
| UI集成测试 | Flutter Test | 验证完整流程 |
| AI探索测试 | mobile-mcp | 快速验证和视觉检查 |

这样既有自动化保护，又有灵活的探索能力！
