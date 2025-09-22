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
