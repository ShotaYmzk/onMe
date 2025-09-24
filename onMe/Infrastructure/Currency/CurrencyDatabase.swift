//
//  CurrencyDatabase.swift
//  onMe
//
//  Created by AI Assistant on 2025/09/22.
//

import Foundation

struct CurrencyInfo {
    let code: String
    let name: String
    let symbol: String
    let region: String
    let decimalPlaces: Int
    let isPopular: Bool
    
    init(code: String, name: String, symbol: String, region: String, decimalPlaces: Int = 2, isPopular: Bool = false) {
        self.code = code
        self.name = name
        self.symbol = symbol
        self.region = region
        self.decimalPlaces = decimalPlaces
        self.isPopular = isPopular
    }
}

class CurrencyDatabase {
    static let shared = CurrencyDatabase()
    
    private let currencies: [String: CurrencyInfo] = [
        // Major currencies (Popular)
        "JPY": CurrencyInfo(code: "JPY", name: "Japanese Yen", symbol: "¥", region: "Japan", decimalPlaces: 0, isPopular: true),
        "USD": CurrencyInfo(code: "USD", name: "US Dollar", symbol: "$", region: "United States", isPopular: true),
        "EUR": CurrencyInfo(code: "EUR", name: "Euro", symbol: "€", region: "European Union", isPopular: true),
        "GBP": CurrencyInfo(code: "GBP", name: "British Pound", symbol: "£", region: "United Kingdom", isPopular: true),
        
        // Asian currencies
        "KRW": CurrencyInfo(code: "KRW", name: "South Korean Won", symbol: "₩", region: "South Korea", decimalPlaces: 0, isPopular: true),
        "CNY": CurrencyInfo(code: "CNY", name: "Chinese Yuan", symbol: "¥", region: "China", isPopular: true),
        "THB": CurrencyInfo(code: "THB", name: "Thai Baht", symbol: "฿", region: "Thailand", isPopular: true),
        "SGD": CurrencyInfo(code: "SGD", name: "Singapore Dollar", symbol: "S$", region: "Singapore", isPopular: true),
        "HKD": CurrencyInfo(code: "HKD", name: "Hong Kong Dollar", symbol: "HK$", region: "Hong Kong", isPopular: true),
        "TWD": CurrencyInfo(code: "TWD", name: "Taiwan Dollar", symbol: "NT$", region: "Taiwan"),
        "MYR": CurrencyInfo(code: "MYR", name: "Malaysian Ringgit", symbol: "RM", region: "Malaysia"),
        "PHP": CurrencyInfo(code: "PHP", name: "Philippine Peso", symbol: "₱", region: "Philippines"),
        "IDR": CurrencyInfo(code: "IDR", name: "Indonesian Rupiah", symbol: "Rp", region: "Indonesia", decimalPlaces: 0),
        "VND": CurrencyInfo(code: "VND", name: "Vietnamese Dong", symbol: "₫", region: "Vietnam", decimalPlaces: 0, isPopular: true),
        "INR": CurrencyInfo(code: "INR", name: "Indian Rupee", symbol: "₹", region: "India"),
        
        // Oceania
        "AUD": CurrencyInfo(code: "AUD", name: "Australian Dollar", symbol: "A$", region: "Australia", isPopular: true),
        "NZD": CurrencyInfo(code: "NZD", name: "New Zealand Dollar", symbol: "NZ$", region: "New Zealand"),
        
        // Americas
        "CAD": CurrencyInfo(code: "CAD", name: "Canadian Dollar", symbol: "C$", region: "Canada", isPopular: true),
        "BRL": CurrencyInfo(code: "BRL", name: "Brazilian Real", symbol: "R$", region: "Brazil"),
        "MXN": CurrencyInfo(code: "MXN", name: "Mexican Peso", symbol: "$", region: "Mexico"),
        "ARS": CurrencyInfo(code: "ARS", name: "Argentine Peso", symbol: "$", region: "Argentina"),
        "CLP": CurrencyInfo(code: "CLP", name: "Chilean Peso", symbol: "$", region: "Chile", decimalPlaces: 0),
        "COP": CurrencyInfo(code: "COP", name: "Colombian Peso", symbol: "$", region: "Colombia", decimalPlaces: 0),
        "PEN": CurrencyInfo(code: "PEN", name: "Peruvian Sol", symbol: "S/", region: "Peru"),
        
        // Europe
        "CHF": CurrencyInfo(code: "CHF", name: "Swiss Franc", symbol: "CHF", region: "Switzerland", isPopular: true),
        "NOK": CurrencyInfo(code: "NOK", name: "Norwegian Krone", symbol: "kr", region: "Norway"),
        "SEK": CurrencyInfo(code: "SEK", name: "Swedish Krona", symbol: "kr", region: "Sweden"),
        "DKK": CurrencyInfo(code: "DKK", name: "Danish Krone", symbol: "kr", region: "Denmark"),
        "PLN": CurrencyInfo(code: "PLN", name: "Polish Zloty", symbol: "zł", region: "Poland"),
        "CZK": CurrencyInfo(code: "CZK", name: "Czech Koruna", symbol: "Kč", region: "Czech Republic"),
        "HUF": CurrencyInfo(code: "HUF", name: "Hungarian Forint", symbol: "Ft", region: "Hungary", decimalPlaces: 0),
        "RON": CurrencyInfo(code: "RON", name: "Romanian Leu", symbol: "lei", region: "Romania"),
        "BGN": CurrencyInfo(code: "BGN", name: "Bulgarian Lev", symbol: "лв", region: "Bulgaria"),
        "HRK": CurrencyInfo(code: "HRK", name: "Croatian Kuna", symbol: "kn", region: "Croatia"),
        "RSD": CurrencyInfo(code: "RSD", name: "Serbian Dinar", symbol: "дин", region: "Serbia"),
        "RUB": CurrencyInfo(code: "RUB", name: "Russian Ruble", symbol: "₽", region: "Russia"),
        "TRY": CurrencyInfo(code: "TRY", name: "Turkish Lira", symbol: "₺", region: "Turkey"),
        
        // Middle East & Africa
        "AED": CurrencyInfo(code: "AED", name: "UAE Dirham", symbol: "د.إ", region: "United Arab Emirates"),
        "SAR": CurrencyInfo(code: "SAR", name: "Saudi Riyal", symbol: "ر.س", region: "Saudi Arabia"),
        "QAR": CurrencyInfo(code: "QAR", name: "Qatari Riyal", symbol: "ر.ق", region: "Qatar"),
        "KWD": CurrencyInfo(code: "KWD", name: "Kuwaiti Dinar", symbol: "د.ك", region: "Kuwait", decimalPlaces: 3),
        "BHD": CurrencyInfo(code: "BHD", name: "Bahraini Dinar", symbol: "د.ب", region: "Bahrain", decimalPlaces: 3),
        "OMR": CurrencyInfo(code: "OMR", name: "Omani Rial", symbol: "ر.ع.", region: "Oman", decimalPlaces: 3),
        "JOD": CurrencyInfo(code: "JOD", name: "Jordanian Dinar", symbol: "د.ا", region: "Jordan", decimalPlaces: 3),
        "LBP": CurrencyInfo(code: "LBP", name: "Lebanese Pound", symbol: "ل.ل", region: "Lebanon", decimalPlaces: 0),
        "ILS": CurrencyInfo(code: "ILS", name: "Israeli Shekel", symbol: "₪", region: "Israel"),
        "EGP": CurrencyInfo(code: "EGP", name: "Egyptian Pound", symbol: "ج.م", region: "Egypt"),
        "ZAR": CurrencyInfo(code: "ZAR", name: "South African Rand", symbol: "R", region: "South Africa"),
        "NGN": CurrencyInfo(code: "NGN", name: "Nigerian Naira", symbol: "₦", region: "Nigeria"),
        "KES": CurrencyInfo(code: "KES", name: "Kenyan Shilling", symbol: "KSh", region: "Kenya"),
        "GHS": CurrencyInfo(code: "GHS", name: "Ghanaian Cedi", symbol: "₵", region: "Ghana"),
        "MAD": CurrencyInfo(code: "MAD", name: "Moroccan Dirham", symbol: "د.م.", region: "Morocco"),
        "TND": CurrencyInfo(code: "TND", name: "Tunisian Dinar", symbol: "د.ت", region: "Tunisia", decimalPlaces: 3),
        "DZD": CurrencyInfo(code: "DZD", name: "Algerian Dinar", symbol: "د.ج", region: "Algeria"),
        
        // Others
        "ISK": CurrencyInfo(code: "ISK", name: "Icelandic Krona", symbol: "kr", region: "Iceland", decimalPlaces: 0),
        "ALL": CurrencyInfo(code: "ALL", name: "Albanian Lek", symbol: "L", region: "Albania"),
        "MKD": CurrencyInfo(code: "MKD", name: "Macedonian Denar", symbol: "ден", region: "North Macedonia"),
        "BAM": CurrencyInfo(code: "BAM", name: "Bosnia-Herzegovina Convertible Mark", symbol: "KM", region: "Bosnia and Herzegovina"),
        "MDL": CurrencyInfo(code: "MDL", name: "Moldovan Leu", symbol: "L", region: "Moldova"),
        "GEL": CurrencyInfo(code: "GEL", name: "Georgian Lari", symbol: "₾", region: "Georgia"),
        "AMD": CurrencyInfo(code: "AMD", name: "Armenian Dram", symbol: "֏", region: "Armenia"),
        "AZN": CurrencyInfo(code: "AZN", name: "Azerbaijani Manat", symbol: "₼", region: "Azerbaijan"),
        "KZT": CurrencyInfo(code: "KZT", name: "Kazakhstani Tenge", symbol: "₸", region: "Kazakhstan"),
        "UZS": CurrencyInfo(code: "UZS", name: "Uzbekistani Som", symbol: "лв", region: "Uzbekistan", decimalPlaces: 0),
        "KGS": CurrencyInfo(code: "KGS", name: "Kyrgystani Som", symbol: "лв", region: "Kyrgyzstan"),
        "TJS": CurrencyInfo(code: "TJS", name: "Tajikistani Somoni", symbol: "SM", region: "Tajikistan"),
        "TMT": CurrencyInfo(code: "TMT", name: "Turkmenistani Manat", symbol: "m", region: "Turkmenistan"),
        "MNT": CurrencyInfo(code: "MNT", name: "Mongolian Tugrik", symbol: "₮", region: "Mongolia", decimalPlaces: 0),
        "NPR": CurrencyInfo(code: "NPR", name: "Nepalese Rupee", symbol: "₨", region: "Nepal"),
        "PKR": CurrencyInfo(code: "PKR", name: "Pakistani Rupee", symbol: "₨", region: "Pakistan"),
        "BDT": CurrencyInfo(code: "BDT", name: "Bangladeshi Taka", symbol: "৳", region: "Bangladesh"),
        "LKR": CurrencyInfo(code: "LKR", name: "Sri Lankan Rupee", symbol: "₨", region: "Sri Lanka"),
        "MVR": CurrencyInfo(code: "MVR", name: "Maldivian Rufiyaa", symbol: "Rf", region: "Maldives"),
        "AFN": CurrencyInfo(code: "AFN", name: "Afghan Afghani", symbol: "؋", region: "Afghanistan"),
        "IRR": CurrencyInfo(code: "IRR", name: "Iranian Rial", symbol: "﷼", region: "Iran", decimalPlaces: 0),
        "IQD": CurrencyInfo(code: "IQD", name: "Iraqi Dinar", symbol: "د.ع", region: "Iraq", decimalPlaces: 3),
        "SYP": CurrencyInfo(code: "SYP", name: "Syrian Pound", symbol: "£", region: "Syria"),
        "YER": CurrencyInfo(code: "YER", name: "Yemeni Rial", symbol: "﷼", region: "Yemen")
    ]
    
    private init() {}
    
    func getCurrency(code: String) -> CurrencyInfo? {
        return currencies[code.uppercased()]
    }
    
    func getAllCurrencies() -> [CurrencyInfo] {
        return Array(currencies.values).sorted { $0.code < $1.code }
    }
    
    func getPopularCurrencies() -> [CurrencyInfo] {
        return currencies.values.filter { $0.isPopular }.sorted { $0.code < $1.code }
    }
    
    func getCurrenciesByRegion() -> [String: [CurrencyInfo]] {
        var regionGroups: [String: [CurrencyInfo]] = [:]
        
        for currency in currencies.values {
            let region = getRegionGroup(for: currency.region)
            if regionGroups[region] == nil {
                regionGroups[region] = []
            }
            regionGroups[region]?.append(currency)
        }
        
        // Sort currencies within each region
        for key in regionGroups.keys {
            regionGroups[key]?.sort { $0.code < $1.code }
        }
        
        return regionGroups
    }
    
    func searchCurrencies(query: String) -> [CurrencyInfo] {
        let lowercaseQuery = query.lowercased()
        return currencies.values.filter {
            $0.code.lowercased().contains(lowercaseQuery) ||
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.region.lowercased().contains(lowercaseQuery)
        }.sorted { $0.code < $1.code }
    }
    
    private func getRegionGroup(for region: String) -> String {
        switch region {
        case let r where r.contains("Japan") || r.contains("Korea") || r.contains("China") || 
                        r.contains("Thailand") || r.contains("Singapore") || r.contains("Hong Kong") ||
                        r.contains("Taiwan") || r.contains("Malaysia") || r.contains("Philippines") ||
                        r.contains("Indonesia") || r.contains("Vietnam") || r.contains("India"):
            return "Asia"
            
        case let r where r.contains("Australia") || r.contains("New Zealand"):
            return "Oceania"
            
        case let r where r.contains("United States") || r.contains("Canada") || r.contains("Brazil") ||
                        r.contains("Mexico") || r.contains("Argentina") || r.contains("Chile") ||
                        r.contains("Colombia") || r.contains("Peru"):
            return "Americas"
            
        case let r where r.contains("European") || r.contains("United Kingdom") || r.contains("Switzerland") ||
                        r.contains("Norway") || r.contains("Sweden") || r.contains("Denmark") ||
                        r.contains("Poland") || r.contains("Czech") || r.contains("Hungary") ||
                        r.contains("Romania") || r.contains("Bulgaria") || r.contains("Croatia") ||
                        r.contains("Serbia") || r.contains("Russia") || r.contains("Turkey"):
            return "Europe"
            
        case let r where r.contains("UAE") || r.contains("Saudi") || r.contains("Qatar") ||
                        r.contains("Kuwait") || r.contains("Bahrain") || r.contains("Oman") ||
                        r.contains("Jordan") || r.contains("Lebanon") || r.contains("Israel") ||
                        r.contains("Egypt") || r.contains("South Africa") || r.contains("Nigeria") ||
                        r.contains("Kenya") || r.contains("Ghana") || r.contains("Morocco") ||
                        r.contains("Tunisia") || r.contains("Algeria"):
            return "Middle East & Africa"
            
        default:
            return "Others"
        }
    }
}

// 通貨フォーマット用のヘルパー
extension CurrencyInfo {
    func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = decimalPlaces
        
        // 特定の通貨に対するロケール設定
        formatter.locale = getLocale()
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(symbol)\(amount)"
    }
    
    private func getLocale() -> Locale {
        switch code {
        case "JPY": return Locale(identifier: "ja_JP")
        case "USD": return Locale(identifier: "en_US")
        case "EUR": return Locale(identifier: "de_DE")
        case "GBP": return Locale(identifier: "en_GB")
        case "KRW": return Locale(identifier: "ko_KR")
        case "CNY": return Locale(identifier: "zh_CN")
        case "THB": return Locale(identifier: "th_TH")
        case "SGD": return Locale(identifier: "en_SG")
        case "HKD": return Locale(identifier: "zh_HK")
        case "AUD": return Locale(identifier: "en_AU")
        case "CAD": return Locale(identifier: "en_CA")
        case "CHF": return Locale(identifier: "de_CH")
        case "INR": return Locale(identifier: "hi_IN")
        case "BRL": return Locale(identifier: "pt_BR")
        case "MXN": return Locale(identifier: "es_MX")
        case "RUB": return Locale(identifier: "ru_RU")
        case "TRY": return Locale(identifier: "tr_TR")
        case "VND": return Locale(identifier: "vi_VN")
        case "ZAR": return Locale(identifier: "af_ZA")
        default: return Locale.current
        }
    }
}
