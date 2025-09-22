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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    settlementOverviewSection
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
                    
                    Text("\(suggestion.amount as NSDecimalNumber, formatter: currencyFormatter)")
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
                        Text("金額")
                        Spacer()
                        Text("\(suggestion.amount as NSDecimalNumber, formatter: currencyFormatter) \(suggestion.currency)")
                            .fontWeight(.medium)
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
            try viewModel.markSettlementAsCompleted(suggestion, in: group, context: viewContext)
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
}

#Preview {
    SettlementDetailView(
        suggestion: SettlementSuggestion(
            fromMemberId: UUID(),
            toMemberId: UUID(),
            amount: 1000,
            currency: "JPY"
        ),
        group: TravelGroup()
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
