//
//  Recipe+Extended.swift
//  DataProvider
//
//  Created by Ben Davis on 3/18/26.
//

import Foundation
import SwiftData



    
public extension Recipe {
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

