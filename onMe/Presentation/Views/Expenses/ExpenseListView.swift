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
                    NoGroupSelectedView {
                        showingExpenseForm = true
                    }
                } else if filteredExpenses.isEmpty {
                    EmptyExpensesView {
                        showingExpenseForm = true
                    }
                } else {
                    List {
                        ForEach(filteredExpenses, id: \.id) { expense in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedExpense = expense
                                }
                            }) {
                                ExpenseRowView(expense: expense)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteExpenses)
                    }
                    .refreshable {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                    }
                }
            }
            .navigationTitle(appState.selectedGroup?.name ?? "支出")
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingExpenseForm = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                if appState.selectedGroup != nil && !filteredExpenses.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                            .fontWeight(.medium)
                    }
                }
            })
            .sheet(isPresented: $showingExpenseForm) {
                ExpenseFormView(preselectedGroup: appState.selectedGroup)
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
            .reduce(0) { $0 + ($1.amount?.decimalValue ?? 0) } ?? 0
    }
    
    private var categoryIcon: String {
        ExpenseCategory(rawValue: expense.category ?? "other")?.iconName ?? "ellipsis.circle.fill"
    }
    
    private var categoryName: String {
        ExpenseCategory(rawValue: expense.category ?? "other")?.localizedName ?? "その他"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.title3)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.desc ?? "支出")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Text(categoryName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(8)
                    
                    Text(expense.createdDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(totalAmount as NSDecimalNumber, formatter: currencyFormatter)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(expense.currency ?? "JPY")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
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
    let onCreateExpense: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("グループを選択してください")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("グループタブからグループを選択すると\nそのグループの支出を表示できます")
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
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

struct EmptyExpensesView: View {
    let onCreateExpense: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                    )
                
                VStack(spacing: 8) {
                    Text("支出がありません")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("新しい支出を登録して\n旅行の記録を始めましょう")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            
            Button(action: onCreateExpense) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("支出を登録")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

#Preview {
    ExpenseListView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
