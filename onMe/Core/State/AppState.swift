//
//  AppState.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import Combine
import Foundation

// Simple exchange rate response structure
struct SimpleExchangeRateResponse {
    let rates: [String: Double]
    let lastUpdated: Date
}

// Basic exchange rate service
class BasicExchangeRateService {
    private let session = URLSession.shared
    private let baseURL = "https://api.exchangerate-api.com/v4/latest"
    private var cachedRates: SimpleExchangeRateResponse?
    private var lastUpdated: Date?
    private let cacheExpiration: TimeInterval = 3600 // 1時間
    
    func getExchangeRates() -> AnyPublisher<SimpleExchangeRateResponse, Error> {
        // キャッシュが有効な場合は返す
        if let cachedRates = cachedRates,
           let lastUpdated = lastUpdated,
           Date().timeIntervalSince(lastUpdated) < cacheExpiration {
            return Just(cachedRates)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // フォールバック用の静的レート
        let fallbackRates: [String: Double] = [
            "JPY": 149.50,
            "USD": 1.0,
            "EUR": 0.92,
            "GBP": 0.79,
            "KRW": 1340.0,
            "CNY": 7.31,
            "THB": 36.80,
            "SGD": 1.35,
            "HKD": 7.83,
            "AUD": 1.53
        ]
        
        guard let url = URL(string: "\(baseURL)/USD") else {
            let fallback = SimpleExchangeRateResponse(rates: fallbackRates, lastUpdated: Date())
            return Just(fallback)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: APIResponse.self, decoder: JSONDecoder())
            .map { response in
                let result = SimpleExchangeRateResponse(
                    rates: response.rates,
                    lastUpdated: Date()
                )
                self.cachedRates = result
                self.lastUpdated = Date()
                return result
            }
            .catch { _ in
                // エラー時はフォールバックレートを使用
                let fallback = SimpleExchangeRateResponse(rates: fallbackRates, lastUpdated: Date())
                return Just(fallback)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func convertAmount(_ amount: Decimal, from fromCurrency: String, to toCurrency: String) -> AnyPublisher<Decimal, Error> {
        if fromCurrency == toCurrency {
            return Just(amount)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return getExchangeRates()
            .tryMap { response in
                guard let fromRate = response.rates[fromCurrency],
                      let toRate = response.rates[toCurrency] else {
                    throw NSError(domain: "CurrencyError", code: 1, userInfo: [NSLocalizedDescriptionKey: "サポートされていない通貨です"])
                }
                
                // USDベースなので、まずUSDに変換してから目標通貨に変換
                let usdAmount = amount / Decimal(fromRate)
                let convertedAmount = usdAmount * Decimal(toRate)
                
                return convertedAmount
            }
            .eraseToAnyPublisher()
    }
    
    private struct APIResponse: Codable {
        let base: String
        let rates: [String: Double]
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: Tab = .groups
    @Published var selectedGroup: TravelGroup?
    @Published var isShowingExpenseForm = false
    @Published var isShowingSettlementView = false
    @Published var currentLocale: Locale = .current
    @Published var preferredCurrency: String = "JPY"
    @Published var exchangeRates: [String: Double] = [:]
    @Published var lastExchangeRateUpdate: Date?
    @Published var isLoadingExchangeRates = false
    
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
    
    private let exchangeRateService = BasicExchangeRateService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // UserDefaultsから設定を読み込み
        self.isDarkModeEnabled = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        
        // 通貨設定の読み込み
        if let savedCurrency = UserDefaults.standard.string(forKey: "preferredCurrency") {
            self.preferredCurrency = savedCurrency
        }
        
        // 為替レート初期読み込み
        loadExchangeRates()
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
        // 通貨変更時に為替レートを更新
        loadExchangeRates()
    }
    
    func loadExchangeRates() {
        isLoadingExchangeRates = true
        
        exchangeRateService.getExchangeRates()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    self?.isLoadingExchangeRates = false
                    if case .failure(let error) = completion {
                        print("為替レート取得エラー: \(error)")
                    }
                },
                receiveValue: { [weak self] (response: SimpleExchangeRateResponse) in
                    self?.exchangeRates = response.rates
                    self?.lastExchangeRateUpdate = response.lastUpdated
                }
            )
            .store(in: &cancellables)
    }
    
    func convertAmount(_ amount: Decimal, from fromCurrency: String, to toCurrency: String) -> AnyPublisher<Decimal, Error> {
        return exchangeRateService.convertAmount(amount, from: fromCurrency, to: toCurrency)
    }
}
