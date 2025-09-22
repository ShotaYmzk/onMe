//
//  TravelSettleUITests.swift
//  TravelSettleUITests
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import XCTest

final class TravelSettleUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - アプリ起動テスト
    func testAppLaunch() throws {
        XCTAssertTrue(app.tabBars.firstMatch.exists)
        XCTAssertTrue(app.tabBars.buttons["グループ"].exists)
        XCTAssertTrue(app.tabBars.buttons["支出"].exists)
        XCTAssertTrue(app.tabBars.buttons["清算"].exists)
        XCTAssertTrue(app.tabBars.buttons["設定"].exists)
    }
    
    // MARK: - グループ作成テスト
    func testGroupCreation() throws {
        // グループタブに移動
        app.tabBars.buttons["グループ"].tap()
        
        // プラスボタンをタップ
        app.navigationBars.buttons["plus"].tap()
        
        // グループ作成画面が表示されることを確認
        XCTAssertTrue(app.navigationBars["新しいグループ"].exists)
        
        // グループ名を入力
        let groupNameField = app.textFields["グループ名"]
        XCTAssertTrue(groupNameField.exists)
        groupNameField.tap()
        groupNameField.typeText("テスト旅行")
        
        // 通貨選択
        app.pickers.firstMatch.pickerWheels.firstMatch.adjust(toPickerWheelValue: "USD")
        
        // 作成ボタンをタップ
        app.navigationBars.buttons["作成"].tap()
        
        // グループリストに戻り、作成されたグループが表示されることを確認
        XCTAssertTrue(app.cells.staticTexts["テスト旅行"].exists)
    }
    
    // MARK: - 支出登録テスト
    func testExpenseCreation() throws {
        // まずグループを作成
        createTestGroup()
        
        // 支出タブに移動
        app.tabBars.buttons["支出"].tap()
        
        // プラスボタンをタップ
        app.navigationBars.buttons["plus"].tap()
        
        // 支出登録画面が表示されることを確認
        XCTAssertTrue(app.navigationBars["支出を登録"].exists)
        
        // 支出の説明を入力
        let descriptionField = app.textFields["支出の説明"]
        descriptionField.tap()
        descriptionField.typeText("ランチ")
        
        // 金額を入力
        let amountField = app.textFields["金額"]
        amountField.tap()
        amountField.typeText("2000")
        
        // カテゴリを選択
        app.pickers.firstMatch.pickerWheels.firstMatch.adjust(toPickerWheelValue: "食事")
        
        // 保存ボタンをタップ
        app.navigationBars.buttons["保存"].tap()
        
        // 支出リストに戻り、作成された支出が表示されることを確認
        XCTAssertTrue(app.cells.staticTexts["ランチ"].exists)
    }
    
    // MARK: - 清算画面テスト
    func testSettlementView() throws {
        // まずグループを作成
        createTestGroup()
        
        // 清算タブに移動
        app.tabBars.buttons["清算"].tap()
        
        // 清算画面が表示されることを確認
        XCTAssertTrue(app.navigationBars.firstMatch.exists)
        
        // 残高概要セクションが存在することを確認
        XCTAssertTrue(app.staticTexts["残高概要"].exists)
        
        // 返済提案セクションが存在することを確認
        XCTAssertTrue(app.staticTexts["返済提案"].exists)
    }
    
    // MARK: - 設定画面テスト
    func testSettingsView() throws {
        // 設定タブに移動
        app.tabBars.buttons["設定"].tap()
        
        // 設定画面が表示されることを確認
        XCTAssertTrue(app.navigationBars["設定"].exists)
        
        // 各設定項目が存在することを確認
        XCTAssertTrue(app.staticTexts["一般"].exists)
        XCTAssertTrue(app.staticTexts["表示"].exists)
        XCTAssertTrue(app.staticTexts["データ"].exists)
        XCTAssertTrue(app.staticTexts["アプリについて"].exists)
        
        // ダークモードトグルをテスト
        let darkModeToggle = app.switches.firstMatch
        if darkModeToggle.exists {
            let initialValue = darkModeToggle.value as? String
            darkModeToggle.tap()
            XCTAssertNotEqual(darkModeToggle.value as? String, initialValue)
        }
    }
    
    // MARK: - アクセシビリティテスト
    func testAccessibility() throws {
        // VoiceOverが有効な場合のテスト
        app.tabBars.buttons["グループ"].tap()
        
        // アクセシビリティラベルが設定されていることを確認
        let groupTab = app.tabBars.buttons["グループ"]
        XCTAssertTrue(groupTab.isHittable)
        
        // ナビゲーション要素のアクセシビリティ
        if app.navigationBars.buttons["plus"].exists {
            XCTAssertTrue(app.navigationBars.buttons["plus"].isHittable)
        }
    }
    
    // MARK: - パフォーマンステスト
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testScrollPerformance() throws {
        // 大量のデータがある場合のスクロールパフォーマンステスト
        app.tabBars.buttons["グループ"].tap()
        
        let table = app.tables.firstMatch
        if table.exists {
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
                table.swipeUp(velocity: .fast)
                table.swipeDown(velocity: .fast)
            }
        }
    }
    
    // MARK: - エラーハンドリングテスト
    func testErrorHandling() throws {
        // グループ作成時の無効な入力テスト
        app.tabBars.buttons["グループ"].tap()
        app.navigationBars.buttons["plus"].tap()
        
        // 空のグループ名で作成を試行
        app.navigationBars.buttons["作成"].tap()
        
        // 作成ボタンが無効化されていることを確認
        XCTAssertFalse(app.navigationBars.buttons["作成"].isEnabled)
    }
    
    // MARK: - 画面遷移テスト
    func testNavigationFlow() throws {
        // グループ → 支出 → 清算 → 設定の順に遷移
        let tabs = ["グループ", "支出", "清算", "設定"]
        
        for tab in tabs {
            app.tabBars.buttons[tab].tap()
            XCTAssertTrue(app.navigationBars.firstMatch.exists)
            
            // 少し待機してアニメーションを完了
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    // MARK: - ヘルパーメソッド
    private func createTestGroup() {
        app.tabBars.buttons["グループ"].tap()
        app.navigationBars.buttons["plus"].tap()
        
        let groupNameField = app.textFields["グループ名"]
        groupNameField.tap()
        groupNameField.typeText("UIテストグループ")
        
        app.navigationBars.buttons["作成"].tap()
        
        // グループが作成されるまで待機
        let groupCell = app.cells.staticTexts["UIテストグループ"]
        XCTAssertTrue(groupCell.waitForExistence(timeout: 5.0))
        
        // グループを選択
        groupCell.tap()
    }
    
    private func addTestMember(name: String) {
        // メンバー追加機能が実装されている場合のヘルパー
        // 実際の実装に応じて調整が必要
    }
    
    private func deleteTestData() {
        // テストデータのクリーンアップ
        // 必要に応じて実装
    }
}
