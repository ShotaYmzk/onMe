//
//  GroupListView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import CoreData

struct GroupListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = GroupListViewModel()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TravelGroup.createdDate, ascending: false)],
        predicate: NSPredicate(format: "isActive == YES"),
        animation: .default
    )
    private var groups: FetchedResults<TravelGroup>
    
    @State private var showingCreateGroup = false
    
    var body: some View {
        NavigationView {
            VStack {
                if groups.isEmpty {
                    EmptyGroupsView {
                        showingCreateGroup = true
                    }
                } else {
                    List {
                        ForEach(groups, id: \.id) { group in
                            GroupRowView(group: group)
                                .onTapGesture {
                                    appState.selectGroup(group)
                                }
                        }
                        .onDelete(perform: deleteGroups)
                    }
                    .refreshable {
                        // プルトゥリフレッシュ処理
                        try? await Task.sleep(nanoseconds: 500_000_000)
                    }
                }
            }
            .navigationTitle("グループ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
        }
        .onAppear {
            viewModel.setContext(viewContext)
        }
    }
    
    private func deleteGroups(offsets: IndexSet) {
        withAnimation {
            offsets.map { groups[$0] }.forEach { group in
                group.isActive = false
            }
            
            do {
                try viewContext.save()
            } catch {
                // エラーハンドリング
                print("グループの削除に失敗しました: \(error)")
            }
        }
    }
}

struct GroupRowView: View {
    let group: TravelGroup
    @Environment(\.colorScheme) var colorScheme
    
    private var totalExpenses: Decimal {
        group.expenses?.allObjects
            .compactMap { $0 as? Expense }
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.amount } ?? 0
    }
    
    private var memberCount: Int {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .filter { $0.isActive }
            .count ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(group.name ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("\(memberCount)人")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(totalExpenses as NSDecimalNumber, formatter: currencyFormatter) \(group.currency ?? "JPY")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            if let budget = group.budget, budget.doubleValue > 0 {
                ProgressView(value: min(totalExpenses.doubleValue / budget.doubleValue, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: budgetColor))
                    .scaleEffect(y: 0.5)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.name ?? ""), \(memberCount)人, 支出合計 \(totalExpenses as NSDecimalNumber, formatter: currencyFormatter) \(group.currency ?? "JPY")")
    }
    
    private var budgetColor: Color {
        guard let budget = group.budget, budget.doubleValue > 0 else { return .blue }
        let ratio = totalExpenses.doubleValue / budget.doubleValue
        
        if ratio >= 1.0 {
            return .red
        } else if ratio >= 0.8 {
            return .orange
        } else {
            return .blue
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

struct EmptyGroupsView: View {
    let onCreateGroup: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("グループがありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("新しいグループを作成して\n旅行の支出管理を始めましょう")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onCreateGroup) {
                HStack {
                    Image(systemName: "plus")
                    Text("グループを作成")
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
    GroupListView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
