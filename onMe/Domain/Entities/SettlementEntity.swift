//
//  SettlementEntity.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import Foundation

struct SettlementEntity: Identifiable, Hashable {
    let id: UUID
    let amount: Decimal
    let payerId: UUID
    let receiverId: UUID
    let groupId: UUID
    let createdDate: Date
    let settledDate: Date?
    let isCompleted: Bool
    let note: String?
    
    init(id: UUID = UUID(),
         amount: Decimal,
         payerId: UUID,
         receiverId: UUID,
         groupId: UUID,
         createdDate: Date = Date(),
         settledDate: Date? = nil,
         isCompleted: Bool = false,
         note: String? = nil) {
        self.id = id
        self.amount = amount
        self.payerId = payerId
        self.receiverId = receiverId
        self.groupId = groupId
        self.createdDate = createdDate
        self.settledDate = settledDate
        self.isCompleted = isCompleted
        self.note = note
    }
}

struct SettlementSuggestion: Identifiable, Hashable {
    let id: UUID
    let fromMemberId: UUID
    let toMemberId: UUID
    let amount: Decimal
    let currency: String
    
    init(id: UUID = UUID(),
         fromMemberId: UUID,
         toMemberId: UUID,
         amount: Decimal,
         currency: String) {
        self.id = id
        self.fromMemberId = fromMemberId
        self.toMemberId = toMemberId
        self.amount = amount
        self.currency = currency
    }
}

struct MemberBalance: Identifiable, Hashable {
    let memberId: UUID
    let balance: Decimal // 正の値：受け取る側、負の値：支払う側
    
    var id: UUID { memberId }
    
    init(memberId: UUID, balance: Decimal) {
        self.memberId = memberId
        self.balance = balance
    }
}
