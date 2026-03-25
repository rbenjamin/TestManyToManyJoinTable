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
    
    
    static func removeExistingRelationshipValues(recipe: Recipe, fromKeyword keyword: Keyword, modelContext: ModelContext) {
        if let firstIndex = keyword.recipes?.firstIndex(of: recipe) {
            keyword.recipes?.remove(at: firstIndex)
        }
        if let firstIndex = recipe.keywords?.firstIndex(of: keyword) {
            recipe.keywords?.remove(at: firstIndex)
        }
        let recipeUUID = recipe.uuid
        let keywordUUID = keyword.uuid
        let predicate = #Predicate<RecipeKeywordIndex> { idx in
            return idx.recipeID == recipeUUID &&
                idx.keywordID == keywordUUID
        }
        do {
            let existing:[RecipeKeywordIndex] = try modelContext.fetch(
                FetchDescriptor<RecipeKeywordIndex>(predicate: predicate)
            )
            if !existing.isEmpty {
                for existing in existing {
                    modelContext.delete(existing)
                }
            }
            try modelContext.save()
        }
        catch let error {
            print("Failed to fetch RecipeKeywordIndex with error: \(error.localizedDescription)")
        }

    }
    
    static func validateExistingRelationshipValues(recipe: Recipe, fromKeyword keyword: Keyword, modelContext: ModelContext) {
        recipe.keywords?.append(keyword)
        let recipeUUID = recipe.uuid
        let keywordUUID = keyword.uuid
        
        let predicate = #Predicate<RecipeKeywordIndex> { idx in
            return idx.recipeID == recipeUUID &&
                idx.keywordID == keywordUUID
        }
        do {
            let existing:[RecipeKeywordIndex] = try modelContext.fetch(
                FetchDescriptor<RecipeKeywordIndex>(predicate: predicate)
            )
            
            if existing.isEmpty {
                let newIndex = RecipeKeywordIndex(recipeID: recipeUUID, keywordID: keywordUUID)
                modelContext.insert(newIndex)
            }
            try modelContext.save()

        }
        catch let error {
            print("Failed to fetch RecipeKeywordIndex with error: \(error.localizedDescription)")
        }
    }
    
    
    static func removeExistingRelationshipValues(keyword: Keyword, fromRecipe recipe: Recipe, modelContext: ModelContext) {
        
        if let firstIndex = recipe.keywords?.firstIndex(of: keyword) {
            recipe.keywords?.remove(at: firstIndex)
        }
        if let firstIndex = keyword.recipes?.firstIndex(of: recipe) {
            keyword.recipes?.remove(at: firstIndex)
        }
        let recipeUUID = recipe.uuid
        let keywordUUID = keyword.uuid
        let predicate = #Predicate<RecipeKeywordIndex> { idx in
            return idx.recipeID == recipeUUID &&
                idx.keywordID == keywordUUID
        }
        do {
            let existing:[RecipeKeywordIndex] = try modelContext.fetch(
                FetchDescriptor<RecipeKeywordIndex>(predicate: predicate)
            )
            if !existing.isEmpty {
                for existing in existing {
                    modelContext.delete(existing)
                }
            }
            try modelContext.save()
        }
        catch let error {
            print("Failed to fetch RecipeKeywordIndex with error: \(error.localizedDescription)")
        }

    }
    
    static func validateExistingRelationshipValues(keyword: Keyword, fromRecipe recipe: Recipe, modelContext: ModelContext) {
        recipe.keywords?.append(keyword)
        let keywordUUID = keyword.uuid
        let recipeUUID = recipe.uuid
        
        let predicate = #Predicate<RecipeKeywordIndex> { idx in
            return idx.recipeID == recipeUUID &&
                idx.keywordID == keywordUUID
        }
        do {
            let existing:[RecipeKeywordIndex] = try modelContext.fetch(
                FetchDescriptor<RecipeKeywordIndex>(predicate: predicate)
            )
            
            if existing.isEmpty {
                let newIndex = RecipeKeywordIndex(recipeID: recipeUUID, keywordID: keywordUUID)
                modelContext.insert(newIndex)
            }
            try modelContext.save()

        }
        catch let error {
            print("Failed to fetch RecipeKeywordIndex with error: \(error.localizedDescription)")
        }
    }
}

