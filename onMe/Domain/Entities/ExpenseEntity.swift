//
//  ExpenseEntity.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import Foundation

struct ExpenseEntity: Identifiable, Hashable {
    let id: UUID
    let amount: Decimal
    let currency: String
    let description: String?
    let category: ExpenseCategory
    let createdDate: Date
    let imageData: Data?
    let tags: [String]
    let groupId: UUID
    let payments: [ExpensePaymentEntity]
    let participants: [ExpenseParticipantEntity]
    let isActive: Bool
    
    init(id: UUID = UUID(),
         amount: Decimal,
         currency: String,
         description: String? = nil,
         category: ExpenseCategory,
         createdDate: Date = Date(),
         imageData: Data? = nil,
         tags: [String] = [],
         groupId: UUID,
         payments: [ExpensePaymentEntity] = [],
         participants: [ExpenseParticipantEntity] = [],
         isActive: Bool = true) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.description = description
        self.category = category
        self.createdDate = createdDate
        self.imageData = imageData
        self.tags = tags
        self.groupId = groupId
        self.payments = payments
        self.participants = participants
        self.isActive = isActive
    }
}

struct ExpensePaymentEntity: Identifiable, Hashable {
    let id: UUID
    let amount: Decimal
    let payerId: UUID
    let expenseId: UUID
    
    init(id: UUID = UUID(),
         amount: Decimal,
         payerId: UUID,
         expenseId: UUID) {
        self.id = id
        self.amount = amount
        self.payerId = payerId
        self.expenseId = expenseId
    }
}

struct ExpenseParticipantEntity: Identifiable, Hashable {
    let id: UUID
    let memberId: UUID
    let expenseId: UUID
    let shareAmount: Decimal
    
    init(id: UUID = UUID(),
         memberId: UUID,
         expenseId: UUID,
         shareAmount: Decimal) {
        self.id = id
        self.memberId = memberId
        self.expenseId = expenseId
        self.shareAmount = shareAmount
    }
}

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case food = "food"
    case transportation = "transportation"
    case accommodation = "accommodation"
    case entertainment = "entertainment"
    case shopping = "shopping"
    case other = "other"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .food:
            return NSLocalizedString("expense.category.food", value: "食事", comment: "")
        case .transportation:
            return NSLocalizedString("expense.category.transportation", value: "交通費", comment: "")
        case .accommodation:
            return NSLocalizedString("expense.category.accommodation", value: "宿泊費", comment: "")
        case .entertainment:
            return NSLocalizedString("expense.category.entertainment", value: "娯楽", comment: "")
        case .shopping:
            return NSLocalizedString("expense.category.shopping", value: "ショッピング", comment: "")
        case .other:
            return NSLocalizedString("expense.category.other", value: "その他", comment: "")
        }
    }
    
    var iconName: String {
        switch self {
        case .food:
            return "fork.knife"
        case .transportation:
            return "car.fill"
        case .accommodation:
            return "bed.double.fill"
        case .entertainment:
            return "theatermasks.fill"
        case .shopping:
            return "bag.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
}
