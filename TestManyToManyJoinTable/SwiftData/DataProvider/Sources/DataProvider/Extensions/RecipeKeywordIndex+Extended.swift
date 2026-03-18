//
//  RecipeKeywordIndex+Extended.swift
//  DataProvider
//
//  Created by Ben Davis on 3/18/26.
//

import SwiftData
import Foundation


public extension RecipeKeywordIndex {
    static func fetch(persistentID: PersistentIdentifier, modelContext: ModelContext) throws -> RecipeKeywordIndex? {
        let predicate = #Predicate<RecipeKeywordIndex> { k in
            return k.persistentModelID == persistentID
        }
        return try modelContext.fetch(FetchDescriptor<RecipeKeywordIndex>(predicate: predicate)).first
    }
}

