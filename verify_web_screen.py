#!/usr/bin/env python3
"""
Quick verification that the Web unsupported platform screen is displayed
"""

import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def verify_web_platform_screen():
    print("🔍 Verifying Web Platform Screen...")

    options = Options()
    # options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')

    driver = None
    try:
        driver = webdriver.Chrome(options=options)
        driver.set_window_size(1200, 900)

        print("📱 Opening http://localhost:53817...")
        driver.get("http://localhost:53817")

        # Wait for page to load
        time.sleep(3)

        page_source = driver.page_source

        # Check for expected content
        checks = [
            ("Web Platform Not Supported", "title message"),
            ("SQLCipher", "technical reason"),
            ("Supported Platforms", "platform list"),
            ("iOS", "iOS platform"),
            ("Android", "Android platform"),
            ("macOS", "macOS platform"),
        ]

        print("\n✅ Content Verification:")
        all_passed = True
        for text, description in checks:
            if text in page_source:
                print(f"  ✅ Found: {description}")
            else:
                print(f"  ❌ Missing: {description}")
                all_passed = False

        # Take screenshot
        screenshot_path = "/Users/kuang/workspace/kimmykuang/apwd/web_unsupported_screen.png"
        driver.save_screenshot(screenshot_path)
        print(f"\n📸 Screenshot saved: web_unsupported_screen.png")

        if all_passed:
            print("\n🎉 SUCCESS: Unsupported platform screen is displaying correctly!")
            return True
        else:
            print("\n⚠️  WARNING: Some expected content is missing")
            return False

    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        return False
    finally:
        if driver:
            time.sleep(2)  # Let user see the result
            driver.quit()

if __name__ == "__main__":
    print("\n" + "="*60)
    print("APWD - Web Platform Screen Verification")
    print("="*60)

    success = verify_web_platform_screen()

    print("\n" + "="*60)
    if success:
        print("✅ Verification PASSED")
    else:
        print("❌ Verification FAILED")
    print("="*60)
