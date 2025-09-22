//
//  SettlementDetailView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI

struct SettlementDetailView: View {
    let suggestion: SettlementSuggestion
    let group: TravelGroup
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = SettlementViewModel()
    
    @State private var showingConfirmation = false
    @State private var note = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var customAmount: Decimal
    @State private var isEditingAmount = false
    
    private var fromMember: GroupMember? {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .first { $0.id == suggestion.fromMemberId }
    }
    
    private var toMember: GroupMember? {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .first { $0.id == suggestion.toMemberId }
    }
    
    init(suggestion: SettlementSuggestion, group: TravelGroup) {
        self.suggestion = suggestion
        self.group = group
        self._customAmount = State(initialValue: suggestion.amount)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    settlementOverviewSection
                    amountAdjustmentSection
                    noteSection
                    actionSection
                }
                .padding()
            }
            .navigationTitle("返済詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("確認", isPresented: $showingConfirmation) {
                Button("キャンセル", role: .cancel) { }
                Button("完了", role: .destructive) {
                    markAsCompleted()
                }
            } message: {
                Text("この返済を完了済みとしてマークしますか？")
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var settlementOverviewSection: some View {
        VStack(spacing: 20) {
            // 支払者と受取者の表示
            HStack(spacing: 20) {
                VStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(fromMember?.name?.first ?? "?"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        )
                    
                    Text(fromMember?.name ?? "Unknown")
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("支払者")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("\(customAmount as NSDecimalNumber, formatter: currencyFormatter)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text(suggestion.currency)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(toMember?.name?.first ?? "?"))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        )
                    
                    Text(toMember?.name ?? "Unknown")
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("受取者")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 返済詳細カード
            VStack(spacing: 12) {
                HStack {
                    Text("返済詳細")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("返済金額")
                        Spacer()
                        Text("\(customAmount as NSDecimalNumber, formatter: currencyFormatter) \(suggestion.currency)")
                            .fontWeight(.medium)
                    }
                    
                    if customAmount < suggestion.amount {
                        Divider()
                        
                        HStack {
                            Text("残債")
                            Spacer()
                            Text("\((suggestion.amount - customAmount) as NSDecimalNumber, formatter: currencyFormatter) \(suggestion.currency)")
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("支払方法")
                        Spacer()
                        Text("現金・振込など")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var amountAdjustmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("返済金額の調整")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // 現在の金額表示
                HStack {
                    Text("返済金額")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditingAmount.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("\(customAmount as NSDecimalNumber, formatter: currencyFormatter)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(suggestion.currency)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: isEditingAmount ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                if isEditingAmount {
                    VStack(spacing: 12) {
                        // スライダー
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(suggestion.amount as NSDecimalNumber, formatter: currencyFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(truncating: customAmount as NSDecimalNumber) },
                                    set: { customAmount = Decimal($0) }
                                ),
                                in: 0...Double(truncating: suggestion.amount as NSDecimalNumber),
                                step: 100
                            )
                            .accentColor(.blue)
                        }
                        
                        // プリセット金額ボタン
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { ratio in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        customAmount = suggestion.amount * Decimal(ratio)
                                    }
                                }) {
                                    VStack(spacing: 2) {
                                        Text(ratio == 1.0 ? "全額" : "\(Int(ratio * 100))%")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text("\(Int(truncating: (suggestion.amount * Decimal(ratio)) as NSDecimalNumber))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        customAmount == suggestion.amount * Decimal(ratio) ?
                                        Color.blue : Color.secondary.opacity(0.1)
                                    )
                                    .foregroundColor(
                                        customAmount == suggestion.amount * Decimal(ratio) ?
                                        .white : .primary
                                    )
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // カスタム金額入力
                        HStack {
                            Text("カスタム金額:")
                                .font(.subheadline)
                            TextField("金額を入力", value: $customAmount, formatter: decimalFormatter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                            Text(suggestion.currency)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // 残債表示
                if customAmount < suggestion.amount {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text("残債: \((suggestion.amount - customAmount) as NSDecimalNumber, formatter: currencyFormatter) \(suggestion.currency)")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("メモ（任意）")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("返済に関するメモを入力", text: $note, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingConfirmation = true
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("返済完了")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
            
            Button(action: {
                // 後で返済する機能（リマインダー設定など）
            }) {
                HStack {
                    Image(systemName: "clock")
                    Text("後で返済")
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            Text("返済完了をタップすると、この返済が完了済みとしてマークされます")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private func markAsCompleted() {
        do {
            // カスタム金額で新しいsuggestionを作成
            let customSuggestion = SettlementSuggestion(
                fromMemberId: suggestion.fromMemberId,
                toMemberId: suggestion.toMemberId,
                amount: customAmount,
                currency: suggestion.currency
            )
            try viewModel.markSettlementAsCompleted(customSuggestion, in: group, context: viewContext, note: note.isEmpty ? nil : note)
            dismiss()
        } catch {
            alertMessage = "返済の記録に失敗しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

#Preview {
    let group = TravelGroup()
    return SettlementDetailView(
        suggestion: SettlementSuggestion(
            fromMemberId: UUID(),
            toMemberId: UUID(),
            amount: 1000,
            currency: "JPY"
        ),
        group: group
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
