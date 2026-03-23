# UI 集成测试

本目录包含APWD应用的UI集成测试，测试完整的用户交互流程。

## 测试内容

`app_test.dart` 涵盖以下场景：

1. **场景1**：首次启动和主密码设置
2. **场景2**：添加密码条目
3. **场景3**：查看密码详情
4. **场景4**：搜索功能
5. **场景5**：Group 管理

## 运行测试

### 前提条件

需要连接真实设备或启动模拟器。

**检查可用设备：**
```bash
flutter devices
```

### 运行方式

**在特定设备上运行：**
```bash
flutter test test/ui/app_test.dart -d <device_id>
```

**在iOS模拟器上运行：**
```bash
flutter test test/ui/app_test.dart -d iPhone
```

**在Android模拟器上运行：**
```bash
flutter test test/ui/app_test.dart -d emulator-5554
```

### 截图

测试运行时会自动生成截图，保存在：
- iOS: `build/app/outputs/`
- Android: `/sdcard/Pictures/`

## 最近更新

- ✅ 适配 `addPostFrameCallback` 延迟加载模式
- ✅ 更新按钮查找方式（使用 `widgetWithText`）
- ✅ 增加等待时间以适应异步加载
- ✅ 从 `integration_test/` 移动到 `test/ui/`

## 注意事项

- UI测试需要在真实设备或模拟器上运行，不能使用 `flutter test` 直接运行
- 测试会创建临时数据，完成后会自动清理
- 确保设备有足够的存储空间用于截图
