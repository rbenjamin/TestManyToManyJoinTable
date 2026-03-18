//
//  DataHandler.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//



import SwiftData
import Foundation

@ModelActor
actor DataHandler {
    
    func fetchRecipes(descriptor: FetchDescriptor<Recipe>) async throws -> [RecipeSendable] {
        let recipes = try await modelContext.fetch(descriptor)
        return recipes?.map({ RecipeSendable(recipe: $0) })
    }
    
    func fetchKeywords(descriptor: FetchDescriptor<Keyword>) async throws -> [KeywordSendable] {
        let keywords = try await modelContext.fetch(descriptor)
        return keywords?.map({ KeywordSendable(keyword: $0) })
    }
    
    func fetchIndices(descriptor: FetchDescriptor<RecipeKeywordIndex>) async throws -> [RecipeKeywordIndexSendable] {
        let indices = try await modelContext.fetch(descriptor)
        return indices?.map({ RecipeKeywordIndexSendable(index: $0) })
    }
    
    func recipeSearch(_ searchText: String) async throws -> [RecipeSendable] {
        let predicate = #Predicate<Recipe> { r in
            return r.label.localizedCaseInsensitiveContains(searchText)
        }
        let recipes = try modelContext.fetch(FetchDescriptor(predicate: predicate, sortBy: [.init(\Recipe.timestamp)]))
        return recipes?.map({ RecipeSendable(recipe: $0) })
    }
    
    func recipesForKeywords(
        keywordIDs: Set<PersistentIdentifier>,
        searchText: String?
    ) async throws -> [RecipeSendable] {

        let predicate = #Predicate<RecipeKeywordIndex> { idx in
            return keywordIDs.contains(idx.keywordID)
        }
        let indexDescriptor = SortDescriptor<RecipeKeywordIndex>(\RecipeKeywordIndex.timestamp)
        
        var descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [indexDescriptor]
        )
        descriptor.propertiesToFetch = [\RecipeKeywordIndex.recipeID]
        let indices = modelContext.fetch(descriptor)
        var ids: Set<PersistentIdentifier> = []
        
        for index in indices {
            ids.insert(index.recipeID)
        }
        var predicate: Predicate<Recipe>?
        if let searchText {
            predicate = #Predicate<Recipe> { r in
                return ids.contains(r.persistentModelID) && r.label.localizedCaseInsensitiveContains(searchText)
            }
        }
        else {
            predicate = #Predicate<Recipe> { r in
                return ids.contains(r.persistentModelID)
            }
        }
        let recipes = modelContext.fetch(
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
