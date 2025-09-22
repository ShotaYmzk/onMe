//
//  SettingsView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingCurrencyPicker = false
    @State private var showingLanguagePicker = false
    @State private var showingAbout = false
    @State private var showingExchangeRates = false
    
    private let currencyDB = CurrencyDatabase.shared
    
    private func formatLastUpdate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    VStack(spacing: 16) {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "gear")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(spacing: 4) {
                            Text("onMe")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("旅行の支出管理")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        modernGeneralSection
                        modernCurrencySection
                        modernAppearanceSection
                        modernDataSection
                        modernAboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerView(selectedCurrency: $appState.preferredCurrency)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingExchangeRates) {
            ExchangeRatesView()
        }
    }
    
    // MARK: - Modern Sections
    
    private var modernGeneralSection: some View {
        SettingsSectionView(title: "一般設定", icon: "gear.circle.fill", color: .blue) {
            VStack(spacing: 0) {
                SettingsRowView(
                    icon: "bell.circle.fill",
                    iconColor: .orange,
                    title: "通知",
                    subtitle: "支出の追加や清算の提案を通知",
                    action: {
                        appState.notificationsEnabled.toggle()
                    },
                    trailing: {
                        Toggle("", isOn: $appState.notificationsEnabled)
                            .labelsHidden()
                    }
                )
            }
        }
    }
    
    private var modernCurrencySection: some View {
        SettingsSectionView(title: "通貨・為替", icon: "yensign.circle.fill", color: .green) {
            VStack(spacing: 0) {
                SettingsRowView(
                    icon: "dollarsign.circle.fill",
                    iconColor: .green,
                    title: "デフォルト通貨",
                    subtitle: currencyDB.getCurrency(code: appState.preferredCurrency)?.name ?? appState.preferredCurrency,
                    action: { showingCurrencyPicker = true },
                    trailing: {
                        HStack(spacing: 8) {
                            if let currency = currencyDB.getCurrency(code: appState.preferredCurrency) {
                                Text(currency.symbol)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                                Text(currency.code)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                )\n                \n                Divider()\n                    .padding(.leading, 50)\n                \n                SettingsRowView(\n                    icon: \"arrow.triangle.2.circlepath.circle.fill\",\n                    iconColor: .blue,\n                    title: \"為替レート\",\n                    subtitle: appState.lastExchangeRateUpdate != nil ? \"最終更新: \\(formatLastUpdate(appState.lastExchangeRateUpdate!))\": \"未更新\",\n                    action: { showingExchangeRates = true },\n                    trailing: {\n                        HStack(spacing: 8) {\n                            if appState.isLoadingExchangeRates {\n                                ProgressView()\n                                    .scaleEffect(0.8)\n                            } else {\n                                Image(systemName: \"chevron.right\")\n                                    .font(.caption)\n                                    .foregroundColor(.secondary)\n                            }\n                        }\n                    }\n                )\n            }\n        }\n    }\n    \n    private var modernAppearanceSection: some View {\n        SettingsSectionView(title: \"外観\", icon: \"paintbrush.fill\", color: .purple) {\n            VStack(spacing: 0) {\n                SettingsRowView(\n                    icon: \"moon.circle.fill\",\n                    iconColor: .indigo,\n                    title: \"ダークモード\",\n                    subtitle: \"システム設定に従う\",\n                    action: {\n                        appState.isDarkModeEnabled.toggle()\n                    },\n                    trailing: {\n                        Toggle(\"\", isOn: $appState.isDarkModeEnabled)\n                            .labelsHidden()\n                    }\n                )\n            }\n        }\n    }\n    \n    private var modernDataSection: some View {\n        SettingsSectionView(title: \"データ管理\", icon: \"externaldrive.fill\", color: .orange) {\n            VStack(spacing: 0) {\n                SettingsRowView(\n                    icon: \"square.and.arrow.up.circle.fill\",\n                    iconColor: .blue,\n                    title: \"データエクスポート\",\n                    subtitle: \"支出データをCSV形式で出力\",\n                    action: { exportData() },\n                    trailing: {\n                        Image(systemName: \"chevron.right\")\n                            .font(.caption)\n                            .foregroundColor(.secondary)\n                    }\n                )\n                \n                Divider()\n                    .padding(.leading, 50)\n                \n                SettingsRowView(\n                    icon: \"trash.circle.fill\",\n                    iconColor: .red,\n                    title: \"データをクリア\",\n                    subtitle: \"すべての支出データを削除\",\n                    action: { clearAllData() },\n                    trailing: {\n                        Image(systemName: \"chevron.right\")\n                            .font(.caption)\n                            .foregroundColor(.secondary)\n                    }\n                )\n            }\n        }\n    }\n    \n    private var modernAboutSection: some View {\n        SettingsSectionView(title: \"アプリについて\", icon: \"info.circle.fill\", color: .gray) {\n            VStack(spacing: 0) {\n                SettingsRowView(\n                    icon: \"doc.text.circle.fill\",\n                    iconColor: .blue,\n                    title: \"onMeについて\",\n                    subtitle: \"バージョン 1.0.0\",\n                    action: { showingAbout = true },\n                    trailing: {\n                        Image(systemName: \"chevron.right\")\n                            .font(.caption)\n                            .foregroundColor(.secondary)\n                    }\n                )\n                \n                Divider()\n                    .padding(.leading, 50)\n                \n                SettingsRowView(\n                    icon: \"star.circle.fill\",\n                    iconColor: .yellow,\n                    title: \"App Storeでレビュー\",\n                    subtitle: \"アプリの評価をお願いします\",\n                    action: { openAppStore() },\n                    trailing: {\n                        Image(systemName: \"arrow.up.right\")\n                            .font(.caption)\n                            .foregroundColor(.secondary)\n                    }\n                )\n                \n                Divider()\n                    .padding(.leading, 50)\n                \n                SettingsRowView(\n                    icon: \"envelope.circle.fill\",\n                    iconColor: .green,\n                    title: \"フィードバック\",\n                    subtitle: \"ご意見・ご要望をお聞かせください\",\n                    action: { sendFeedback() },\n                    trailing: {\n                        Image(systemName: \"arrow.up.right\")\n                            .font(.caption)\n                            .foregroundColor(.secondary)\n                    }\n                )\n            }\n        }\n    }\n    \n    // MARK: - Actions\n    \n    private func exportData() {\n        // データエクスポート処理を実装\n    }\n    \n    private func clearAllData() {\n        // データクリア処理を実装\n    }\n    \n    private func openAppStore() {\n        if let url = URL(string: \"https://apps.apple.com/app/id123456789\") {\n            UIApplication.shared.open(url)\n        }\n    }\n    \n    private func sendFeedback() {\n        if let url = URL(string: \"mailto:feedback@onme-app.com?subject=onMe%20Feedback\") {\n            UIApplication.shared.open(url)\n        }\n    }\n    \n    // MARK: - Legacy Sections (for reference)\n    \n    private var generalSection: some View {"}
        Section(header: Text("一般")) {
            HStack {
                Image(systemName: "yensign.circle")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                Text("デフォルト通貨")
                
                Spacer()
                
                Button(appState.preferredCurrency) {
                    showingCurrencyPicker = true
                }
                .foregroundColor(.blue)
            }
            
            // 為替レート情報
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("為替レート")
                    
                    Spacer()
                    
                    if appState.isLoadingExchangeRates {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("更新") {
                            appState.loadExchangeRates()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                if let lastUpdate = appState.lastExchangeRateUpdate {
                    Text("最終更新: \(formatLastUpdate(lastUpdate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
                
                // 主要通貨の為替レート表示
                if !appState.exchangeRates.isEmpty && appState.preferredCurrency != "USD" {
                    VStack(alignment: .leading, spacing: 2) {
                        ExchangeRateDisplayView(fromCurrency: "USD", toCurrency: appState.preferredCurrency)
                            .padding(.leading, 32)
                        
                        if appState.preferredCurrency != "JPY" {
                            ExchangeRateDisplayView(fromCurrency: "JPY", toCurrency: appState.preferredCurrency)
                                .padding(.leading, 32)
                        }
                    }
                }
            }
            
            HStack {
                Image(systemName: "bell")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                Text("通知")
                
                Spacer()
                
                Toggle("", isOn: $appState.notificationsEnabled)
                    .labelsHidden()
            }
        }
    }
    
    private var appearanceSection: some View {
        Section(header: Text("表示")) {
            HStack {
                Image(systemName: "moon")
                    .foregroundColor(.indigo)
                    .frame(width: 24)
                
                Text("ダークモード")
                
                Spacer()
                
                Toggle("", isOn: $appState.isDarkModeEnabled)
                    .labelsHidden()
            }
            
            HStack {
                Image(systemName: "textformat.size")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("アクセシビリティ")
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    private var dataSection: some View {
        Section(header: Text("データ")) {
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("データのエクスポート")
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            HStack {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                Text("すべてのデータを削除")
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("アプリについて")) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("アプリについて")
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .onTapGesture {
                showingAbout = true
            }
            
            HStack {
                Image(systemName: "star")
                    .foregroundColor(.yellow)
                    .frame(width: 24)
                
                Text("App Storeで評価")
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("フィードバック")
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) private var dismiss
    
    private let currencies = [
        ("JPY", "日本円", "¥"),
        ("USD", "米ドル", "$"),
        ("EUR", "ユーロ", "€"),
        ("GBP", "英ポンド", "£"),
        ("KRW", "韓国ウォン", "₩"),
        ("CNY", "中国元", "¥"),
        ("THB", "タイバーツ", "฿"),
        ("SGD", "シンガポールドル", "S$"),
        ("HKD", "香港ドル", "HK$"),
        ("AUD", "豪ドル", "A$")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(currencies, id: \.0) { currency in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(currency.1)
                                .font(.body)
                            Text("\(currency.0) (\(currency.2))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedCurrency == currency.0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCurrency = currency.0
                        dismiss()
                    }
                }
            }
            .navigationTitle("通貨を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // アプリアイコン
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text("TravelSettle")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("バージョン 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TravelSettleについて")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("TravelSettleは旅行や友人グループでの立替・割り勘・貸し借りを簡単に管理できるアプリです。支出を記録し、誰が誰にいくら返せば良いかを自動で計算します。")
                            .font(.body)
                            .lineSpacing(4)
                        
                        Text("主な機能")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "person.3.fill", title: "グループ管理", description: "旅行やイベントごとにグループを作成")
                            FeatureRow(icon: "creditcard.fill", title: "支出記録", description: "レシートOCRで簡単入力")
                            FeatureRow(icon: "arrow.left.arrow.right", title: "自動清算", description: "最適な返済ルートを提案")
                            FeatureRow(icon: "chart.bar.fill", title: "可視化", description: "支出状況をグラフで表示")
                        }
                        
                        Text("プライバシー")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.top)
                        
                        Text("すべてのデータはお使いのデバイスにローカル保存され、外部サーバーには送信されません。プライバシーを重視した設計となっています。")
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("アプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Views

struct SettingsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct SettingsRowView<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    let trailing: Trailing
    
    init(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.trailing = trailing()
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
                
                trailing
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExchangeRatesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var isRefreshing = false
    
    private let currencyDB = CurrencyDatabase.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(currencyDB.getPopularCurrencies(), id: \.code) { currency in
                        ExchangeRateRowView(
                            fromCurrency: "USD",
                            toCurrency: currency.code,
                            currencyInfo: currency
                        )
                        
                        if currency.code != currencyDB.getPopularCurrencies().last?.code {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("為替レート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshRates) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isRefreshing)
                }
            }
            .refreshable {
                await refreshRatesAsync()
            }
        }
    }
    
    private func refreshRates() {
        isRefreshing = true
        appState.loadExchangeRates()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
        }
    }
    
    @MainActor
    private func refreshRatesAsync() async {
        isRefreshing = true
        appState.loadExchangeRates()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
}

struct ExchangeRateRowView: View {
    let fromCurrency: String
    let toCurrency: String
    let currencyInfo: CurrencyInfo
    
    @EnvironmentObject private var appState: AppState
    @State private var exchangeRate: String = "---"
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(currencyInfo.symbol)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(currencyInfo.code)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(currencyInfo.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("1 USD = ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                +
                Text(exchangeRate)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                +
                Text(" \(toCurrency)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastUpdate = appState.lastExchangeRateUpdate {
                    Text(formatLastUpdate(lastUpdate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            updateExchangeRate()
        }
        .onChange(of: appState.exchangeRates) {
            updateExchangeRate()
        }
    }
    
    private func updateExchangeRate() {
        if let rate = appState.exchangeRates[toCurrency] {
            exchangeRate = String(format: "%.4f", rate)
        }
    }
    
    private func formatLastUpdate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
