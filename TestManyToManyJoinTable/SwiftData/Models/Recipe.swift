//
//  Recipe.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import Foundation
import SwiftData

@Model
final class Recipe {
    var timestamp: Date = Date()
    var uuid: UUID = UUID()
    var label: String = ""
    
    @Relationship(deleteRule: .nullify, inverse: \Keyword.recipes)
    var keywords: [Keyword]? = []

    init() {
    }
}

struct RecipeSendable: Codable, Sendable, Equatable, Comparable, Identifiable, Hashable {
    let timestamp: Date
    let uuid: UUID
    let label: String
    let keywords: [PersistentIdentifier]
    let keywordsLabel: String
    let persistentModelID: PersistentIdentifier
    
    var id: UUID {
        return uuid
    }
    
    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
    init(recipe: Recipe) {
        self.timestamp = recipe.timestamp
        self.uuid = recipe.uuid
        self.label = recipe.label
        self.persistentModelID = keyword.persistentModelID
        let words = recipe.keywords
        
        self.keywords = words?.compactMap(\.persistentModelID) ?? []
        self.keywordsLabel = words?.compactMap(\.label)?.joined(separator: ", ") ?? ""
    }
}


extension Recipe {
    // Fetch Request for single recipe
    static func fetch(recipeID: PersistentIdentifier,
                      modelContext: ModelContext) throws -> Recipe? {
        let predicate = #Predicate<Recipe> { r in
            return r.persistentModelID == recipeID
        }
        return try modelContext.fetch(FetchDescriptor<Recipe>(predicate: predicate)).first
    }
    
    static func fetch(recipeUUID: UUID, modelContext: ModelContext) throws -> Recipe? {
        let predicate = #Predicate<Recipe> { r in
            return r.uuid == recipeUUID
        }
        return try modelContext.fetch(FetchDescriptor<Recipe>(predicate: predicate)).first
    }
    
    static func fetchDescriptorForUUID(_ uuid: UUID) -> FetchDescriptor<Recipe> {
        
        let predicate = #Predicate<Recipe> { recipe in
            return recipe.uuid == uuid
        }
        return FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\Recipe.timestamp,
                                     order: .forward)
            ])
    }

}
