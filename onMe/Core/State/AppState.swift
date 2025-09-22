//
//  AppState.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Tab = .groups
    @Published var selectedGroup: TravelGroup?
    @Published var isShowingExpenseForm = false
    @Published var isShowingSettlementView = false
    @Published var currentLocale: Locale = .current
    @Published var preferredCurrency: String = "JPY"
    
    // ユーザー設定
    @Published var isDarkModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDarkModeEnabled, forKey: "isDarkModeEnabled")
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    enum Tab {
        case groups
        case expenses
        case settlements
        case settings
    }
    
    init() {
        // UserDefaultsから設定を読み込み
        self.isDarkModeEnabled = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        
        // 通貨設定の読み込み
        if let savedCurrency = UserDefaults.standard.string(forKey: "preferredCurrency") {
            self.preferredCurrency = savedCurrency
        }
    }
    
    func selectGroup(_ group: TravelGroup?) {
        selectedGroup = group
    }
    
    func showExpenseForm() {
        isShowingExpenseForm = true
    }
    
    func hideExpenseForm() {
        isShowingExpenseForm = false
    }
    
    func showSettlementView() {
        isShowingSettlementView = true
    }
    
    func hideSettlementView() {
        isShowingSettlementView = false
    }
    
    func updateCurrency(_ currency: String) {
        preferredCurrency = currency
        UserDefaults.standard.set(currency, forKey: "preferredCurrency")
    }
}
