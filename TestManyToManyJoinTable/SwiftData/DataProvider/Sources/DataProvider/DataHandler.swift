//
//  DataHandler.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//



import SwiftData
import Foundation

@ModelActor
public actor DataHandler {
    
    public func fetchRecipes(descriptor: FetchDescriptor<Recipe>) async throws -> [RecipeSendable] {
        let recipes = try modelContext.fetch(descriptor)
        return recipes.map({ RecipeSendable(recipe: $0) })
    }
    
    public func fetchKeywords(descriptor: FetchDescriptor<Keyword>) async throws -> [KeywordSendable] {
        let keywords = try modelContext.fetch(descriptor)
        return keywords.map({ KeywordSendable(keyword: $0) })
    }
    
    public func fetchIndices(descriptor: FetchDescriptor<RecipeKeywordIndex>) async throws -> [RecipeKeywordIndexSendable] {
        let indices = try modelContext.fetch(descriptor)
        return indices.map({ RecipeKeywordIndexSendable(index: $0) })
    }
    
    
    
    public func recipeSearch(_ searchText: String) async throws -> [RecipeSendable] {
        let predicate = #Predicate<Recipe> { r in
            return r.label.localizedStandardContains(searchText)
        }
        let recipes = try modelContext.fetch(
            FetchDescriptor(predicate: predicate,
                            sortBy: [.init(\Recipe.timestamp)])
        )
        
        return recipes.map({ RecipeSendable(recipe: $0) })
    }
    
    public func keywordsForRecipe(recipeID: UUID) async throws -> [KeywordSendable] {
        let indexPredicate = #Predicate<RecipeKeywordIndex> { idx in
            return idx.recipeID == recipeID
        }
        var descriptor = FetchDescriptor(predicate: indexPredicate)
        descriptor.propertiesToFetch = [\RecipeKeywordIndex.keywordID]
        // fetch connecting indices
        let indices = try modelContext.fetch(descriptor)
        // get just the keyword uuids from these indices
        let validKeywords: Set<UUID> = Set(indices.map(\RecipeKeywordIndex.keywordID))
        
        // fetch only those keyword IDs
        let predicate = #Predicate<Keyword> { keyword in
            return validKeywords.contains(keyword.uuid)
        }
        // return sendable copy
        let results = try modelContext.fetch(
            FetchDescriptor(predicate: predicate,
                            sortBy: [.init(\Keyword.timestamp)])
        )
        return results.map({ KeywordSendable(keyword: $0) })
    }
    
    /// Used for search-filtering by-tag
    public func recipesForKeywords(
        keywordIDs: Set<UUID>,
        searchText: String?
    ) async throws -> [RecipeSendable] {
        // get matching keyword indices for these keywords
        let indexPredicate = #Predicate<RecipeKeywordIndex> { idx in
            return keywordIDs.contains(idx.keywordID)
        }
        
        let indexDescriptor = SortDescriptor<RecipeKeywordIndex>(\RecipeKeywordIndex.timestamp)
        
        var descriptor = FetchDescriptor(
            predicate: indexPredicate,
            sortBy: [indexDescriptor]
        )
        descriptor.propertiesToFetch = [\RecipeKeywordIndex.recipeID]
        let indices = try modelContext.fetch(descriptor)
        let recipeIDs = indices.map(\RecipeKeywordIndex.recipeID)
        
        var predicate: Predicate<Recipe>?
        if let searchText {
            predicate = #Predicate<Recipe> { r in
                return recipeIDs.contains(r.uuid) && r.label.localizedStandardContains(searchText)
            }
        }
        else {
            predicate = #Predicate<Recipe> { r in
                return recipeIDs.contains(r.uuid)
            }
        }
        let recipes = try modelContext.fetch(
            FetchDescriptor(
                predicate: predicate!,
                sortBy: [SortDescriptor<Recipe>(\Recipe.timestamp)]
            )
        )
        return recipes.map({ RecipeSendable(recipe: $0) })
    }
    
//    func recipesForKeywords(
//        keywords: [KeywordSendable],
//        searchText: String?
//    ) async throws -> [RecipeSendable] {
//        let keywords = Set(keywords)
//        let predicate = #Predicate<RecipeKeywordIndex> { idx in
//            return keywords.contains(idx.keywordID)
//        }
//        let indexDescriptor = SortDescriptor<RecipeKeywordIndex>(\RecipeKeywordIndex.timestamp)
//        
//        var descriptor = FetchDescriptor(
//            predicate: predicate,
//            sortBy: [indexDescriptor]
//        )
//        descriptor.propertiesToFetch = [\RecipeKeywordIndex.recipeID]
//        let indices = modelContext.fetch(descriptor)
//        var ids: Set<PersistentIdentifier> = []
//        
//        for index in indices {
//            ids.insert(index.recipeID)
//        }
//        var predicate: Predicate<Recipe>?
//        if let searchText {
//            predicate = #Predicate<Recipe> { r in
//                return ids.contains(r.persistentModelID) && r.label.localizedCaseInsensitiveContains(searchText)
//            }
//        }
//        else {
//            predicate = #Predicate<Recipe> { r in
//                return ids.contains(r.persistentModelID)
//            }
//        }
//        let recipes = modelContext.fetch(
//            FetchDescriptor(
//                predicate: predicate!,
//                sortBy: [SortDescriptor<Recipe>(\Recipe.timestamp)]
//            )
//        )
//        return recipes.map({ RecipeSendable(recipe: $0) })
//    }

}
