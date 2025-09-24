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
    @State private var showingQuickCreateSheet = false
    @State private var quickGroupName = ""
    @State private var selectedGroupForSharing: TravelGroup?
    @State private var groupToDelete: TravelGroup?
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 統一ヘッダー
                UnifiedHeaderView(
                    title: "onMe",
                    subtitle: "旅行の割り勘を簡単に",
                    primaryAction: { showingQuickCreateSheet = true },
                    primaryActionTitle: "作成",
                    primaryActionIcon: "plus.circle.fill",
                    showStatistics: !groups.isEmpty,
                    statisticsData: !groups.isEmpty ? HeaderStatistics(items: [
                        HeaderStatistics.StatItem(
                            title: "グループ数",
                            value: "\(groups.count)",
                            icon: "person.3.fill",
                            color: Color.unifiedPrimary
                        ),
                        HeaderStatistics.StatItem(
                            title: "総支出",
                            value: formatTotalExpenses(),
                            icon: "creditcard.fill",
                            color: Color.unifiedSecondary
                        )
                    ]) : nil
                )
                
                // メインコンテンツ
                if groups.isEmpty {
                    EmptyGroupsView {
                        showingQuickCreateSheet = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(groups, id: \.id) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    ModernGroupCardView(group: group, onManageMembers: {
                                        selectedGroupForManagement = group
                                    }, onShare: {
                                        selectedGroupForSharing = group
                                    }, onDelete: {
                                        groupToDelete = group
                                        showingDeleteConfirmation = true
                                    })
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(action: {
                                        selectedGroupForManagement = group
                                    }) {
                                        Label("メンバー管理", systemImage: "person.badge.plus")
                                    }
                                    
                                    Button(action: {
                                        selectedGroupForSharing = group
                                    }) {
                                        Label("共有", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive, action: {
                                        groupToDelete = group
                                        showingDeleteConfirmation = true
                                    }) {
                                        Label("グループを削除", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        groupToDelete = group
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
            }
            .unifiedNavigationStyle()
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
            .sheet(isPresented: $showingQuickCreateSheet) {
                QuickCreateGroupView()
            }
            .sheet(item: $selectedGroupForManagement) { group in
                GroupMemberManagementView(group: group)
            }
            .sheet(item: $selectedGroupForSharing) { group in
                GroupSharingView(group: group)
            }
            .alert("グループを削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    if let group = groupToDelete {
                        deleteGroup(group)
                    }
                }
                Button("キャンセル", role: .cancel) {
                    groupToDelete = nil
                }
            } message: {
                if let group = groupToDelete {
                    Text("「\(group.name ?? "")」を削除しますか？\n\nこのグループに関連する支出や清算データもすべて削除されます。\n\nこの操作は元に戻せません。")
                }
            }
            .alert("エラー", isPresented: $showingDeleteError) {
                Button("OK") { }
            } message: {
                Text(deleteErrorMessage)
            }
        }
        .onAppear {
            viewModel.setContext(viewContext)
        }
    }
    
    private func deleteGroup(_ group: TravelGroup) {
        withAnimation(.easeInOut(duration: 0.3)) {
            do {
                try viewModel.deleteGroup(group)
                groupToDelete = nil
            } catch {
                deleteErrorMessage = "グループの削除に失敗しました: \(error.localizedDescription)"
                showingDeleteError = true
                groupToDelete = nil
            }
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
                print("グループの削除に失敗しました: \(error)")
            }
        }
    }
    
    private func formatTotalExpenses() -> String {
        let total = groups.reduce(0.0) { sum, group in
            let groupTotal = group.expenses?.allObjects
                .compactMap { $0 as? Expense }
                .filter { $0.isActive }
                .reduce(0.0) { $0 + ($1.amount?.doubleValue ?? 0) } ?? 0
            return sum + groupTotal
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "¥\(formatter.string(from: NSNumber(value: total)) ?? "0")"
    }
    
    @MainActor
    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        appState.loadExchangeRates()
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

// MARK: - 新しいコンポーネント

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ModernGroupCardView: View {
    let group: TravelGroup
    let onManageMembers: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
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
        VStack(spacing: 0) {
            // メインコンテンツ
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.name ?? "")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            Label("\(memberCount)人", systemImage: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let createdDate = group.createdDate {
                                Label(createdDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(totalExpenses as NSDecimalNumber, formatter: currencyFormatter)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(group.currency ?? "JPY")
                            .font(.caption2)
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
                    VStack(spacing: 6) {
                        HStack {
                            Text("予算進捗")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            let ratio = NSDecimalNumber(decimal: totalExpenses).doubleValue / budget.doubleValue
                            Text("\(Int(ratio * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(budgetColor)
                        }
                        
                        ProgressView(value: min(NSDecimalNumber(decimal: totalExpenses).doubleValue / budget.doubleValue, 1.0))
                            .progressViewStyle(LinearProgressViewStyle(tint: budgetColor))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
            }
            .padding(20)
            
            // アクションエリア
            HStack {
                Button(action: onManageMembers) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.caption)
                        Text("メンバー")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onShare) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                        Text("共有")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onDelete) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("削除")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 2)
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
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct QuickCreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    
    @State private var groupName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        )
                    
                    VStack(spacing: 8) {
                        Text("新しいグループを作成")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("グループ名を入力してすぐに始めましょう")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 16) {
                    TextField("例: 沖縄旅行、忘年会", text: $groupName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                        .textInputAutocapitalization(.words)
                    
                    Button(action: createQuickGroup) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("グループを作成")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    Button("詳細設定で作成") {
                        dismiss()
                        // 詳細作成画面を開く処理を追加
                    }
                    .foregroundColor(.blue)
                    .font(.body)
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 40)
            .navigationTitle("クイック作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func createQuickGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let newGroup = TravelGroup(context: viewContext)
        newGroup.id = UUID()
        newGroup.name = trimmedName
        newGroup.currency = appState.preferredCurrency
        newGroup.createdDate = Date()
        newGroup.isActive = true
        
        do {
            try viewContext.save()
            appState.selectGroup(newGroup)
            dismiss()
        } catch {
            alertMessage = "グループの作成に失敗しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct EmptyGroupsView: View {
    let onCreateGroup: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                // アニメーション付きアイコン
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.1), .blue.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: true)
                
                VStack(spacing: 12) {
                    Text("最初のグループを作成しましょう")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 8) {
                        Text("旅行やイベントでの支出を")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("簡単に管理・清算できます")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 16) {
                Button(action: onCreateGroup) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("グループを作成")
                            .fontWeight(.semibold)
                            .font(.body)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        FeatureItemView(
                            icon: "camera.fill",
                            title: "レシート読取",
                            description: "撮影で自動入力"
                        )
                        
                        FeatureItemView(
                            icon: "yensign.circle.fill",
                            title: "多通貨対応",
                            description: "海外旅行も安心"
                        )
                    }
                    
                    HStack(spacing: 16) {
                        FeatureItemView(
                            icon: "arrow.left.arrow.right.circle.fill",
                            title: "自動清算",
                            description: "最適ルート提案"
                        )
                        
                        FeatureItemView(
                            icon: "lock.shield.fill",
                            title: "安全・安心",
                            description: "データは端末内に"
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureItemView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct GroupMemberManagementView: View {
    let group: TravelGroup
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var newMemberName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var memberToDelete: GroupMember?
    @State private var showingDeleteConfirmation = false
    
    private var members: [GroupMember] {
        group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .filter { $0.isActive }
            .sorted { ($0.name ?? "") < ($1.name ?? "") } ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // メンバー追加セクション
                VStack(spacing: 16) {
                    HStack {
                        TextField("新しいメンバーの名前", text: $newMemberName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.words)
                        
                        Button(action: addMember) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newMemberName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                }
                
                // メンバーリスト
                if members.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("メンバーがいません")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("上のフィールドから新しいメンバーを追加してください")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(members, id: \.id) { member in
                            MemberRowView(member: member) {
                                memberToDelete = member
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("メンバー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            })
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .alert("メンバーを削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    if let member = memberToDelete {
                        deleteMember(member)
                    }
                }
                Button("キャンセル", role: .cancel) {
                    memberToDelete = nil
                }
            } message: {
                Text("「\(memberToDelete?.name ?? "")」を削除しますか？\n\nこの操作は元に戻せません。")
            }
        }
    }
    
    private func addMember() {
        let memberName = newMemberName.trimmingCharacters(in: .whitespaces)
        
        // 重複チェック
        if members.contains(where: { $0.name?.lowercased() == memberName.lowercased() }) {
            alertMessage = "同じ名前のメンバーが既に存在します"
            showingAlert = true
            return
        }
        
        let newMember = GroupMember(context: viewContext)
        newMember.id = UUID()
        newMember.name = memberName
        newMember.createdDate = Date()
        newMember.isActive = true
        newMember.group = group
        
        do {
            try viewContext.save()
            newMemberName = ""
        } catch {
            alertMessage = "メンバーの追加に失敗しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteMember(_ member: GroupMember) {
        // 論理削除（isActive = false）
        member.isActive = false
        
        do {
            try viewContext.save()
            memberToDelete = nil
        } catch {
            alertMessage = "メンバーの削除に失敗しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct MemberRowView: View {
    let member: GroupMember
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // アバター
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(member.name?.prefix(1) ?? "?").uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name ?? "")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                if let createdDate = member.createdDate {
                    Text("追加日: \(createdDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.body)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    GroupListView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


