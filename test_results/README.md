# 测试结果目录

本目录包含 APWD 自动化测试的结果。

## 📊 最新测试结果

**测试时间**: 2026-03-21 14:49:44
**测试平台**: iOS
**测试结果**: ✅ 13/13 通过

---

## 📁 文件说明

本目录保留最新一次的完整测试结果：

### 测试报告
- `YYYYMMDD_HHMMSS_report.md` - 人类可读的测试报告

### iOS 测试文件
- `ios_YYYYMMDD_HHMMSS_result.txt` - 详细测试输出
- `ios_YYYYMMDD_HHMMSS_logs.txt` - 设备日志
- `ios_YYYYMMDD_HHMMSS_analysis.json` - 结构化分析数据
- `ios_YYYYMMDD_HHMMSS_screenshots/` - 测试截图

---

## 🔄 测试结果管理

### 自动清理

每次运行测试时，旧的测试结果会被自动归档或删除，只保留最新的测试结果。

### 手动运行测试

```bash
# 运行 iOS 自动化测试
python3 autonomous_test_runner.py ios

# 运行 Android 自动化测试
python3 autonomous_test_runner.py android
```

测试完成后，新的结果会出现在此目录。

---

## 📖 查看测试结果

### 快速查看

```bash
# 查看测试报告
cat test_results/最新时间戳_report.md

# 查看结构化分析
cat test_results/ios_最新时间戳_analysis.json

# 查看截图
open test_results/ios_最新时间戳_screenshots/
```

### 测试分析 JSON 格式

```json
{
  "platform": "ios",
  "timestamp": "20260321_144944",
  "success": true,
  "tests_passed": 13,
  "tests_failed": 0,
  "errors": [],
  "warnings": []
}
```

---

## 🎯 测试覆盖

当前测试覆盖以下场景：

1. ✅ 首次启动和主密码设置
2. ✅ 添加密码条目
3. ✅ 查看密码详情
4. ✅ 搜索功能
5. ✅ Group 管理

---

## 📚 相关文档

- [测试文档](../docs/testing/TESTING.md) - 完整测试文档
- [README.md](../README.md) - 项目说明

---

**维护者**: AI Agent
**自动生成**: 由 autonomous_test_runner.py 生成
