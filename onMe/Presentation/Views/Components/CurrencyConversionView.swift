//
//  CurrencyConversionView.swift
//  onMe
//
//  Created by AI Assistant on 2025/09/22.
//

import SwiftUI
import Combine

struct CurrencyConversionView: View {
    let originalAmount: Decimal
    let originalCurrency: String
    let preferredCurrency: String
    
    @EnvironmentObject private var appState: AppState
    @State private var convertedAmount: Decimal = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 元の金額表示
            HStack {
                Text(formatAmount(originalAmount, currency: originalCurrency))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if originalCurrency != preferredCurrency {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 変換後の金額表示（異なる通貨の場合のみ）
            if originalCurrency != preferredCurrency {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("変換中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let errorMessage = errorMessage {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text(formatAmount(convertedAmount, currency: preferredCurrency))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let lastUpdate = appState.lastExchangeRateUpdate {
                            Text("更新: \(formatUpdateTime(lastUpdate))")
                                .font(.caption2)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                }
            }
        }
        .onAppear {
            convertCurrency()
        }
        .onChange(of: appState.exchangeRates) {
            convertCurrency()
        }
    }
    
    private func convertCurrency() {
        guard originalCurrency != preferredCurrency else {
            convertedAmount = originalAmount
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        appState.convertAmount(originalAmount, from: originalCurrency, to: preferredCurrency)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { amount in
                    convertedAmount = amount
                }
            )
            .store(in: &cancellables)
    }
    
    private func formatUpdateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// Currency formatting function
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

// 簡単な表示用コンポーネント
struct SimpleCurrencyView: View {
    let amount: Decimal
    let currency: String
    
    var body: some View {
        Text(formatAmount(amount, currency: currency))
            .font(.headline)
            .foregroundColor(.primary)
    }
}

// 為替レート表示用コンポーネント
struct ExchangeRateDisplayView: View {
    let fromCurrency: String
    let toCurrency: String
    
    @EnvironmentObject private var appState: AppState
    @State private var exchangeRate: String = "---"
    @State private var isLoading = false
    
    private let exchangeRateService = BasicExchangeRateService()
    
    var body: some View {
        HStack {
            Text("1 \(fromCurrency) = ")
                .foregroundColor(.secondary)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
            } else {
                Text("\(exchangeRate) \(toCurrency)")
                    .fontWeight(.medium)
            }
        }
        .font(.caption)
        .onAppear {
            loadExchangeRate()
        }
        .onChange(of: appState.exchangeRates) {
            loadExchangeRate()
        }
    }
    
    private func loadExchangeRate() {
        guard fromCurrency != toCurrency else {
            exchangeRate = "1.0000"
            return
        }
        
        isLoading = true
        
        exchangeRateService.getExchangeRates()
            .tryMap { response in
                guard let fromRate = response.rates[fromCurrency],
                      let toRate = response.rates[toCurrency] else {
                    throw NSError(domain: "CurrencyError", code: 1, userInfo: [NSLocalizedDescriptionKey: "サポートされていない通貨です"])
                }
                
                let rate = toRate / fromRate
                return String(format: "%.4f", rate)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(_) = completion {
                        exchangeRate = "---"
                    }
                },
                receiveValue: { rate in
                    exchangeRate = rate
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct CurrencyConversionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CurrencyConversionView(
                originalAmount: 1000,
                originalCurrency: "USD",
                preferredCurrency: "JPY"
            )
            .environmentObject(AppState())
            
            SimpleCurrencyView(amount: 1500, currency: "EUR")
            
            ExchangeRateDisplayView(fromCurrency: "USD", toCurrency: "JPY")
                .environmentObject(AppState())
        }
        .padding()
    }
}
