//
//  ExpenseFormView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI
import PhotosUI

struct ExpenseFormView: View {
    let group: TravelGroup
    
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
    
    private let ocrService = ReceiptOCRService()
    
    private var members: [GroupMember] {
        group.members?.allObjects
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
                basicInfoSection
                amountSection
                participantsSection
                payersSection
                if !splitEqually {
                    customSplitSection
                }
                receiptSection
                additionalInfoSection
            }
            .navigationTitle("支出を登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveExpense()
                    }
                    .disabled(!isValidForm)
                }
            }
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
                initializeSelections()
            }
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
                Text(group.currency ?? "JPY")
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
                HStack {
                    Button(action: {
                        toggleMemberSelection(member.id!)
                    }) {
                        HStack {
                            Image(systemName: selectedMembers.contains(member.id!) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedMembers.contains(member.id!) ? .blue : .secondary)
                            Text(member.name ?? "")
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
            
            Toggle("均等割り", isOn: $splitEqually)
        }
    }
    
    private var payersSection: some View {
        Section(header: Text("支払者")) {
            ForEach(members, id: \.id) { member in
                HStack {
                    Text(member.name ?? "")
                    Spacer()
                    TextField("0", value: Binding(
                        get: { payerSelections[member.id!] ?? 0 },
                        set: { payerSelections[member.id!] = $0 }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text(group.currency ?? "JPY")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var customSplitSection: some View {
        Section(header: Text("個別負担額")) {
            ForEach(Array(selectedMembers), id: \.self) { memberId in
                if let member = members.first(where: { $0.id == memberId }) {
                    HStack {
                        Text(member.name ?? "")
                        Spacer()
                        TextField("0", value: Binding(
                            get: { customSplits[memberId] ?? 0 },
                            set: { customSplits[memberId] = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text(group.currency ?? "JPY")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
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
    
    private var additionalInfoSection: some View {
        Section(header: Text("追加情報")) {
            TextField("タグ（カンマ区切り）", text: $tags)
                .textInputAutocapitalization(.none)
        }
    }
    
    private var isValidForm: Bool {
        !description.isEmpty && totalAmount > 0 && !selectedMembers.isEmpty && totalPayerAmount == totalAmount
    }
    
    private func initializeSelections() {
        selectedMembers = Set(members.compactMap { $0.id })
        
        // 最初のメンバーがすべて支払うように初期化
        if let firstMember = members.first {
            payerSelections[firstMember.id!] = totalAmount
        }
    }
    
    private func toggleMemberSelection(_ memberId: UUID) {
        if selectedMembers.contains(memberId) {
            selectedMembers.remove(memberId)
        } else {
            selectedMembers.insert(memberId)
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
        let expense = Expense(context: viewContext)
        expense.id = UUID()
        expense.amount = totalAmount as NSDecimalNumber
        expense.currency = group.currency
        expense.desc = description
        expense.category = selectedCategory.rawValue
        expense.createdDate = Date()
        expense.isActive = true
        expense.group = group
        
        if let imageData = receiptImage?.jpegData(compressionQuality: 0.8) {
            expense.imageData = imageData
        }
        
        if !tags.isEmpty {
            expense.tags = tags
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
}

#Preview {
    ExpenseFormView(group: TravelGroup())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
