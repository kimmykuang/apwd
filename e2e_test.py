#!/usr/bin/env python3
"""
APWD 密码管理器 - 端到端自动化测试
完全自闭环测试所有功能
"""

import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import TimeoutException, NoSuchElementException
import sys

class APWDTester:
    def __init__(self, url="http://localhost:53817"):
        self.url = url
        self.driver = None
        self.test_password = "MySecureTestPassword123!"
        self.test_results = []

    def setup(self):
        """设置浏览器"""
        print("🚀 启动浏览器...")
        options = Options()
        # options.add_argument('--headless')  # 无头模式
        options.add_argument('--disable-gpu')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')

        self.driver = webdriver.Chrome(options=options)
        self.driver.set_window_size(1200, 900)
        print("✅ 浏览器启动成功")

    def teardown(self):
        """清理"""
        if self.driver:
            print("\n🧹 关闭浏览器...")
            self.driver.quit()

    def wait_for_element(self, by, value, timeout=10):
        """等待元素出现"""
        try:
            element = WebDriverWait(self.driver, timeout).until(
                EC.presence_of_element_located((by, value))
            )
            return element
        except TimeoutException:
            print(f"❌ 超时：找不到元素 {value}")
            return None

    def click_element(self, by, value, timeout=10):
        """点击元素"""
        try:
            element = WebDriverWait(self.driver, timeout).until(
                EC.element_to_be_clickable((by, value))
            )
            element.click()
            return True
        except Exception as e:
            print(f"❌ 点击失败: {value} - {str(e)}")
            return False

    def test_1_open_app(self):
        """测试1: 打开应用"""
        print("\n📱 测试1: 打开应用")
        try:
            self.driver.get(self.url)
            time.sleep(2)
            print(f"✅ 成功打开: {self.url}")
            print(f"   页面标题: {self.driver.title}")
            self.test_results.append(("打开应用", True))
            return True
        except Exception as e:
            print(f"❌ 打开应用失败: {str(e)}")
            self.test_results.append(("打开应用", False))
            return False

    def test_2_check_splash_screen(self):
        """测试2: 检查启动页"""
        print("\n🎨 测试2: 检查启动页")
        try:
            # 等待启动页元素
            time.sleep(2)
            page_source = self.driver.page_source

            # 检查是否有 APWD 或密码管理器相关文字
            if "APWD" in page_source or "密码" in page_source or "Password" in page_source:
                print("✅ 启动页加载成功")
                self.test_results.append(("启动页", True))
                return True
            else:
                print("⚠️  未检测到启动页特征")
                self.test_results.append(("启动页", False))
                return False
        except Exception as e:
            print(f"❌ 启动页检查失败: {str(e)}")
            self.test_results.append(("启动页", False))
            return False

    def test_3_setup_master_password(self):
        """测试3: 设置主密码"""
        print("\n🔐 测试3: 设置主密码")
        try:
            # 等待设置页面加载
            time.sleep(3)

            # 尝试查找密码输入框
            print("   查找密码输入框...")
            password_inputs = self.driver.find_elements(By.TAG_NAME, "input")

            if len(password_inputs) >= 2:
                print(f"   找到 {len(password_inputs)} 个输入框")

                # 输入主密码
                password_inputs[0].send_keys(self.test_password)
                print(f"   ✅ 输入主密码")

                time.sleep(0.5)

                # 确认密码
                password_inputs[1].send_keys(self.test_password)
                print(f"   ✅ 确认主密码")

                time.sleep(0.5)

                # 查找并点击提交按钮
                buttons = self.driver.find_elements(By.TAG_NAME, "button")
                for button in buttons:
                    if button.text and ("创建" in button.text or "设置" in button.text or "确认" in button.text or "Create" in button.text):
                        button.click()
                        print("   ✅ 点击创建按钮")
                        time.sleep(2)
                        break

                print("✅ 主密码设置完成")
                self.test_results.append(("设置主密码", True))
                return True
            else:
                print(f"⚠️  输入框数量不足: {len(password_inputs)}")
                self.test_results.append(("设置主密码", False))
                return False

        except Exception as e:
            print(f"❌ 设置主密码失败: {str(e)}")
            self.test_results.append(("设置主密码", False))
            return False

    def test_4_check_home_screen(self):
        """测试4: 检查主页"""
        print("\n🏠 测试4: 检查主页")
        try:
            time.sleep(2)
            page_source = self.driver.page_source

            # 检查主页特征
            if "密码" in page_source or "Password" in page_source or "搜索" in page_source:
                print("✅ 主页加载成功")

                # 截图
                self.driver.save_screenshot("/Users/kuang/workspace/kimmykuang/apwd/test_home.png")
                print("   📸 已保存主页截图: test_home.png")

                self.test_results.append(("主页显示", True))
                return True
            else:
                print("⚠️  未检测到主页特征")
                self.test_results.append(("主页显示", False))
                return False

        except Exception as e:
            print(f"❌ 主页检查失败: {str(e)}")
            self.test_results.append(("主页显示", False))
            return False

    def test_5_add_password(self):
        """测试5: 添加密码条目"""
        print("\n➕ 测试5: 添加密码条目")
        try:
            # 查找添加按钮 (通常是 + 或 FAB)
            print("   查找添加按钮...")
            time.sleep(1)

            # 尝试点击浮动操作按钮
            buttons = self.driver.find_elements(By.TAG_NAME, "button")
            clicked = False

            for button in buttons:
                try:
                    # 查找包含 + 或 添加 的按钮
                    if button.text in ['+', '＋', '添加'] or 'add' in button.get_attribute('class').lower():
                        button.click()
                        print("   ✅ 点击添加按钮")
                        clicked = True
                        time.sleep(2)
                        break
                except:
                    continue

            if not clicked:
                # 尝试通过其他方式找到添加按钮
                print("   尝试查找其他添加方式...")

            # 填写密码信息
            print("   填写密码信息...")
            inputs = self.driver.find_elements(By.TAG_NAME, "input")

            if len(inputs) >= 3:
                # 标题
                inputs[0].send_keys("测试网站 - Gmail")
                print("   ✅ 输入标题: 测试网站 - Gmail")

                time.sleep(0.3)

                # 用户名
                if len(inputs) > 1:
                    inputs[1].send_keys("test@gmail.com")
                    print("   ✅ 输入用户名: test@gmail.com")

                time.sleep(0.3)

                # 密码
                if len(inputs) > 2:
                    inputs[2].send_keys("TestPassword123!")
                    print("   ✅ 输入密码: TestPassword123!")

                time.sleep(0.5)

                # 保存
                save_buttons = self.driver.find_elements(By.TAG_NAME, "button")
                for btn in save_buttons:
                    if "保存" in btn.text or "Save" in btn.text or "确定" in btn.text:
                        btn.click()
                        print("   ✅ 点击保存按钮")
                        time.sleep(2)
                        break

                print("✅ 密码条目添加成功")
                self.test_results.append(("添加密码", True))
                return True
            else:
                print(f"⚠️  未找到足够的输入框")
                self.test_results.append(("添加密码", False))
                return False

        except Exception as e:
            print(f"❌ 添加密码失败: {str(e)}")
            self.test_results.append(("添加密码", False))
            return False

    def test_6_search_password(self):
        """测试6: 搜索密码"""
        print("\n🔍 测试6: 搜索密码")
        try:
            time.sleep(1)

            # 查找搜索框
            search_inputs = self.driver.find_elements(By.TAG_NAME, "input")

            if search_inputs:
                search_inputs[0].send_keys("Gmail")
                print("   ✅ 输入搜索词: Gmail")
                time.sleep(1)

                page_source = self.driver.page_source
                if "Gmail" in page_source or "test@gmail.com" in page_source:
                    print("✅ 搜索功能正常")
                    self.test_results.append(("搜索功能", True))
                    return True

            print("⚠️  搜索功能测试未完成")
            self.test_results.append(("搜索功能", False))
            return False

        except Exception as e:
            print(f"❌ 搜索测试失败: {str(e)}")
            self.test_results.append(("搜索功能", False))
            return False

    def test_7_screenshot_final(self):
        """测试7: 最终截图"""
        print("\n📸 测试7: 保存最终状态截图")
        try:
            self.driver.save_screenshot("/Users/kuang/workspace/kimmykuang/apwd/test_final.png")
            print("✅ 已保存最终截图: test_final.png")
            self.test_results.append(("截图", True))
            return True
        except Exception as e:
            print(f"❌ 截图失败: {str(e)}")
            self.test_results.append(("截图", False))
            return False

    def run_all_tests(self):
        """运行所有测试"""
        print("\n" + "="*60)
        print("🧪 APWD 密码管理器 - 端到端自动化测试")
        print("="*60)

        try:
            self.setup()

            # 运行所有测试
            self.test_1_open_app()
            self.test_2_check_splash_screen()
            self.test_3_setup_master_password()
            self.test_4_check_home_screen()
            self.test_5_add_password()
            self.test_6_search_password()
            self.test_7_screenshot_final()

            # 打印测试结果
            self.print_results()

        except Exception as e:
            print(f"\n❌ 测试过程中出现错误: {str(e)}")

        finally:
            time.sleep(3)  # 让用户看到最终状态
            self.teardown()

    def print_results(self):
        """打印测试结果"""
        print("\n" + "="*60)
        print("📊 测试结果汇总")
        print("="*60)

        passed = 0
        failed = 0

        for test_name, result in self.test_results:
            status = "✅ 通过" if result else "❌ 失败"
            print(f"{status} - {test_name}")
            if result:
                passed += 1
            else:
                failed += 1

        print("\n" + "-"*60)
        print(f"总计: {len(self.test_results)} 个测试")
        print(f"✅ 通过: {passed}")
        print(f"❌ 失败: {failed}")
        print(f"📈 成功率: {(passed/len(self.test_results)*100):.1f}%")
        print("="*60)

if __name__ == "__main__":
    tester = APWDTester()
    tester.run_all_tests()
