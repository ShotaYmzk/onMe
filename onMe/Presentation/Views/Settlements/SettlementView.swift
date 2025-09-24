//
//  SettlementView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import CoreData

struct SettlementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SettlementViewModel()
    
    @State private var showingSettlementDetail = false
    @State private var selectedSuggestion: SettlementSuggestion?
    @State private var showingExpenseForm = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 統一ヘッダー
                UnifiedHeaderView(
                    title: "清算",
                    subtitle: appState.selectedGroup != nil ? "グループの清算を管理" : "グループを選択して清算を開始",
                    primaryAction: appState.selectedGroup != nil ? { showingExpenseForm = true } : nil,
                    primaryActionTitle: appState.selectedGroup != nil ? "支出登録" : nil,
                    primaryActionIcon: appState.selectedGroup != nil ? "plus.circle.fill" : nil,
                    showStatistics: appState.selectedGroup != nil && !viewModel.settlementSuggestions.isEmpty,
                    statisticsData: appState.selectedGroup != nil && !viewModel.settlementSuggestions.isEmpty ? 
                        HeaderStatistics(items: [
                            HeaderStatistics.StatItem(
                                title: "未清算件数",
                                value: "\(viewModel.settlementSuggestions.count)件",
                                icon: "arrow.left.arrow.right.circle.fill",
                                color: Color.unifiedAccent
                            ),
                            HeaderStatistics.StatItem(
                                title: "清算済み",
                                value: "\(viewModel.completedSettlements.count)件",
                                icon: "checkmark.circle.fill",
                                color: Color.unifiedSecondary
                            )
                        ]) : nil
                )
                
                // メインコンテンツ
                if appState.selectedGroup == nil {
                    SettlementNoGroupSelectedView {
                        showingExpenseForm = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            balanceOverviewSection
                            settlementSuggestionsSection
                            settlementHistorySection
                        }
                        .padding()
                    }
                }
            }
            .unifiedNavigationStyle()
            .onAppear {
                if let group = appState.selectedGroup {
                    viewModel.loadSettlements(for: group)
                }
            }
            .onChange(of: appState.selectedGroup) { _, newGroup in
                if let group = newGroup {
                    viewModel.loadSettlements(for: group)
                }
            }
            .sheet(item: $selectedSuggestion) { suggestion in
                SettlementDetailView(suggestion: suggestion, group: appState.selectedGroup!)
            }
            .sheet(isPresented: $showingExpenseForm) {
                ExpenseFormView(preselectedGroup: appState.selectedGroup)
            }
        }
    }
    
    private var balanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("残高概要")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(viewModel.memberBalances) { balance in
                    BalanceCardView(balance: balance, group: appState.selectedGroup!)
                }
            }
        }
    }
    
    private var settlementSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("返済提案")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if !viewModel.settlementSuggestions.isEmpty {
                    Text("タップして金額を調整")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.settlementSuggestions.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("すべて清算済みです")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                ForEach(viewModel.settlementSuggestions) { suggestion in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSuggestion = suggestion
                        }
                    }) {
                        SettlementSuggestionRow(suggestion: suggestion, group: appState.selectedGroup!)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var settlementHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("清算履歴")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.completedSettlements.isEmpty {
                Text("清算履歴がありません")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.completedSettlements, id: \.id) { settlement in
                    SettlementHistoryRow(settlement: settlement)
                }
            }
        }
    }
}

struct BalanceCardView: View {
    let balance: MemberBalance
    let group: TravelGroup
    
    private var memberName: String {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .first { $0.id == balance.memberId }?.name ?? "Unknown"
    }
    
    private var isPositive: Bool {
        balance.balance > 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(memberName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            HStack {
                Text(isPositive ? "受取" : "支払")
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isPositive ? Color.green : Color.red).opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            Text("\(abs(balance.balance) as NSDecimalNumber, formatter: currencyFormatter)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isPositive ? .green : .red)
            
            Text(group.currency ?? "JPY")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

struct SettlementSuggestionRow: View {
    let suggestion: SettlementSuggestion
    let group: TravelGroup
    
    private var fromMemberName: String {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .first { $0.id == suggestion.fromMemberId }?.name ?? "Unknown"
    }
    
    private var toMemberName: String {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .first { $0.id == suggestion.toMemberId }?.name ?? "Unknown"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(fromMemberName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(toMemberName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("返済提案")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("金額調整可能")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(suggestion.amount as NSDecimalNumber, formatter: currencyFormatter)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text(suggestion.currency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

struct SettlementHistoryRow: View {
    let settlement: Settlement
    
    private var payerName: String {
        settlement.payer?.name ?? "Unknown"
    }
    
    private var receiverName: String {
        settlement.receiver?.name ?? "Unknown"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(payerName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(receiverName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let date = settlement.settledDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let note = settlement.note, !note.isEmpty {
                        Text(note)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(settlement.amount ?? NSDecimalNumber.zero, formatter: currencyFormatter)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

struct SettlementNoGroupSelectedView: View {
    let onCreateExpense: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("グループを選択してください")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("グループタブからグループを選択すると\nそのグループの清算状況を表示できます")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 12) {
                Text("または")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: onCreateExpense) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("新しい支出を登録")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

#Preview {
    SettlementView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
