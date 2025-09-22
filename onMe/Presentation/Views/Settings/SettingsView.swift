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
    
    var body: some View {
        NavigationView {
            List {
                generalSection
                appearanceSection
                dataSection
                aboutSection
            }
            .navigationTitle("設定")
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerView(selectedCurrency: $appState.preferredCurrency)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private var generalSection: some View {
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

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
