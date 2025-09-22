//
//  ExchangeRateService.swift
//  onMe
//
//  Created by AI Assistant on 2025/09/22.
//

import Foundation
import Combine

protocol ExchangeRateServiceProtocol {
    func getExchangeRates() -> AnyPublisher<ExchangeRateResponse, Error>
    func convertAmount(_ amount: Decimal, from fromCurrency: String, to toCurrency: String) -> AnyPublisher<Decimal, Error>
}

struct ExchangeRateResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}

class ExchangeRateService: ExchangeRateServiceProtocol {
    private let session = URLSession.shared
    private let baseURL = "https://api.exchangerate-api.com/v4/latest"
    private var cachedRates: ExchangeRateResponse?
    private var lastUpdated: Date?
    private let cacheExpiration: TimeInterval = 3600 // 1時間
    
    func getExchangeRates() -> AnyPublisher<ExchangeRateResponse, Error> {
        // キャッシュが有効な場合は返す
        if let cachedRates = cachedRates,
           let lastUpdated = lastUpdated,
           Date().timeIntervalSince(lastUpdated) < cacheExpiration {
            return Just(cachedRates)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: "\(baseURL)/USD") else {
            return Fail(error: ExchangeRateError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
            .handleEvents(receiveOutput: { [weak self] response in
                self?.cachedRates = response
                self?.lastUpdated = Date()
            })
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
                    throw ExchangeRateError.currencyNotSupported
                }
                
                // USDベースなので、まずUSDに変換してから目標通貨に変換
                let usdAmount = amount / Decimal(fromRate)
                let convertedAmount = usdAmount * Decimal(toRate)
                
                return convertedAmount
            }
            .eraseToAnyPublisher()
    }
}

// フォールバック用のモックサービス（オフライン時やAPI制限時用）
class MockExchangeRateService: ExchangeRateServiceProtocol {
    private let staticRates: [String: Double] = [
        // Major currencies
        "JPY": 149.50,
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.79,
        
        // Asian currencies
        "KRW": 1340.0,
        "CNY": 7.31,
        "THB": 36.80,
        "SGD": 1.35,
        "HKD": 7.83,
        "TWD": 31.20,
        "MYR": 4.68,
        "PHP": 55.80,
        "IDR": 15420.0,
        "VND": 24150.0,
        "INR": 83.25,
        
        // Oceania
        "AUD": 1.53,
        "NZD": 1.64,
        
        // Americas
        "CAD": 1.36,
        "BRL": 5.02,
        "MXN": 17.85,
        "ARS": 350.0,
        "CLP": 920.0,
        "COP": 4050.0,
        "PEN": 3.75,
        
        // Europe
        "CHF": 0.88,
        "NOK": 10.85,
        "SEK": 10.95,
        "DKK": 6.87,
        "PLN": 4.02,
        "CZK": 22.50,
        "HUF": 360.0,
        "RON": 4.55,
        "BGN": 1.80,
        "HRK": 6.93,
        "RSD": 108.0,
        "RUB": 92.50,
        "TRY": 28.50,
        
        // Middle East & Africa
        "AED": 3.67,
        "SAR": 3.75,
        "QAR": 3.64,
        "KWD": 0.31,
        "BHD": 0.38,
        "OMR": 0.38,
        "JOD": 0.71,
        "LBP": 15000.0,
        "ILS": 3.72,
        "EGP": 30.85,
        "ZAR": 18.90,
        "NGN": 775.0,
        "KES": 147.0,
        "GHS": 12.10,
        "MAD": 10.15,
        "TND": 3.10,
        "DZD": 135.0,
        
        // Others
        "ISK": 137.0,
        "ALL": 94.50,
        "MKD": 56.80,
        "BAM": 1.80,
        "MDL": 17.80,
        "GEL": 2.68,
        "AMD": 386.0,
        "AZN": 1.70,
        "KZT": 450.0,
        "UZS": 12250.0,
        "KGS": 89.50,
        "TJS": 10.95,
        "TMT": 3.50,
        "MNT": 3450.0,
        "NPR": 133.0,
        "PKR": 278.0,
        "BDT": 110.0,
        "LKR": 325.0,
        "MVR": 15.40,
        "AFN": 70.50,
        "IRR": 42000.0,
        "IQD": 1310.0,
        "SYP": 2512.0,
        "YER": 250.0
    ]
    
    func getExchangeRates() -> AnyPublisher<ExchangeRateResponse, Error> {
        let response = ExchangeRateResponse(
            base: "USD",
            date: DateFormatter.iso8601.string(from: Date()),
            rates: staticRates
        )
        
        return Just(response)
            .delay(for: .milliseconds(500), scheduler: RunLoop.main) // リアルなAPI感を演出
            .setFailureType(to: Error.self)
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
                    throw ExchangeRateError.currencyNotSupported
                }
                
                let usdAmount = amount / Decimal(fromRate)
                let convertedAmount = usdAmount * Decimal(toRate)
                
                return convertedAmount
            }
            .eraseToAnyPublisher()
    }
}

enum ExchangeRateError: Error, LocalizedError {
    case invalidURL
    case networkError
    case currencyNotSupported
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .currencyNotSupported:
            return "サポートされていない通貨です"
        case .decodingError:
            return "データの解析に失敗しました"
        }
    }
}

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
