//
//  CreateGroupView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    
    @State private var groupName = ""
    @State private var selectedCurrency = "JPY"
    @State private var budgetString = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 1週間後
    @State private var hasBudget = false
    @State private var hasDateRange = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let currencies = ["JPY", "USD", "EUR", "GBP", "KRW", "CNY", "THB"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("グループ名", text: $groupName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("通貨", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                }
                
                Section(header: Text("予算設定"), footer: hasBudget ? Text("グループの予算を設定すると、支出状況を追跡できます") : nil) {
                    Toggle("予算を設定", isOn: $hasBudget)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if hasBudget {
                        HStack {
                            TextField("予算金額を入力", text: $budgetString)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text(selectedCurrency)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)
                        }
                    }
                }
                
                Section(header: Text("期間設定"), footer: hasDateRange ? Text("旅行やイベントの期間を設定できます") : nil) {
                    Toggle("期間を設定", isOn: $hasDateRange)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if hasDateRange {
                        DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        if startDate >= endDate {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("終了日は開始日より後に設定してください")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("新しいグループ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || (hasDateRange && startDate >= endDate))
                    .fontWeight(.semibold)
                }
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func createGroup() {
        let budget: Decimal? = hasBudget && !budgetString.isEmpty ? Decimal(string: budgetString) : nil
        let start: Date? = hasDateRange ? startDate : nil
        let end: Date? = hasDateRange ? endDate : nil
        
        // 日付の妥当性チェック
        if hasDateRange && startDate >= endDate {
            alertMessage = "終了日は開始日より後に設定してください"
            showingAlert = true
            return
        }
        
        let newGroup = TravelGroup(context: viewContext)
        newGroup.id = UUID()
        newGroup.name = groupName
        newGroup.currency = selectedCurrency
        newGroup.budget = budget as NSDecimalNumber?
        newGroup.startDate = start
        newGroup.endDate = end
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

#Preview {
    CreateGroupView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
