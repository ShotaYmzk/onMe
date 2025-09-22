//
//  CurrencyConverterUseCase.swift
//  onMe
//
//  Created by AI Assistant on 2025/09/22.
//

import Foundation
import Combine

protocol CurrencyConverterUseCaseProtocol {
    func convertExpenseToPreferredCurrency(_ expense: ExpenseEntity, preferredCurrency: String) -> AnyPublisher<ExpenseEntity, Error>
    func convertAmountToPreferredCurrency(_ amount: Decimal, from currency: String, to preferredCurrency: String) -> AnyPublisher<Decimal, Error>
    func getAvailableExchangeRates() -> AnyPublisher<[String: Double], Error>
    func isConversionNeeded(from: String, to: String) -> Bool
}

class CurrencyConverterUseCase: CurrencyConverterUseCaseProtocol {
    private let exchangeRateService: ExchangeRateServiceProtocol
    
    init(exchangeRateService: ExchangeRateServiceProtocol = ExchangeRateService()) {
        self.exchangeRateService = exchangeRateService
    }
    
    func convertExpenseToPreferredCurrency(_ expense: ExpenseEntity, preferredCurrency: String) -> AnyPublisher<ExpenseEntity, Error> {
        if expense.currency == preferredCurrency {
            return Just(expense)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return convertAmountToPreferredCurrency(expense.amount, from: expense.currency, to: preferredCurrency)
            .map { convertedAmount in
                var convertedExpense = expense
                convertedExpense.amount = convertedAmount
                convertedExpense.currency = preferredCurrency
                return convertedExpense
            }
            .eraseToAnyPublisher()
    }
    
    func convertAmountToPreferredCurrency(_ amount: Decimal, from currency: String, to preferredCurrency: String) -> AnyPublisher<Decimal, Error> {
        return exchangeRateService.convertAmount(amount, from: currency, to: preferredCurrency)
    }
    
    func getAvailableExchangeRates() -> AnyPublisher<[String: Double], Error> {
        return exchangeRateService.getExchangeRates()
            .map { response in
                return response.rates
            }
            .eraseToAnyPublisher()
    }
    
    func isConversionNeeded(from: String, to: String) -> Bool {
        return from != to
    }
    
    // 複数の支出を一括変換
    func convertExpensesToPreferredCurrency(_ expenses: [ExpenseEntity], preferredCurrency: String) -> AnyPublisher<[ExpenseEntity], Error> {
        let publishers = expenses.map { expense in
            convertExpenseToPreferredCurrency(expense, preferredCurrency: preferredCurrency)
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
    
    // 通貨変換レートを取得（表示用）
    func getExchangeRateForDisplay(from: String, to: String) -> AnyPublisher<String, Error> {
        if from == to {
            return Just("1.00")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return exchangeRateService.getExchangeRates()
            .tryMap { response in
                guard let fromRate = response.rates[from],
                      let toRate = response.rates[to] else {
                    throw ExchangeRateError.currencyNotSupported
                }
                
                let rate = toRate / fromRate
                return String(format: "%.4f", rate)
            }
            .eraseToAnyPublisher()
    }
    
    // 通貨変換の最終更新時刻を取得
    func getLastUpdateTime() -> AnyPublisher<String, Error> {
        return exchangeRateService.getExchangeRates()
            .map { response in
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.locale = Locale(identifier: "ja_JP")
                
                if let date = DateFormatter.iso8601.date(from: response.date) {
                    return formatter.string(from: date)
                } else {
                    return formatter.string(from: Date())
                }
            }
            .eraseToAnyPublisher()
    }
}

// 通貨変換結果を格納する構造体
struct ConvertedAmount {
    let originalAmount: Decimal
    let originalCurrency: String
    let convertedAmount: Decimal
    let convertedCurrency: String
    let exchangeRate: Double
    let lastUpdated: Date
}

extension ConvertedAmount {
    func formattedOriginalAmount() -> String {
        return CurrencyFormatter.shared.formatAmount(originalAmount, currency: originalCurrency)
    }
    
    func formattedConvertedAmount() -> String {
        return CurrencyFormatter.shared.formatAmount(convertedAmount, currency: convertedCurrency)
    }
}

// 通貨フォーマッター
class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    
    private init() {}
    
    func formatAmount(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = localeForCurrency(currency)
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
    
    private func localeForCurrency(_ currency: String) -> Locale {
        switch currency {
        case "JPY":
            return Locale(identifier: "ja_JP")
        case "USD":
            return Locale(identifier: "en_US")
        case "EUR":
            return Locale(identifier: "de_DE")
        case "GBP":
            return Locale(identifier: "en_GB")
        case "KRW":
            return Locale(identifier: "ko_KR")
        case "CNY":
            return Locale(identifier: "zh_CN")
        case "THB":
            return Locale(identifier: "th_TH")
        case "SGD":
            return Locale(identifier: "en_SG")
        case "HKD":
            return Locale(identifier: "zh_HK")
        case "AUD":
            return Locale(identifier: "en_AU")
        default:
            return Locale.current
        }
    }
}
