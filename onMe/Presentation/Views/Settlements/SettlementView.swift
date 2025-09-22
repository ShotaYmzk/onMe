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
    
    var body: some View {
        NavigationView {
            VStack {
                if appState.selectedGroup == nil {
                    NoGroupSelectedView()
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
            .navigationTitle(appState.selectedGroup?.name ?? "清算")
            .onAppear {
                if let group = appState.selectedGroup {
                    viewModel.loadSettlements(for: group)
                }
            }
            .onChange(of: appState.selectedGroup) { newGroup in
                if let group = newGroup {
                    viewModel.loadSettlements(for: group)
                }
            }
            .sheet(item: $selectedSuggestion) { suggestion in
                SettlementDetailView(suggestion: suggestion, group: appState.selectedGroup!)
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
            Text("返済提案")
                .font(.headline)
                .fontWeight(.semibold)
            
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
                    SettlementSuggestionRow(suggestion: suggestion, group: appState.selectedGroup!)
                        .onTapGesture {
                            selectedSuggestion = suggestion
                        }
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
                
                Text("返済提案")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                
                if let date = settlement.settledDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(settlement.amount as NSDecimalNumber, formatter: currencyFormatter)")
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

#Preview {
    SettlementView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
