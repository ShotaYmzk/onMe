//
//  CurrencyPickerView.swift
//  onMe
//
//  Created by AI Assistant on 2025/09/22.
//

import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    private let currencyDB = CurrencyDatabase.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // タブ選択
                Picker("Currency Type", selection: $selectedTab) {
                    Text("人気").tag(0)
                    Text("すべて").tag(1)
                    Text("地域別").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                // 検索バー
                SearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                // コンテンツ
                switch selectedTab {
                case 0:
                    PopularCurrenciesView(
                        selectedCurrency: $selectedCurrency,
                        searchText: searchText,
                        onSelect: { dismiss() }
                    )
                case 1:
                    AllCurrenciesView(
                        selectedCurrency: $selectedCurrency,
                        searchText: searchText,
                        onSelect: { dismiss() }
                    )
                case 2:
                    RegionalCurrenciesView(
                        selectedCurrency: $selectedCurrency,
                        searchText: searchText,
                        onSelect: { dismiss() }
                    )
                default:
                    EmptyView()
                }
            }
            .navigationTitle("通貨を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("通貨コードまたは国名で検索", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct PopularCurrenciesView: View {
    @Binding var selectedCurrency: String
    let searchText: String
    let onSelect: () -> Void
    
    private let currencyDB = CurrencyDatabase.shared
    
    var filteredCurrencies: [CurrencyInfo] {
        let popular = currencyDB.getPopularCurrencies()
        if searchText.isEmpty {
            return popular
        } else {
            return currencyDB.searchCurrencies(query: searchText).filter { $0.isPopular }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredCurrencies, id: \.code) { currency in
                    CurrencyRowView(
                        currency: currency,
                        isSelected: currency.code == selectedCurrency,
                        onTap: {
                            selectedCurrency = currency.code
                            onSelect()
                        }
                    )
                    
                    if currency.code != filteredCurrencies.last?.code {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
    }
}

struct AllCurrenciesView: View {
    @Binding var selectedCurrency: String
    let searchText: String
    let onSelect: () -> Void
    
    private let currencyDB = CurrencyDatabase.shared
    
    var filteredCurrencies: [CurrencyInfo] {
        if searchText.isEmpty {
            return currencyDB.getAllCurrencies()
        } else {
            return currencyDB.searchCurrencies(query: searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredCurrencies, id: \.code) { currency in
                    CurrencyRowView(
                        currency: currency,
                        isSelected: currency.code == selectedCurrency,
                        onTap: {
                            selectedCurrency = currency.code
                            onSelect()
                        }
                    )
                    
                    if currency.code != filteredCurrencies.last?.code {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
    }
}

struct RegionalCurrenciesView: View {
    @Binding var selectedCurrency: String
    let searchText: String
    let onSelect: () -> Void
    
    private let currencyDB = CurrencyDatabase.shared
    
    var filteredCurrenciesByRegion: [String: [CurrencyInfo]] {
        let allByRegion = currencyDB.getCurrenciesByRegion()
        
        if searchText.isEmpty {
            return allByRegion
        } else {
            let filtered = currencyDB.searchCurrencies(query: searchText)
            var result: [String: [CurrencyInfo]] = [:]
            
            for currency in filtered {
                let region = getRegionGroup(for: currency.region)
                if result[region] == nil {
                    result[region] = []
                }
                result[region]?.append(currency)
            }
            
            return result
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(filteredCurrenciesByRegion.keys.sorted()), id: \.self) { region in
                    if let currencies = filteredCurrenciesByRegion[region], !currencies.isEmpty {
                        Section {
                            ForEach(currencies, id: \.code) { currency in
                                CurrencyRowView(
                                    currency: currency,
                                    isSelected: currency.code == selectedCurrency,
                                    onTap: {
                                        selectedCurrency = currency.code
                                        onSelect()
                                    }
                                )
                                
                                if currency.code != currencies.last?.code {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        } header: {
                            Text(region)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.systemGroupedBackground))
                        }
                    }
                }
            }
        }
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

struct CurrencyRowView: View {
    let currency: CurrencyInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 通貨シンボル
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(currency.symbol)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? .white : .primary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(currency.code)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if currency.isPopular {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(currency.name)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text(currency.region)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
    }
}

#Preview {
    CurrencyPickerView(selectedCurrency: .constant("JPY"))
}
