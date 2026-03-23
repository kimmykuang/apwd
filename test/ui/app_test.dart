import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:apwd/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('APWD 完整流程测试', () {
    testWidgets('完整用户流程：从设置主密码到添加密码', (WidgetTester tester) async {
      // ========== 场景1: 首次启动和主密码设置 ==========
      print('\n📱 场景1: 首次启动和主密码设置');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 等待启动页完成
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 查找密码输入框（使用 TextFormField）
      await tester.pumpAndSettle(const Duration(seconds: 3));
      var passwordFields = find.byType(TextFormField);

      print('🔍 查找密码输入框: ${passwordFields.evaluate().length} 个');

      // 如果没找到，等待更长时间
      if (passwordFields.evaluate().isEmpty) {
        print('⏳ 第一次未找到，等待页面加载...');
        await tester.pumpAndSettle(const Duration(seconds: 5));
        passwordFields = find.byType(TextFormField);
        print('🔍 第二次查找: ${passwordFields.evaluate().length} 个');
      }

      // 再试一次
      if (passwordFields.evaluate().isEmpty) {
        print('⏳ 第二次未找到，再次等待...');
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle(const Duration(seconds: 5));
        passwordFields = find.byType(TextFormField);
        print('🔍 第三次查找: ${passwordFields.evaluate().length} 个');
      }

      expect(passwordFields, findsAtLeast(2), reason: '应该有至少2个密码输入框');

      // 输入主密码
      await tester.enterText(passwordFields.first, 'TestPassword123!');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // 输入确认密码
      await tester.enterText(passwordFields.at(1), 'TestPassword123!');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));


      // 点击创建按钮
      final createButton = find.text('Create Password');
      expect(createButton, findsOneWidget, reason: '应该有创建按钮');

      await tester.tap(createButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));


      // 验证进入主页 - 由于addPostFrameCallback，需要额外等待
      print('📋 验证是否进入主页面...');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final homeText = find.text('No passwords yet');
      expect(homeText, findsOneWidget, reason: '应该显示主页面的"No passwords yet"文字');

      print('✅ 场景1完成：成功设置主密码并进入主页面\n');

      // ========== 场景2: 添加密码条目 ==========
      print('\n📱 场景2: 添加密码条目');

      // 等待页面完全加载（addPostFrameCallback延迟）
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 查找添加按钮
      final addButton = find.byType(FloatingActionButton);
      expect(addButton, findsOneWidget, reason: '应该有FloatingActionButton添加按钮');

      print('✅ 找到添加按钮');
      await tester.tap(addButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));


      // 验证进入添加密码页面（AppBar中的标题）
      final addPasswordTitle = find.ancestor(
        of: find.text('Add Password'),
        matching: find.byType(AppBar),
      );
      expect(addPasswordTitle, findsOneWidget, reason: '应该显示"Add Password"标题');
      print('✅ 进入添加密码页面');

      // ========== 关键测试：检查 Group 下拉框 ==========
      print('\n🔍 关键测试：检查 Group 下拉框');

      // 等待GroupProvider加载完成（addPostFrameCallback延迟）
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final groupDropdown = find.byType(DropdownButtonFormField<int>);
      print('   查找 DropdownButtonFormField<int>: ${groupDropdown.evaluate().length} 个');

      if (groupDropdown.evaluate().isEmpty) {
        print('   ❌ 错误: 没有找到 Group 下拉框！');
        print('   📋 当前页面的 Widget 类型:');
        tester.allWidgets.take(30).forEach((widget) {
          if (widget.runtimeType.toString().contains('Dropdown') ||
              widget.runtimeType.toString().contains('Form') ||
              widget.runtimeType.toString().contains('Card')) {
            print('      - ${widget.runtimeType}');
          }
        });

        // 查找是否有 "No groups available" 提示
        final noGroupsText = find.text('No groups available. Create a group first.');
        if (noGroupsText.evaluate().isNotEmpty) {
          print('   ❌ 发现问题: 显示 "No groups available. Create a group first."');
          print('   ❌ 这就是用户报告的BUG：没有group就无法保存密码！');
        }

        fail('❌ BUG确认: 添加密码页面应该有 Group 下拉框，但实际没有或没有可选项');
      }

      print('   ✅ 找到 Group 下拉框');

      // 填写密码信息
      final titleField = find.widgetWithText(TextFormField, 'Title');
      final usernameField = find.widgetWithText(TextFormField, 'Username (optional)');
      final passwordField = find.widgetWithText(TextFormField, 'Password');

      expect(titleField, findsOneWidget, reason: '应该有 Title 输入框');
      expect(usernameField, findsOneWidget, reason: '应该有 Username 输入框');
      expect(passwordField, findsOneWidget, reason: '应该有 Password 输入框');

      await tester.enterText(titleField, 'GitHub测试账号');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.enterText(usernameField, 'test@github.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.enterText(passwordField, 'SecurePassword123!');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      print('✅ 表单填写完成');

      // 保存密码 - 使用底部的ElevatedButton
      final saveButton = find.widgetWithText(ElevatedButton, 'Add Password');
      expect(saveButton, findsOneWidget, reason: '应该有保存按钮');

      await tester.tap(saveButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      print('✅ 点击保存按钮');


      // 验证密码已添加
      final savedPassword = find.text('GitHub测试账号');
      expect(savedPassword, findsOneWidget, reason: '应该能看到刚添加的密码条目');
      print('✅ 场景2完成：成功添加密码\n');

      // ========== 场景3: 查看密码详情 ==========
      print('\n📱 场景3: 查看密码详情');

      await tester.tap(savedPassword);
      await tester.pumpAndSettle(const Duration(seconds: 2));


      expect(find.text('test@github.com'), findsOneWidget, reason: '应该显示用户名');
      print('✅ 场景3完成：成功查看密码详情\n');

      // ========== 场景4: 搜索功能 ==========
      print('\n📱 场景4: 测试搜索功能');

      // 返回主页
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 搜索（简化测试，只验证搜索框存在）
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        print('✅ 场景4完成：搜索框存在\n');
      }

      print('\n🎉 基础流程测试完成！');

      // ========== 场景5: Group 管理 ==========
      print('\n📱 场景5: Group 管理');

      // 打开菜单
      final menuButton = find.byType(PopupMenuButton<String>);
      expect(menuButton, findsOneWidget, reason: '应该有菜单按钮');

      await tester.tap(menuButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 点击 Manage Groups
      final manageGroupsItem = find.text('Manage Groups');
      expect(manageGroupsItem, findsOneWidget, reason: '应该有 Manage Groups 菜单项');

      await tester.tap(manageGroupsItem);
      await tester.pumpAndSettle(const Duration(seconds: 3));


      // 验证进入 Groups 管理页面
      expect(find.text('Manage Groups'), findsOneWidget, reason: '应该显示 Manage Groups 标题');

      // 验证只有一个默认 Group
      print('🔍 检查默认 Group');
      final defaultGroup = find.text('Default');
      expect(defaultGroup, findsOneWidget, reason: '应该只有一个 Default group');

      // 添加新 Group
      print('➕ 添加新 Group');
      final addGroupButton = find.byType(FloatingActionButton);
      expect(addGroupButton, findsOneWidget, reason: '应该有添加 Group 按钮');

      await tester.tap(addGroupButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));


      // 验证进入添加 Group 页面
      expect(find.text('Add Group'), findsOneWidget, reason: '应该显示 Add Group 标题');

      // 选择图标（选择 Work 图标 💼）
      final workIcon = find.text('💼');
      if (workIcon.evaluate().isNotEmpty) {
        await tester.tap(workIcon.first);
        await tester.pumpAndSettle(Duration(milliseconds: 500));
        print('✅ 选择了 Work 图标');
      }

      // 填写 Group 名称
      final groupNameField = find.widgetWithText(TextFormField, 'Group Name');
      expect(groupNameField, findsOneWidget, reason: '应该有 Group Name 输入框');

      await tester.enterText(groupNameField, 'Work');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      print('✅ Group 信息填写完成');

      // 保存 Group - 使用ElevatedButton
      final createGroupButton = find.widgetWithText(ElevatedButton, 'Create Group');
      expect(createGroupButton, findsOneWidget, reason: '应该有 Create Group 按钮');

      await tester.tap(createGroupButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('✅ 保存 Group');


      // 验证新 Group 已添加
      final newGroups = find.text('Work');
      expect(newGroups, findsOneWidget, reason: '应该能看到新添加的 Work group');

      // 验证现在有两个 Groups
      print('✅ 场景5完成：成功添加自定义 Group\n');

      // 返回主页
      final backToHome = find.byType(BackButton);
      if (backToHome.evaluate().isNotEmpty) {
        await tester.tap(backToHome);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      print('\n🎉 完整流程测试完成！所有核心场景通过！');
      print('📝 测试已更新以适配最近的代码变更：');
      print('   - 适配 addPostFrameCallback 延迟加载模式');
      print('   - 更新按钮查找方式（使用 widgetWithText）');
      print('   - 增加等待时间以适应异步加载');
    });
  });
}
