//
//  ExpenseDetailView.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    @Environment(\.dismiss) private var dismiss
    
    private var totalAmount: Decimal {
        expense.payments?.allObjects
            .compactMap { $0 as? ExpensePayment }
            .reduce(0) { result, payment in
                result + (payment.amount?.decimalValue ?? 0)
            } ?? 0
    }
    
    private var payments: [ExpensePayment] {
        expense.payments?.allObjects
            .compactMap { $0 as? ExpensePayment } ?? []
    }
    
    private var participants: [ExpenseParticipant] {
        expense.participants?.allObjects
            .compactMap { $0 as? ExpenseParticipant } ?? []
    }
    
    private var categoryIcon: String {
        ExpenseCategory(rawValue: expense.category ?? "other")?.iconName ?? "ellipsis.circle.fill"
    }
    
    private var categoryName: String {
        ExpenseCategory(rawValue: expense.category ?? "other")?.localizedName ?? "その他"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if let imageData = expense.imageData,
                       let image = UIImage(data: imageData) {
                        receiptImageSection(image: image)
                    }
                    
                    paymentSection
                    participantSection
                    
                    if let tags = expense.tags, !tags.isEmpty {
                        tagsSection(tags: tags)
                    }
                }
                .padding()
            }
            .navigationTitle("支出詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.desc ?? "支出")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(categoryName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(expense.createdDate?.formatted(date: .abbreviated, time: .shortened) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("合計金額")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(totalAmount as NSDecimalNumber, formatter: currencyFormatter)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(expense.currency ?? "JPY")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func receiptImageSection(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("レシート")
                .font(.headline)
                .fontWeight(.semibold)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .shadow(radius: 2)
        }
    }
    
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支払者")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(payments, id: \.id) { payment in
                HStack {
                    Text(payment.payer?.name ?? "Unknown")
                        .font(.body)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\((payment.amount ?? NSDecimalNumber.zero), formatter: currencyFormatter)")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(expense.currency ?? "JPY")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private var participantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("参加者")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(participants, id: \.id) { participant in
                HStack {
                    Text(participant.member?.name ?? "Unknown")
                        .font(.body)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\((participant.shareAmount ?? NSDecimalNumber.zero), formatter: currencyFormatter)")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(expense.currency ?? "JPY")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private func tagsSection(tags: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("タグ")
                .font(.headline)
                .fontWeight(.semibold)
            
            let tagArray = tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(tagArray, id: \.self) { tag in
                    if !tag.isEmpty {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
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
    ExpenseDetailView(expense: Expense())
}
