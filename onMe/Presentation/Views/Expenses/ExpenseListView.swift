//
//  ExpenseListView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import CoreData

struct ExpenseListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.createdDate, ascending: false)],
        predicate: NSPredicate(format: "isActive == YES"),
        animation: .default
    )
    private var expenses: FetchedResults<Expense>
    
    @State private var showingExpenseForm = false
    @State private var selectedExpense: Expense?
    
    var filteredExpenses: [Expense] {
        if let selectedGroup = appState.selectedGroup {
            return expenses.filter { $0.group == selectedGroup }
        }
        return Array(expenses)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if appState.selectedGroup == nil {
                    NoGroupSelectedView()
                } else if filteredExpenses.isEmpty {
                    EmptyExpensesView {
                        showingExpenseForm = true
                    }
                } else {
                    List {
                        ForEach(filteredExpenses, id: \.id) { expense in
                            ExpenseRowView(expense: expense)
                                .onTapGesture {
                                    selectedExpense = expense
                                }
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                    .refreshable {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                    }
                }
            }
            .navigationTitle(appState.selectedGroup?.name ?? "支出")
            .toolbar {
                if appState.selectedGroup != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingExpenseForm = true }) {
                            Image(systemName: "plus")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingExpenseForm) {
                if let group = appState.selectedGroup {
                    ExpenseFormView(group: group)
                }
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense)
            }
        }
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredExpenses[$0] }.forEach { expense in
                expense.isActive = false
            }
            
            do {
                try viewContext.save()
            } catch {
                print("支出の削除に失敗しました: \(error)")
            }
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    
    private var totalAmount: Decimal {
        expense.payments?.allObjects
            .compactMap { $0 as? ExpensePayment }
            .reduce(0) { $0 + $1.amount } ?? 0
    }
    
    private var categoryIcon: String {
        ExpenseCategory(rawValue: expense.category ?? "other")?.iconName ?? "ellipsis.circle.fill"
    }
    
    private var categoryName: String {
        ExpenseCategory(rawValue: expense.category ?? "other")?.localizedName ?? "その他"
    }
    
    var body: some View {
        HStack {
            Image(systemName: categoryIcon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.desc ?? "支出")
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(expense.createdDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(totalAmount as NSDecimalNumber, formatter: currencyFormatter)")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(expense.currency ?? "JPY")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(expense.desc ?? "支出"), \(categoryName), \(totalAmount as NSDecimalNumber, formatter: currencyFormatter) \(expense.currency ?? "JPY")")
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

struct NoGroupSelectedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("グループを選択してください")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("グループタブからグループを選択すると\nそのグループの支出を表示できます")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyExpensesView: View {
    let onCreateExpense: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("支出がありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("新しい支出を登録して\n旅行の記録を始めましょう")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onCreateExpense) {
                HStack {
                    Image(systemName: "plus")
                    Text("支出を登録")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    ExpenseListView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
