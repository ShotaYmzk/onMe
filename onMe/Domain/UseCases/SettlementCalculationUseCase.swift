//
//  SettlementCalculationUseCase.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import Foundation

protocol SettlementCalculationUseCaseProtocol {
    func calculateMemberBalances(for group: GroupEntity) -> [MemberBalance]
    func generateOptimalSettlements(from balances: [MemberBalance], currency: String) -> [SettlementSuggestion]
    func calculateTotalOwed(for memberId: UUID, in group: GroupEntity) -> Decimal
    func calculateTotalPaid(for memberId: UUID, in group: GroupEntity) -> Decimal
}

class SettlementCalculationUseCase: SettlementCalculationUseCaseProtocol {
    
    func calculateMemberBalances(for group: GroupEntity) -> [MemberBalance] {
        var balances: [UUID: Decimal] = [:]
        
        // 各メンバーの初期化
        for member in group.members {
            balances[member.id] = 0
        }
        
        // 各支出について計算
        for expense in group.expenses.filter({ $0.isActive }) {
            // 支払った金額を加算
            for payment in expense.payments {
                balances[payment.payerId, default: 0] += payment.amount
            }
            
            // 参加者の負担分を減算
            for participant in expense.participants {
                balances[participant.memberId, default: 0] -= participant.shareAmount
            }
        }
        
        return balances.map { MemberBalance(memberId: $0.key, balance: $0.value) }
    }
    
    func generateOptimalSettlements(from balances: [MemberBalance], currency: String) -> [SettlementSuggestion] {
        var settlements: [SettlementSuggestion] = []
        var creditors = balances.filter { $0.balance > 0 }.sorted { $0.balance > $1.balance }
        var debtors = balances.filter { $0.balance < 0 }.sorted { $0.balance < $1.balance }
        
        var creditorIndex = 0
        var debtorIndex = 0
        
        while creditorIndex < creditors.count && debtorIndex < debtors.count {
            let creditor = creditors[creditorIndex]
            let debtor = debtors[debtorIndex]
            
            let settlementAmount = min(creditor.balance, abs(debtor.balance))
            
            if settlementAmount > 0 {
                let settlement = SettlementSuggestion(
                    fromMemberId: debtor.memberId,
                    toMemberId: creditor.memberId,
                    amount: settlementAmount,
                    currency: currency
                )
                settlements.append(settlement)
                
                // 残高を更新
                creditors[creditorIndex] = MemberBalance(
                    memberId: creditor.memberId,
                    balance: creditor.balance - settlementAmount
                )
                debtors[debtorIndex] = MemberBalance(
                    memberId: debtor.memberId,
                    balance: debtor.balance + settlementAmount
                )
            }
            
            // 残高が0になったら次のメンバーへ
            if creditors[creditorIndex].balance <= 0 {
                creditorIndex += 1
            }
            if debtors[debtorIndex].balance >= 0 {
                debtorIndex += 1
            }
        }
        
        return settlements.filter { $0.amount > 0 }
    }
    
    func calculateTotalOwed(for memberId: UUID, in group: GroupEntity) -> Decimal {
        let balance = calculateMemberBalances(for: group)
            .first { $0.memberId == memberId }?.balance ?? 0
        return max(0, -balance) // 負の値（借金）を正の値として返す
    }
    
    func calculateTotalPaid(for memberId: UUID, in group: GroupEntity) -> Decimal {
        return group.expenses
            .filter { $0.isActive }
            .flatMap { $0.payments }
            .filter { $0.payerId == memberId }
            .reduce(0) { $0 + $1.amount }
    }
}
