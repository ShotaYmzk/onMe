//
//  ExpenseFormView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import PhotosUI
import CoreData

struct ExpenseFormView: View {
    let group: TravelGroup?
    let preselectedGroup: TravelGroup?
    
    init(group: TravelGroup? = nil, preselectedGroup: TravelGroup? = nil) {
        self.group = group
        self.preselectedGroup = preselectedGroup
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var description = ""
    @State private var amountString = ""
    @State private var selectedCategory = ExpenseCategory.food
    @State private var selectedMembers: Set<UUID> = []
    @State private var payerSelections: [UUID: Decimal] = [:]
    @State private var splitEqually = true
    @State private var customSplits: [UUID: Decimal] = [:]
    @State private var tags = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var showingCamera = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isProcessingOCR = false
    @State private var selectedGroupId: UUID?
    @State private var selectedLocationName: String?
    @State private var selectedLatitude: Double?
    @State private var selectedLongitude: Double?
    
    private let ocrService = ReceiptOCRService()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TravelGroup.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == YES"),
        animation: .default
    )
    private var availableGroups: FetchedResults<TravelGroup>
    
    private var currentGroup: TravelGroup? {
        if let group = group {
            return group
        }
        if let selectedGroupId = selectedGroupId {
            return availableGroups.first { $0.id == selectedGroupId }
        }
        if let preselectedGroup = preselectedGroup {
            return preselectedGroup
        }
        return availableGroups.first
    }
    
    private var members: [GroupMember] {
        currentGroup?.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .filter { $0.isActive } ?? []
    }
    
    private var totalAmount: Decimal {
        Decimal(string: amountString) ?? 0
    }
    
    private var totalPayerAmount: Decimal {
        payerSelections.values.reduce(0, +)
    }
    
    var body: some View {
        NavigationView {
            Form {
                if group == nil {
                    groupSelectionSection
                }
                basicInfoSection
                amountSection
                participantsSection
                payersSection
                if !splitEqually {
                    customSplitSection
                }
                receiptSection
                locationSection
                additionalInfoSection
            }
            .navigationTitle("支出を登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveExpense()
                    }
                    .disabled(!isValidForm)
                }
            })
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: selectedPhoto) { newValue in
                Task {
                    if let newValue = newValue {
                        await loadImage(from: newValue)
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    receiptImage = image
                    Task {
                        await processReceiptOCR(image)
                    }
                }
            }
        .onAppear {
            if group == nil && preselectedGroup != nil {
                selectedGroupId = preselectedGroup?.id
            }
            initializeSelections()
        }
        .onChange(of: amountString) { _ in
            updatePayerSelections()
        }
        .onChange(of: selectedGroupId) { _ in
            initializeSelections()
        }
        }
    }
    
    private var groupSelectionSection: some View {
        Section(header: Text("グループ選択")) {
            Picker("グループ", selection: $selectedGroupId) {
                ForEach(availableGroups, id: \.id) { group in
                    HStack {
                        Text(group.name ?? "")
                        Spacer()
                        Text(group.currency ?? "JPY")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }.tag(group.id as UUID?)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var basicInfoSection: some View {
        Section(header: Text("基本情報")) {
            TextField("支出の説明", text: $description)
                .textInputAutocapitalization(.sentences)
            
            Picker("カテゴリ", selection: $selectedCategory) {
                ForEach(ExpenseCategory.allCases) { category in
                    HStack {
                        Image(systemName: category.iconName)
                        Text(category.localizedName)
                    }.tag(category)
                }
            }
        }
    }
    
    private var amountSection: some View {
        Section(header: Text("金額")) {
                    HStack {
                        TextField("金額", text: $amountString)
                            .keyboardType(.decimalPad)
                        Text(currentGroup?.currency ?? "JPY")
                            .foregroundColor(.secondary)
                    }
            
            if totalPayerAmount != totalAmount && totalAmount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("支払額の合計が一致しません")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private var participantsSection: some View {
        Section(header: Text("参加者")) {
            ForEach(members, id: \.id) { member in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        toggleMemberSelection(member.id!)
                    }
                }) {
                    HStack {
                        Image(systemName: selectedMembers.contains(member.id!) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedMembers.contains(member.id!) ? .blue : .secondary)
                            .font(.title3)
                        
                        Text(member.name ?? "")
                            .foregroundColor(.primary)
                            .font(.body)
                        
                        Spacer()
                        
                        if selectedMembers.contains(member.id!) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Toggle("均等割り", isOn: $splitEqually)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
    }
    
    private var payersSection: some View {
        Section(header: Text("支払者"), footer: VStack(alignment: .leading, spacing: 4) {
            Text("各メンバーが実際に支払った金額を入力してください")
            if totalPayerAmount != totalAmount && totalAmount > 0 {
                Text("⚠️ 支払額の合計が支出総額と一致していません")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }) {
            ForEach(members, id: \.id) { member in
                HStack {
                    Text(member.name ?? "")
                        .font(.body)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        TextField("0", value: Binding(
                            get: { payerSelections[member.id!] ?? 0 },
                            set: { newValue in
                                payerSelections[member.id!] = newValue
                            }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                        
                        Text(currentGroup?.currency ?? "JPY")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                    }
                }
                .padding(.vertical, 2)
            }
            
            HStack {
                Text("合計支払額")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalPayerAmount as NSDecimalNumber, formatter: currencyFormatter)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(totalPayerAmount == totalAmount ? .green : .red)
                    
                    if totalAmount > 0 {
                        Text("目標: \(totalAmount as NSDecimalNumber, formatter: currencyFormatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(totalPayerAmount == totalAmount && totalAmount > 0 ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(totalPayerAmount == totalAmount && totalAmount > 0 ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
            )
            
            if totalAmount > 0 && totalPayerAmount != totalAmount {
                Button(action: distributePaymentEqually) {
                    HStack {
                        Image(systemName: "equal.circle.fill")
                        Text("支払を等分する")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
    }
    
    private var customSplitSection: some View {
        Section(header: Text("個別負担額"), footer: Text("各メンバーの負担額を個別に設定できます")) {
            ForEach(Array(selectedMembers), id: \.self) { memberId in
                if let member = members.first(where: { $0.id == memberId }) {
                    HStack {
                        Text(member.name ?? "")
                            .font(.body)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            TextField("0", value: Binding(
                                get: { customSplits[memberId] ?? 0 },
                                set: { customSplits[memberId] = $0 }
                            ), format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.trailing)
                            
                            Text(currentGroup?.currency ?? "JPY")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            let totalCustomSplit = customSplits.values.reduce(0, +)
            if totalCustomSplit > 0 && totalAmount > 0 {
                HStack {
                    Text("合計負担額")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(totalCustomSplit as NSDecimalNumber, formatter: currencyFormatter)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(totalCustomSplit == totalAmount ? .green : .red)
                }
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var receiptSection: some View {
        Section(header: Text("レシート")) {
            HStack {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                        Text("写真を選択")
                    }
                }
                
                Spacer()
                
                Button(action: { showingCamera = true }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("カメラで撮影")
                    }
                }
            }
            
            if let receiptImage = receiptImage {
                Image(uiImage: receiptImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            }
            
            if isProcessingOCR {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("レシートを解析中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var locationSection: some View {
        Section {
            LocationPickerView(
                selectedLocationName: $selectedLocationName,
                selectedLatitude: $selectedLatitude,
                selectedLongitude: $selectedLongitude
            )
        }
    }
    
    private var additionalInfoSection: some View {
        Section(header: Text("追加情報")) {
            TextField("タグ（カンマ区切り）", text: $tags)
                .textInputAutocapitalization(.none)
        }
    }
    
    private var isValidForm: Bool {
        let hasDescription = !description.isEmpty
        let hasValidAmount = totalAmount > 0
        let hasParticipants = !selectedMembers.isEmpty
        let paymentMatches = totalPayerAmount == totalAmount
        let customSplitValid = splitEqually || customSplits.values.reduce(0, +) == totalAmount
        let hasValidGroup = currentGroup != nil
        
        return hasDescription && hasValidAmount && hasParticipants && paymentMatches && customSplitValid && hasValidGroup
    }
    
    private func initializeSelections() {
        selectedMembers = Set(members.compactMap { $0.id })
        
        // すべてのメンバーの支払額を0で初期化
        for member in members {
            if let memberId = member.id {
                payerSelections[memberId] = 0
            }
        }
        
        // 最初のメンバーがすべて支払うように初期化（金額が入力されている場合のみ）
        if let firstMember = members.first, let firstMemberId = firstMember.id {
            payerSelections[firstMemberId] = totalAmount
        }
    }
    
    private func toggleMemberSelection(_ memberId: UUID) {
        if selectedMembers.contains(memberId) {
            selectedMembers.remove(memberId)
        } else {
            selectedMembers.insert(memberId)
        }
    }
    
    private func updatePayerSelections() {
        // 金額が変更されたときに、既存の支払者の金額を調整
        if totalAmount > 0 {
            let currentPayersWithAmount = payerSelections.filter { $0.value > 0 }
            
            if currentPayersWithAmount.count == 1, let payerId = currentPayersWithAmount.first?.key {
                // 単一の支払者の場合、その人に全額を設定
                payerSelections[payerId] = totalAmount
            } else if currentPayersWithAmount.isEmpty, let firstMember = members.first, let firstMemberId = firstMember.id {
                // 支払者がいない場合、最初のメンバーに全額を設定
                payerSelections[firstMemberId] = totalAmount
            }
        } else {
            // 金額が0の場合、すべての支払額をリセット
            for memberId in payerSelections.keys {
                payerSelections[memberId] = 0
            }
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        
        receiptImage = image
        await processReceiptOCR(image)
    }
    
    private func processReceiptOCR(_ image: UIImage) async {
        isProcessingOCR = true
        
        do {
            let result = try await ocrService.extractTextFromImage(image)
            
            await MainActor.run {
                if let firstAmount = result.detectedAmounts.first {
                    amountString = String(describing: firstAmount)
                }
                
                if description.isEmpty {
                    // 簡単な説明を生成
                    let text = result.fullText.lowercased()
                    if text.contains("restaurant") || text.contains("レストラン") {
                        description = "レストラン"
                        selectedCategory = .food
                    } else if text.contains("taxi") || text.contains("タクシー") {
                        description = "タクシー"
                        selectedCategory = .transportation
                    }
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "OCR処理に失敗しました: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        
        isProcessingOCR = false
    }
    
    private func saveExpense() {
        guard let currentGroup = currentGroup else {
            alertMessage = "グループが選択されていません"
            showingAlert = true
            return
        }
        
        let expense = Expense(context: viewContext)
        expense.id = UUID()
        expense.amount = totalAmount as NSDecimalNumber
        expense.currency = currentGroup.currency
        expense.desc = description
        expense.category = selectedCategory.rawValue
        expense.createdDate = Date()
        expense.isActive = true
        expense.group = currentGroup
        
        if let imageData = receiptImage?.jpegData(compressionQuality: 0.8) {
            expense.imageData = imageData
        }
        
        if !tags.isEmpty {
            expense.tags = tags
        }
        
        // 位置情報を保存
        if let locationName = selectedLocationName {
            expense.locationName = locationName
        }
        if let latitude = selectedLatitude {
            expense.locationLatitude = latitude
        }
        if let longitude = selectedLongitude {
            expense.locationLongitude = longitude
        }
        
        // 支払情報を保存
        for (memberId, amount) in payerSelections where amount > 0 {
            if let member = members.first(where: { $0.id == memberId }) {
                let payment = ExpensePayment(context: viewContext)
                payment.id = UUID()
                payment.amount = amount as NSDecimalNumber
                payment.expense = expense
                payment.payer = member
            }
        }
        
        // 参加者情報を保存
        let shareAmount = splitEqually ? totalAmount / Decimal(selectedMembers.count) : 0
        
        for memberId in selectedMembers {
            if let member = members.first(where: { $0.id == memberId }) {
                let participant = ExpenseParticipant(context: viewContext)
                participant.id = UUID()
                participant.expense = expense
                participant.member = member
                participant.shareAmount = (splitEqually ? shareAmount : (customSplits[memberId] ?? 0)) as NSDecimalNumber
            }
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "支出の保存に失敗しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func distributePaymentEqually() {
        guard totalAmount > 0 else { return }
        
        let activeMembers = members.filter { member in
            guard let memberId = member.id else { return false }
            return selectedMembers.contains(memberId)
        }
        
        guard !activeMembers.isEmpty else { return }
        
        let amountPerPerson = totalAmount / Decimal(activeMembers.count)
        
        // すべての支払額をリセット
        for memberId in payerSelections.keys {
            payerSelections[memberId] = 0
        }
        
        // 選択されたメンバーに等分して支払額を設定
        for member in activeMembers {
            if let memberId = member.id {
                payerSelections[memberId] = amountPerPerson
            }
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

#Preview {
    ExpenseFormView(preselectedGroup: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
