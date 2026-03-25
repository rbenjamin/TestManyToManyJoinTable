//
//  Keyword+Extended.swift
//  DataProvider
//
//  Created by Ben Davis on 3/18/26.
//

import SwiftData
import Foundation



public extension Keyword {
    
    static func delete(keywordID: UUID, in context: ModelContext) throws {
        let predicate = #Predicate<RecipeKeywordIndex> { idx in
            return idx.keywordID == keywordID
        }
        try context.delete(model: RecipeKeywordIndex.self, where: predicate)
        if context.hasChanges {
            try context.save()
        }
    }
    
    static var allKeywordsDescriptor: FetchDescriptor<Keyword> {
        return FetchDescriptor<Keyword>(sortBy: [.init(\Keyword.label, order: .forward)])
    }
    static func fetch(keywordID: PersistentIdentifier, modelContext: ModelContext) throws -> Keyword? {
        return try modelContext.existingModel(for: keywordID)
    }
    
    static func fetch(keywordUUID: UUID, modelContext: ModelContext) throws -> Keyword? {
        let predicate = #Predicate<Keyword> { k in
            return k.uuid == keywordUUID
        }
        return try modelContext.fetch(FetchDescriptor<Keyword>(predicate: predicate)).first
    }
}

