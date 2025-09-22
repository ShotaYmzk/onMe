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
    @State private var selectedGroupForManagement: TravelGroup?
    
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
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appState.selectGroup(group)
                                }
                            }) {
                                GroupRowView(group: group) {
                                    selectedGroupForManagement = group
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
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
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                if !groups.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                            .fontWeight(.medium)
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
            .sheet(item: $selectedGroupForManagement) { group in
                GroupMemberManagementView(group: group)
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
    let onManageMembers: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var totalExpenses: Decimal {
        group.expenses?.allObjects
            .compactMap { $0 as? Expense }
            .filter { $0.isActive }
            .reduce(0) { $0 + ($1.amount?.decimalValue ?? 0) } ?? 0
    }
    
    private var memberCount: Int {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .filter { $0.isActive }
            .count ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name ?? "")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Button(action: onManageMembers) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("\(memberCount)人")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if let createdDate = group.createdDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text(createdDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(totalExpenses as NSDecimalNumber, formatter: currencyFormatter)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(group.currency ?? "JPY")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            if let budget = group.budget, budget.doubleValue > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("予算進捗")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let ratio = NSDecimalNumber(decimal: totalExpenses).doubleValue / budget.doubleValue
                        Text("\(Int(ratio * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(budgetColor)
                    }
                    
                    ProgressView(value: min(NSDecimalNumber(decimal: totalExpenses).doubleValue / budget.doubleValue, 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: budgetColor))
                        .frame(height: 6)
                        .cornerRadius(3)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.name ?? ""), \(memberCount)人, 支出合計 \(totalExpenses as NSDecimalNumber, formatter: currencyFormatter) \(group.currency ?? "JPY")")
    }
    
    private var budgetColor: Color {
        guard let budget = group.budget, budget.doubleValue > 0 else { return .blue }
        let ratio = NSDecimalNumber(decimal: totalExpenses).doubleValue / budget.doubleValue
        
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
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    )
                
                VStack(spacing: 8) {
                    Text("グループがありません")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("新しいグループを作成して\n旅行の支出管理を始めましょう")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            
            Button(action: onCreateGroup) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("グループを作成")
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
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: true)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

#Preview {
    GroupListView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

