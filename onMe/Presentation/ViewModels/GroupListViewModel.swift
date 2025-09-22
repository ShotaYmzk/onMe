//
//  GroupListViewModel.swift
//  TravelSettle
//
//  Created by 山﨑彰太 on 2025/09/22.
//

import Foundation
import CoreData
import Combine

@MainActor
class GroupListViewModel: ObservableObject {
    @Published var groups: [TravelGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var viewContext: NSManagedObjectContext?
    private var cancellables = Set<AnyCancellable>()
    
    func setContext(_ context: NSManagedObjectContext) {
        self.viewContext = context
        loadGroups()
    }
    
    func loadGroups() {
        guard let context = viewContext else { return }
        
        isLoading = true
        
        let request: NSFetchRequest<TravelGroup> = TravelGroup.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        request.predicate = NSPredicate(format: "isActive == YES")
        
        do {
            groups = try context.fetch(request)
        } catch {
            errorMessage = "グループの読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createGroup(name: String, currency: String, budget: Decimal?, startDate: Date?, endDate: Date?) throws {
        guard let context = viewContext else {
            throw GroupError.contextNotAvailable
        }
        
        let newGroup = TravelGroup(context: context)
        newGroup.id = UUID()
        newGroup.name = name
        newGroup.currency = currency
        newGroup.budget = budget as NSDecimalNumber?
        newGroup.startDate = startDate
        newGroup.endDate = endDate
        newGroup.createdDate = Date()
        newGroup.isActive = true
        
        try context.save()
        loadGroups()
    }
    
    func deleteGroup(_ group: TravelGroup) throws {
        guard let context = viewContext else {
            throw GroupError.contextNotAvailable
        }
        
        group.isActive = false
        try context.save()
        loadGroups()
    }
    
    func updateGroup(_ group: TravelGroup, name: String?, budget: Decimal?) throws {
        guard let context = viewContext else {
            throw GroupError.contextNotAvailable
        }
        
        if let name = name {
            group.name = name
        }
        
        if let budget = budget {
            group.budget = budget as NSDecimalNumber
        }
        
        try context.save()
        loadGroups()
    }
}

enum GroupError: LocalizedError {
    case contextNotAvailable
    case invalidData
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "データベースコンテキストが利用できません"
        case .invalidData:
            return "無効なデータです"
        case .saveFailed:
            return "保存に失敗しました"
        }
    }
}
