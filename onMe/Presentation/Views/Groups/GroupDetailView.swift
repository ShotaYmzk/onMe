//
//  GroupDetailView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import CoreData

struct GroupDetailView: View {
    let group: TravelGroup
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedTab: DetailTab = .overview
    @State private var showingExpenseForm = false
    @State private var showingMemberManagement = false
    @State private var showingSettlement = false
    
    private var members: [GroupMember] {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .filter { $0.isActive }
            .sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
    }
    
    private var expenses: [Expense] {
        group.expenses?.allObjects
            .compactMap { $0 as? Expense }
            .filter { $0.isActive }
            .sorted { $0.createdDate ?? Date() > $1.createdDate ?? Date() } ?? []
    }
    
    private var settlements: [Settlement] {
        group.settlements?.allObjects
            .compactMap { $0 as? Settlement }
            .sorted { $0.createdDate ?? Date() > $1.createdDate ?? Date() } ?? []
    }
    
    private var totalExpenses: Decimal {
        expenses.reduce(0) { $0 + ($1.amount?.decimalValue ?? 0) }
    }
    
    enum DetailTab: CaseIterable {
        case overview
        case expenses
        case settlements
        
        var title: String {
            switch self {
            case .overview:
                return "概要"
            case .expenses:
                return "支出"
            case .settlements:
                return "清算"
            }
        }
        
        var icon: String {
            switch self {
            case .overview:
                return "chart.pie.fill"
            case .expenses:
                return "creditcard.fill"
            case .settlements:
                return "arrow.left.arrow.right"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                GroupHeaderView(group: group, totalExpenses: totalExpenses)
                
                // タブセレクター
                TabSelectorView(selectedTab: $selectedTab)
                
                // コンテンツ
                TabView(selection: $selectedTab) {
                    OverviewTabView(
                        group: group,
                        members: members,
                        expenses: expenses,
                        totalExpenses: totalExpenses,
                        onAddExpense: { showingExpenseForm = true },
                        onManageMembers: { showingMemberManagement = true }
                    )
                    .tag(DetailTab.overview)
                    
                    ExpensesTabView(
                        expenses: expenses,
                        members: members,
                        onAddExpense: { showingExpenseForm = true }
                    )
                    .tag(DetailTab.expenses)
                    
                    SettlementsTabView(
                        settlements: settlements,
                        members: members,
                        onCalculateSettlement: { showingSettlement = true }
                    )
                    .tag(DetailTab.settlements)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(group.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingExpenseForm = true }) {
                            Label("支出を追加", systemImage: "plus.circle")
                        }
                        
                        Button(action: { showingMemberManagement = true }) {
                            Label("メンバー管理", systemImage: "person.badge.plus")
                        }
                        
                        Button(action: { showingSettlement = true }) {
                            Label("清算計算", systemImage: "equal.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingExpenseForm) {
                ExpenseFormView(preselectedGroup: group)
            }
            .sheet(isPresented: $showingMemberManagement) {
                GroupMemberManagementView(group: group)
            }
            .sheet(isPresented: $showingSettlement) {
                SettlementView()
            }
        }
    }
}

// MARK: - Header View
struct GroupHeaderView: View {
    let group: TravelGroup
    let totalExpenses: Decimal
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.name ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let createdDate = group.createdDate {
                        Label(createdDate.formatted(date: .abbreviated, time: .omitted), 
                              systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currencyFormatter.string(from: NSDecimalNumber(decimal: totalExpenses)) ?? "0")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(group.currency ?? "JPY")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
            
            // 予算プログレス（ある場合）
            if let budget = group.budget, budget.doubleValue > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("予算")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let ratio = NSDecimalNumber(decimal: totalExpenses).doubleValue / budget.doubleValue
                        Text("\(Int(ratio * 100))% (\(currencyFormatter.string(from: budget) ?? "0"))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(budgetColor)
                    }
                    
                    ProgressView(value: min(NSDecimalNumber(decimal: totalExpenses).doubleValue / budget.doubleValue, 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: budgetColor))
                        .frame(height: 6)
                        .cornerRadius(3)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var budgetColor: Color {
        guard let budget = group.budget, budget.doubleValue > 0 else { return .blue }
        let ratio = NSDecimalNumber(decimal: totalExpenses).doubleValue / budget.doubleValue
        
        if ratio >= 1.0 {
            return .red
        } else if ratio >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Tab Selector
struct TabSelectorView: View {
    @Binding var selectedTab: GroupDetailView.DetailTab
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(GroupDetailView.DetailTab.allCases, id: \.self) { tab in
                    TabSelectorButton(
                        tab: tab,
                        selectedTab: selectedTab,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            
            Rectangle()
                .fill(Color(UIColor.separator))
                .frame(height: 0.5)
        }
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Tab Selector Button
struct TabSelectorButton: View {
    let tab: GroupDetailView.DetailTab
    let selectedTab: GroupDetailView.DetailTab
    let onTap: () -> Void
    
    private var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .medium))
                    
                    Text(tab.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(isSelected ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Overview Tab
struct OverviewTabView: View {
    let group: TravelGroup
    let members: [GroupMember]
    let expenses: [Expense]
    let totalExpenses: Decimal
    let onAddExpense: () -> Void
    let onManageMembers: () -> Void
    
    private var recentExpenses: [Expense] {
        Array(expenses.prefix(5))
    }
    
    private var memberExpenseSummary: [(member: GroupMember, totalPaid: Decimal, totalOwed: Decimal)] {
        members.map { member in
            let totalPaid = member.expensePayments?.allObjects
                .compactMap { $0 as? ExpensePayment }
                .filter { $0.expense?.isActive == true }
                .reduce(0) { $0 + ($1.amount?.decimalValue ?? 0) } ?? 0
            
            let totalOwed = member.expenseParticipations?.allObjects
                .compactMap { $0 as? ExpenseParticipant }
                .filter { $0.expense?.isActive == true }
                .reduce(0) { $0 + ($1.shareAmount?.decimalValue ?? 0) } ?? 0
            
            return (member: member, totalPaid: totalPaid, totalOwed: totalOwed)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // 統計カード
                StatsCardsView(
                    memberCount: members.count,
                    expenseCount: expenses.count,
                    totalExpenses: totalExpenses,
                    currency: group.currency ?? "JPY"
                )
                
                // メンバー概要
                MembersSummaryView(
                    memberSummary: memberExpenseSummary,
                    currency: group.currency ?? "JPY",
                    onManageMembers: onManageMembers
                )
                
                // 最近の支出
                RecentExpensesView(
                    expenses: recentExpenses,
                    currency: group.currency ?? "JPY",
                    onAddExpense: onAddExpense
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Stats Cards
struct StatsCardsView: View {
    let memberCount: Int
    let expenseCount: Int
    let totalExpenses: Decimal
    let currency: String
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "メンバー",
                    value: "\(memberCount)人",
                    icon: "person.3.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "支出件数",
                    value: "\(expenseCount)件",
                    icon: "creditcard.fill",
                    color: .green
                )
            }
            
            StatCard(
                title: "総支出額",
                value: "\(currencyFormatter.string(from: NSDecimalNumber(decimal: totalExpenses)) ?? "0") \(currency)",
                icon: "yensign.circle.fill",
                color: .orange,
                isWide: true
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isWide: Bool
    
    init(title: String, value: String, icon: String, color: Color, isWide: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.isWide = isWide
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(isWide ? .title2 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Members Summary
struct MembersSummaryView: View {
    let memberSummary: [(member: GroupMember, totalPaid: Decimal, totalOwed: Decimal)]
    let currency: String
    let onManageMembers: () -> Void
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("メンバー概要")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("管理", action: onManageMembers)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if memberSummary.isEmpty {
                EmptyStateView(
                    icon: "person.3.fill",
                    title: "メンバーがいません",
                    description: "メンバーを追加してください",
                    buttonTitle: "メンバー追加",
                    buttonAction: onManageMembers
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(memberSummary, id: \.member.id) { summary in
                        MemberSummaryRow(
                            member: summary.member,
                            totalPaid: summary.totalPaid,
                            totalOwed: summary.totalOwed,
                            currency: currency
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MemberSummaryRow: View {
    let member: GroupMember
    let totalPaid: Decimal
    let totalOwed: Decimal
    let currency: String
    
    private var balance: Decimal {
        totalPaid - totalOwed
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // アバター
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(member.name?.prefix(1) ?? "?").uppercased())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("支払: \(currencyFormatter.string(from: NSDecimalNumber(decimal: totalPaid)) ?? "0")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("負担: \(currencyFormatter.string(from: NSDecimalNumber(decimal: totalOwed)) ?? "0")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(balance >= 0 ? "受取" : "支払")
                    .font(.caption2)
                    .foregroundColor(balance >= 0 ? .green : .red)
                
                Text(currencyFormatter.string(from: NSDecimalNumber(decimal: abs(balance))) ?? "0")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(balance >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recent Expenses
struct RecentExpensesView: View {
    let expenses: [Expense]
    let currency: String
    let onAddExpense: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近の支出")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("追加", action: onAddExpense)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if expenses.isEmpty {
                EmptyStateView(
                    icon: "creditcard.fill",
                    title: "支出がありません",
                    description: "最初の支出を記録してください",
                    buttonTitle: "支出追加",
                    buttonAction: onAddExpense
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(expenses, id: \.id) { expense in
                        ExpenseSummaryRow(expense: expense, currency: currency)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ExpenseSummaryRow: View {
    let expense: Expense
    let currency: String
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // カテゴリアイコン
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.desc ?? "支出")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let createdDate = expense.createdDate {
                        Text(createdDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let locationName = expense.locationName {
                        HStack(spacing: 2) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.blue)
                            Text(locationName)
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            Text(currencyFormatter.string(from: NSDecimalNumber(decimal: expense.amount?.decimalValue ?? 0)) ?? "0")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    private var categoryIcon: String {
        switch expense.category {
        case "food":
            return "fork.knife"
        case "transportation":
            return "car.fill"
        case "accommodation":
            return "bed.double.fill"
        case "entertainment":
            return "theatermasks.fill"
        case "shopping":
            return "bag.fill"
        default:
            return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let buttonAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: buttonAction) {
                Text(buttonTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Expenses Tab (簡易版)
struct ExpensesTabView: View {
    let expenses: [Expense]
    let members: [GroupMember]
    let onAddExpense: () -> Void
    
    var body: some View {
        VStack {
            if expenses.isEmpty {
                EmptyStateView(
                    icon: "creditcard.fill",
                    title: "支出がありません",
                    description: "最初の支出を記録してください",
                    buttonTitle: "支出追加",
                    buttonAction: onAddExpense
                )
            } else {
                List(expenses, id: \.id) { expense in
                    ExpenseDetailRow(expense: expense, members: members)
                }
            }
        }
    }
}

struct ExpenseDetailRow: View {
    let expense: Expense
    let members: [GroupMember]
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(expense.desc ?? "支出")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(currencyFormatter.string(from: NSDecimalNumber(decimal: expense.amount?.decimalValue ?? 0)) ?? "0")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 8) {
                if let createdDate = expense.createdDate {
                    Text(createdDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let locationName = expense.locationName {
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        Text(locationName)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
            }
            
            // 支払者と参加者の情報を表示
            if let payments = expense.payments?.allObjects as? [ExpensePayment], !payments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("支払者:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(payments, id: \.id) { payment in
                        if let payer = payment.payer {
                            Text("• \(payer.name ?? "") - \(currencyFormatter.string(from: NSDecimalNumber(decimal: payment.amount?.decimalValue ?? 0)) ?? "0")")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settlements Tab (簡易版)
struct SettlementsTabView: View {
    let settlements: [Settlement]
    let members: [GroupMember]
    let onCalculateSettlement: () -> Void
    
    var body: some View {
        VStack {
            if settlements.isEmpty {
                EmptyStateView(
                    icon: "arrow.left.arrow.right",
                    title: "清算がありません",
                    description: "清算を計算してください",
                    buttonTitle: "清算計算",
                    buttonAction: onCalculateSettlement
                )
            } else {
                List(settlements, id: \.id) { settlement in
                    SettlementRow(settlement: settlement)
                }
            }
        }
    }
}

struct SettlementRow: View {
    let settlement: Settlement
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(settlement.payer?.name ?? "")
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(settlement.receiver?.name ?? "")
                        .fontWeight(.semibold)
                }
                
                if let createdDate = settlement.createdDate {
                    Text(createdDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(currencyFormatter.string(from: NSDecimalNumber(decimal: settlement.amount?.decimalValue ?? 0)) ?? "0")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(settlement.isCompleted ? "完了" : "未完了")
                    .font(.caption)
                    .foregroundColor(settlement.isCompleted ? .green : .orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(settlement.isCompleted ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let group = TravelGroup(context: context)
    group.id = UUID()
    group.name = "サンプルグループ"
    group.currency = "JPY"
    group.createdDate = Date()
    group.isActive = true
    
    return GroupDetailView(group: group)
        .environmentObject(AppState())
        .environment(\.managedObjectContext, context)
}
