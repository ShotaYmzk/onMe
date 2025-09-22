//
//  TravelSettleTests.swift
//  TravelSettleTests
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import XCTest
import CoreData
@testable import onMe

final class TravelSettleTests: XCTestCase {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        context = nil
    }
    
    // MARK: - Group Tests
    func testGroupCreation() throws {
        let group = TravelGroup(context: context)
        group.id = UUID()
        group.name = "Test Group"
        group.currency = "JPY"
        group.createdDate = Date()
        group.isActive = true
        
        try context.save()
        
        let fetchRequest: NSFetchRequest<TravelGroup> = TravelGroup.fetchRequest()
        let groups = try context.fetch(fetchRequest)
        
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.name, "Test Group")
        XCTAssertEqual(groups.first?.currency, "JPY")
        XCTAssertTrue(groups.first?.isActive == true)
    }
    
    func testGroupDeletion() throws {
        let group = TravelGroup(context: context)
        group.id = UUID()
        group.name = "Test Group"
        group.currency = "JPY"
        group.createdDate = Date()
        group.isActive = true
        
        try context.save()
        
        // ソフトデリート
        group.isActive = false
        try context.save()
        
        let fetchRequest: NSFetchRequest<TravelGroup> = TravelGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        let activeGroups = try context.fetch(fetchRequest)
        
        XCTAssertEqual(activeGroups.count, 0)
    }
    
    // MARK: - Member Tests
    func testMemberCreation() throws {
        let group = TravelGroup(context: context)
        group.id = UUID()
        group.name = "Test Group"
        group.currency = "JPY"
        group.createdDate = Date()
        group.isActive = true
        
        let member = GroupMember(context: context)
        member.id = UUID()
        member.name = "Test Member"
        member.createdDate = Date()
        member.isActive = true
        member.group = group
        
        try context.save()
        
        XCTAssertEqual(group.members?.count, 1)
        XCTAssertEqual(member.group, group)
        XCTAssertEqual(member.name, "Test Member")
    }
    
    // MARK: - Expense Tests
    func testExpenseCreation() throws {
        let group = TravelGroup(context: context)
        group.id = UUID()
        group.name = "Test Group"
        group.currency = "JPY"
        group.createdDate = Date()
        group.isActive = true
        
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.amount = NSDecimalNumber(value: 1000)
        expense.currency = "JPY"
        expense.desc = "Test Expense"
        expense.category = "food"
        expense.createdDate = Date()
        expense.isActive = true
        expense.group = group
        
        try context.save()
        
        XCTAssertEqual(group.expenses?.count, 1)
        XCTAssertEqual(expense.amount, NSDecimalNumber(value: 1000))
        XCTAssertEqual(expense.desc, "Test Expense")
        XCTAssertEqual(expense.category, "food")
    }
    
    // MARK: - Settlement Calculation Tests
    func testSettlementCalculation() throws {
        let useCase = SettlementCalculationUseCase()
        
        // テストデータの作成
        let member1Id = UUID()
        let member2Id = UUID()
        let member3Id = UUID()
        
        let members = [
            GroupMemberEntity(id: member1Id, name: "Member 1", groupId: UUID()),
            GroupMemberEntity(id: member2Id, name: "Member 2", groupId: UUID()),
            GroupMemberEntity(id: member3Id, name: "Member 3", groupId: UUID())
        ]
        
        let expense1 = ExpenseEntity(
            amount: 3000,
            currency: "JPY",
            category: .food,
            groupId: UUID(),
            payments: [ExpensePaymentEntity(amount: 3000, payerId: member1Id, expenseId: UUID())],
            participants: [
                ExpenseParticipantEntity(memberId: member1Id, expenseId: UUID(), shareAmount: 1000),
                ExpenseParticipantEntity(memberId: member2Id, expenseId: UUID(), shareAmount: 1000),
                ExpenseParticipantEntity(memberId: member3Id, expenseId: UUID(), shareAmount: 1000)
            ]
        )
        
        let group = GroupEntity(
            name: "Test Group",
            members: members,
            expenses: [expense1]
        )
        
        // 残高計算
        let balances = useCase.calculateMemberBalances(for: group)
        
        XCTAssertEqual(balances.count, 3)
        
        let member1Balance = balances.first { $0.memberId == member1Id }?.balance
        let member2Balance = balances.first { $0.memberId == member2Id }?.balance
        let member3Balance = balances.first { $0.memberId == member3Id }?.balance
        
        XCTAssertEqual(member1Balance, 2000) // 3000支払い - 1000負担 = +2000
        XCTAssertEqual(member2Balance, -1000) // 0支払い - 1000負担 = -1000
        XCTAssertEqual(member3Balance, -1000) // 0支払い - 1000負担 = -1000
        
        // 清算提案生成
        let suggestions = useCase.generateOptimalSettlements(from: balances, currency: "JPY")
        
        XCTAssertEqual(suggestions.count, 2)
        
        // Member2とMember3がそれぞれMember1に1000円ずつ支払う
        let suggestion1 = suggestions.first { $0.fromMemberId == member2Id }
        let suggestion2 = suggestions.first { $0.fromMemberId == member3Id }
        
        XCTAssertEqual(suggestion1?.toMemberId, member1Id)
        XCTAssertEqual(suggestion1?.amount, 1000)
        XCTAssertEqual(suggestion2?.toMemberId, member1Id)
        XCTAssertEqual(suggestion2?.amount, 1000)
    }
    
    // MARK: - OCR Tests
    func testOCRAmountExtraction() throws {
        let ocrService = ReceiptOCRService()
        
        let testTexts = [
            "合計 ¥1,500",
            "Total: $25.50",
            "金額: 3,000円",
            "Amount: ¥2,500",
            "小計 1,200円"
        ]
        
        let expectedAmounts: [Decimal] = [1500, 25.50, 3000, 2500, 1200]
        
        for (index, text) in testTexts.enumerated() {
            let amounts = ocrService.extractAmountFromText(text)
            XCTAssertFalse(amounts.isEmpty, "No amounts found in: \(text)")
            XCTAssertEqual(amounts.first, expectedAmounts[index], "Incorrect amount extracted from: \(text)")
        }
    }
    
    // MARK: - Performance Tests
    func testPerformanceGroupFetch() throws {
        // 大量のグループを作成
        for i in 0..<1000 {
            let group = TravelGroup(context: context)
            group.id = UUID()
            group.name = "Group \(i)"
            group.currency = "JPY"
            group.createdDate = Date()
            group.isActive = true
        }
        
        try context.save()
        
        measure {
            let fetchRequest: NSFetchRequest<TravelGroup> = TravelGroup.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isActive == YES")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
            
            do {
                let groups = try context.fetch(fetchRequest)
                XCTAssertEqual(groups.count, 1000)
            } catch {
                XCTFail("Failed to fetch groups: \(error)")
            }
        }
    }
    
    // MARK: - Data Encryption Tests
    func testDataEncryption() throws {
        let encryption = DataEncryption()
        let originalString = "Test sensitive data 秘密のデータ"
        
        // 暗号化
        let encryptedData = try encryption.encryptString(originalString)
        XCTAssertFalse(encryptedData.isEmpty)
        
        // 復号化
        let decryptedString = try encryption.decryptString(encryptedData)
        XCTAssertEqual(decryptedString, originalString)
        
        // バイナリデータのテスト
        let originalData = originalString.data(using: .utf8)!
        let encryptedBinaryData = try encryption.encryptData(originalData)
        let decryptedBinaryData = try encryption.decryptData(encryptedBinaryData)
        
        XCTAssertEqual(decryptedBinaryData, originalData)
    }
    
    // MARK: - Image Cache Tests
    func testImageCache() throws {
        let cache = ImageCache.shared
        let testImage = UIImage(systemName: "star.fill")!
        let testKey = "test_image"
        
        // 画像をキャッシュに保存
        cache.setImage(testImage, for: testKey)
        
        // キャッシュから画像を取得
        let cachedImage = cache.getImage(for: testKey)
        XCTAssertNotNil(cachedImage)
        
        // 画像を削除
        cache.removeImage(for: testKey)
        let removedImage = cache.getImage(for: testKey)
        XCTAssertNil(removedImage)
    }
}
