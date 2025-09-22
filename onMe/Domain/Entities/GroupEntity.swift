//
//  GroupEntity.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import Foundation

struct GroupEntity: Identifiable, Hashable {
    let id: UUID
    let name: String
    let currency: String
    let createdDate: Date
    let startDate: Date?
    let endDate: Date?
    let budget: Decimal?
    let isActive: Bool
    let members: [GroupMemberEntity]
    let expenses: [ExpenseEntity]
    let settlements: [SettlementEntity]
    
    init(id: UUID = UUID(),
         name: String,
         currency: String = "JPY",
         createdDate: Date = Date(),
         startDate: Date? = nil,
         endDate: Date? = nil,
         budget: Decimal? = nil,
         isActive: Bool = true,
         members: [GroupMemberEntity] = [],
         expenses: [ExpenseEntity] = [],
         settlements: [SettlementEntity] = []) {
        self.id = id
        self.name = name
        self.currency = currency
        self.createdDate = createdDate
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.isActive = isActive
        self.members = members
        self.expenses = expenses
        self.settlements = settlements
    }
    
    var totalExpenses: Decimal {
        expenses.filter { $0.isActive }.reduce(0) { $0 + $1.amount }
    }
    
    var remainingBudget: Decimal? {
        guard let budget = budget else { return nil }
        return budget - totalExpenses
    }
    
    var isOverBudget: Bool {
        guard let remaining = remainingBudget else { return false }
        return remaining < 0
    }
}

struct GroupMemberEntity: Identifiable, Hashable {
    let id: UUID
    let name: String
    let avatarData: Data?
    let createdDate: Date
    let isActive: Bool
    let groupId: UUID
    
    init(id: UUID = UUID(),
         name: String,
         avatarData: Data? = nil,
         createdDate: Date = Date(),
         isActive: Bool = true,
         groupId: UUID) {
        self.id = id
        self.name = name
        self.avatarData = avatarData
        self.createdDate = createdDate
        self.isActive = isActive
        self.groupId = groupId
    }
}
