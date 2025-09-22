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
                
                Section(header: Text("予算設定")) {
                    Toggle("予算を設定", isOn: $hasBudget)
                    
                    if hasBudget {
                        TextField("予算", text: $budgetString)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Section(header: Text("期間設定")) {
                    Toggle("期間を設定", isOn: $hasDateRange)
                    
                    if hasDateRange {
                        DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                        DatePicker("終了日", selection: $endDate, displayedComponents: .date)
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
                    .disabled(groupName.isEmpty)
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
