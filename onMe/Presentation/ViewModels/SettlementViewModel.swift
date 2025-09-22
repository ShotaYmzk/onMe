//
//  SettlementViewModel.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import Foundation
import CoreData
import Combine

@MainActor
class SettlementViewModel: ObservableObject {
    @Published var memberBalances: [MemberBalance] = []
    @Published var settlementSuggestions: [SettlementSuggestion] = []
    @Published var completedSettlements: [Settlement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let settlementCalculationUseCase = SettlementCalculationUseCase()
    private var cancellables = Set<AnyCancellable>()
    
    func loadSettlements(for group: TravelGroup) {
        isLoading = true
        
        // GroupEntityに変換
        let groupEntity = convertToGroupEntity(group)
        
        // 残高計算
        memberBalances = settlementCalculationUseCase.calculateMemberBalances(for: groupEntity)
        
        // 清算提案生成
        settlementSuggestions = settlementCalculationUseCase.generateOptimalSettlements(
            from: memberBalances,
            currency: group.currency ?? "JPY"
        )
        
        // 完了済み清算の取得
        loadCompletedSettlements(for: group)
        
        isLoading = false
    }
    
    private func loadCompletedSettlements(for group: TravelGroup) {
        completedSettlements = group.settlements?.allObjects
            .compactMap { $0 as? Settlement }
            .filter { $0.isCompleted }
            .sorted { $0.settledDate ?? Date.distantPast > $1.settledDate ?? Date.distantPast } ?? []
    }
    
    private func convertToGroupEntity(_ group: TravelGroup) -> GroupEntity {
        let members = group.members?.allObjects
            .compactMap { $0 as? GroupMember }
            .filter { $0.isActive }
            .map { convertToMemberEntity($0) } ?? []
        
        let expenses = group.expenses?.allObjects
            .compactMap { $0 as? Expense }
            .filter { $0.isActive }
            .map { convertToExpenseEntity($0) } ?? []
        
        let settlements = group.settlements?.allObjects
            .compactMap { $0 as? Settlement }
            .map { convertToSettlementEntity($0) } ?? []
        
        return GroupEntity(
            id: group.id ?? UUID(),
            name: group.name ?? "",
            currency: group.currency ?? "JPY",
            createdDate: group.createdDate ?? Date(),
            startDate: group.startDate,
            endDate: group.endDate,
            budget: group.budget as? Decimal,
            isActive: group.isActive,
            members: members,
            expenses: expenses,
            settlements: settlements
        )
    }
    
    private func convertToMemberEntity(_ member: GroupMember) -> GroupMemberEntity {
        return GroupMemberEntity(
            id: member.id ?? UUID(),
            name: member.name ?? "",
            avatarData: member.avatarData,
            createdDate: member.createdDate ?? Date(),
            isActive: member.isActive,
            groupId: member.group?.id ?? UUID()
        )
    }
    
    private func convertToExpenseEntity(_ expense: Expense) -> ExpenseEntity {
        let payments = expense.payments?.allObjects
            .compactMap { $0 as? ExpensePayment }
            .map { convertToPaymentEntity($0) } ?? []
        
        let participants = expense.participants?.allObjects
            .compactMap { $0 as? ExpenseParticipant }
            .map { convertToParticipantEntity($0) } ?? []
        
        return ExpenseEntity(
            id: expense.id ?? UUID(),
            amount: expense.amount as? Decimal ?? 0,
            currency: expense.currency ?? "JPY",
            description: expense.desc,
            category: ExpenseCategory(rawValue: expense.category ?? "other") ?? .other,
            createdDate: expense.createdDate ?? Date(),
            imageData: expense.imageData,
            tags: expense.tags?.components(separatedBy: ",") ?? [],
            groupId: expense.group?.id ?? UUID(),
            payments: payments,
            participants: participants,
            isActive: expense.isActive
        )
    }
    
    private func convertToPaymentEntity(_ payment: ExpensePayment) -> ExpensePaymentEntity {
        return ExpensePaymentEntity(
            id: payment.id ?? UUID(),
            amount: payment.amount as? Decimal ?? 0,
            payerId: payment.payer?.id ?? UUID(),
            expenseId: payment.expense?.id ?? UUID()
        )
    }
    
    private func convertToParticipantEntity(_ participant: ExpenseParticipant) -> ExpenseParticipantEntity {
        return ExpenseParticipantEntity(
            id: participant.id ?? UUID(),
            memberId: participant.member?.id ?? UUID(),
            expenseId: participant.expense?.id ?? UUID(),
            shareAmount: participant.shareAmount as? Decimal ?? 0
        )
    }
    
    private func convertToSettlementEntity(_ settlement: Settlement) -> SettlementEntity {
        return SettlementEntity(
            id: settlement.id ?? UUID(),
            amount: settlement.amount as? Decimal ?? 0,
            payerId: settlement.payer?.id ?? UUID(),
            receiverId: settlement.receiver?.id ?? UUID(),
            groupId: settlement.group?.id ?? UUID(),
            createdDate: settlement.createdDate ?? Date(),
            settledDate: settlement.settledDate,
            isCompleted: settlement.isCompleted,
            note: settlement.note
        )
    }
    
    func markSettlementAsCompleted(_ suggestion: SettlementSuggestion, in group: TravelGroup, context: NSManagedObjectContext, note: String? = nil) throws {
        let settlement = Settlement(context: context)
        settlement.id = UUID()
        settlement.amount = suggestion.amount as NSDecimalNumber
        settlement.createdDate = Date()
        settlement.settledDate = Date()
        settlement.isCompleted = true
        settlement.group = group
        settlement.note = note
        
        // メンバーを検索して設定
        let members = group.members?.allObjects.compactMap { $0 as? GroupMember } ?? []
        settlement.payer = members.first { $0.id == suggestion.fromMemberId }
        settlement.receiver = members.first { $0.id == suggestion.toMemberId }
        
        try context.save()
        
        // データを再読み込み
        loadSettlements(for: group)
    }
}
