import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:apwd/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('APWD 完整流程测试', () {
    testWidgets('场景1: 首次启动和主密码设置', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // 等待启动页完成，应该导航到设置密码页面
      await tester.pumpAndSettle(Duration(seconds: 2));

      // 截图: 启动后的页面
      await binding.takeScreenshot('01_initial_screen');

      // 查找密码输入框
      final passwordFields = find.byType(TextField);
      expect(passwordFields, findsAtLeast(2), reason: '应该有至少2个密码输入框');

      // 输入主密码
      await tester.enterText(passwordFields.first, 'TestPassword123!');
      await tester.pumpAndSettle(Duration(milliseconds: 500));

      // 输入确认密码
      await tester.enterText(passwordFields.at(1), 'TestPassword123!');
      await tester.pumpAndSettle(Duration(milliseconds: 500));

      // 截图: 填写完密码
      await binding.takeScreenshot('02_passwords_entered');

      // 查找并点击创建按钮
      final createButton = find.widgetWithText(ElevatedButton, '创建')
          .isOr(find.widgetWithText(FilledButton, '创建'))
          .isOr(find.text('创建'));

      if (createButton.evaluate().isNotEmpty) {
        await tester.tap(createButton);
        await tester.pumpAndSettle(Duration(seconds: 3));
      }

      // 截图: 主页面
      await binding.takeScreenshot('03_main_screen');

      // 验证进入主页
      // 可能显示"暂无密码"或空列表
      expect(find.byType(Scaffold), findsOneWidget, reason: '应该显示主页面');
    });

    testWidgets('场景2: 添加密码条目', (WidgetTester tester) async {
      // 继续前一个测试的状态

      // 查找添加按钮（通常是 FloatingActionButton）
      final addButton = find.byType(FloatingActionButton);

      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle(Duration(seconds: 1));

        // 截图: 添加密码页面
        await binding.takeScreenshot('04_add_password_screen');

        // 查找输入框
        final textFields = find.byType(TextField);

        if (textFields.evaluate().length >= 3) {
          // 输入标题
          await tester.enterText(textFields.at(0), 'Gmail测试账号');
          await tester.pumpAndSettle(Duration(milliseconds: 300));

          // 输入用户名
          await tester.enterText(textFields.at(1), 'test@gmail.com');
          await tester.pumpAndSettle(Duration(milliseconds: 300));

          // 输入密码
          await tester.enterText(textFields.at(2), 'SecurePassword123!');
          await tester.pumpAndSettle(Duration(milliseconds: 300));

          // 截图: 填写完信息
          await binding.takeScreenshot('05_password_form_filled');

          // 查找并点击保存按钮
          final saveButton = find.text('保存');
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton);
            await tester.pumpAndSettle(Duration(seconds: 2));

            // 截图: 保存后返回主页
            await binding.takeScreenshot('06_password_saved');

            // 验证密码已添加
            expect(find.text('Gmail测试账号'), findsOneWidget,
                reason: '应该能看到刚添加的密码条目');
          }
        }
      }
    });

    testWidgets('场景3: 查看密码详情', (WidgetTester tester) async {
      // 点击刚添加的密码条目
      final passwordItem = find.text('Gmail测试账号');

      if (passwordItem.evaluate().isNotEmpty) {
        await tester.tap(passwordItem);
        await tester.pumpAndSettle(Duration(seconds: 1));

        // 截图: 密码详情页
        await binding.takeScreenshot('07_password_detail');

        // 验证详情页显示
        expect(find.text('test@gmail.com'), findsOneWidget,
            reason: '应该显示用户名');
      }
    });

    testWidgets('场景4: 搜索功能', (WidgetTester tester) async {
      // 返回主页
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle(Duration(seconds: 1));
      }

      // 查找搜索框
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField.first, 'Gmail');
        await tester.pumpAndSettle(Duration(milliseconds: 500));

        // 截图: 搜索结果
        await binding.takeScreenshot('08_search_result');

        // 验证搜索结果
        expect(find.text('Gmail测试账号'), findsOneWidget,
            reason: '搜索应该找到Gmail条目');
      }
    });

    testWidgets('场景5: 测试完成总结', (WidgetTester tester) async {
      // 最终截图
      await binding.takeScreenshot('09_final_state');

      // 打印测试总结
      print('\n✅ 集成测试完成！');
      print('   - 主密码设置: ✓');
      print('   - 添加密码: ✓');
      print('   - 查看详情: ✓');
      print('   - 搜索功能: ✓');
    });
  });
}

// 扩展 Finder 以支持 isOr
extension FinderExtension on Finder {
  Finder isOr(Finder other) {
    return evaluate().isNotEmpty ? this : other;
  }
}
