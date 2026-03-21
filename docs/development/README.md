# 开发文档 (Development Documentation)

本目录包含APWD密码管理器的开发相关文档。

## 📋 目录

### 平台设置指南
- [Android开发环境设置](ANDROID_SETUP.md) - Android真机测试、构建配置、常见问题
- [iOS开发环境设置](IOS_SETUP.md) - iOS开发环境配置
- [Web平台说明](WEB_PLATFORM.md) - Web平台不支持的原因及技术限制

### 开发指南
- [**调试指南 (DEBUGGING_GUIDE.md)**](DEBUGGING_GUIDE.md) ⭐ **必读！**
  - 系统性问题排查方法论
  - 常见陷阱和解决方案
  - 真实案例分析（Provider崩溃问题）
  - 何时使用Plan Mode进行深度分析
  - 调试工具和技巧

## 🎯 快速导航

### 遇到Bug？
1. 先阅读 [调试指南](DEBUGGING_GUIDE.md)
2. 检查调试指南中的"快速参考"部分
3. 如果尝试3次以上仍未解决 → 进入Plan Mode

### 设置开发环境？
- Android开发 → [ANDROID_SETUP.md](ANDROID_SETUP.md)
- iOS开发 → [IOS_SETUP.md](IOS_SETUP.md)

### 为什么不支持Web？
→ [WEB_PLATFORM.md](WEB_PLATFORM.md)

## 💡 最佳实践

### 调试时
- ✅ 深入分析根本原因，不要只看症状
- ✅ 追踪完整的调用链和数据流
- ✅ 同一方向尝试3次失败后，立即换方向
- ✅ 使用Plan Mode进行系统分析
- ❌ 不要在错误的方向上反复尝试
- ❌ 不要只依赖错误信息猜测

### 开发时
- ✅ 添加带标签的日志（如 `[AUTH]`, `[DEBUG]`）
- ✅ 异步操作后检查 `mounted`
- ✅ Context使用前确认来源
- ✅ dispose时清理所有资源
- ❌ 不要在build方法中修改状态
- ❌ 不要在notifyListeners过程中触发修改

## 📚 相关资源

### Flutter官方文档
- [Widget生命周期](https://flutter.dev/docs/development/ui/widgets-intro)
- [State管理](https://flutter.dev/docs/development/data-and-backend/state-mgmt)
- [Provider包](https://pub.dev/packages/provider)

### 调试工具
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools/overview)
- [Android Studio调试](https://developer.android.com/studio/debug)
- [Xcode调试](https://developer.apple.com/documentation/xcode/debugging)

---

*维护者：开发团队*
*最后更新：2026-03-21*
