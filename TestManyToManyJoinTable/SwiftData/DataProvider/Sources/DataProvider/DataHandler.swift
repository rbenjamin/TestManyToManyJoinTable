//
//  DataHandler.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//



import SwiftData
import Foundation
import OSLog


@ModelActor
public actor DataHandler {
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "DataProvider.DataHandler")
    
    // MARK: - Basic Fetch (Sendable) -
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
    
    // MARK: - Recipe-Keyword Link Validation -
    
    public func validateRecipeToIndices() async throws {
        // current recipes - if there are bad indices, they should represent recipes that don't exist in the database
        var descriptor = FetchDescriptor<Recipe>()
        descriptor.propertiesToFetch = [\Recipe.uuid]
        let recipes = try modelContext.fetch(descriptor)
        let recipeIds = Set(recipes.map(\Recipe.uuid))
        
        let invalidLinksPredicate = #Predicate<RecipeKeywordIndex> { idx in
            return recipeIds.contains(idx.recipeID) == false
        }
        let invalidLinks = try  modelContext.fetch(FetchDescriptor(predicate: invalidLinksPredicate))
        log.debug("There are \(invalidLinks.count) invalid recipe-keyword links. Removing invalid indices.")
        if invalidLinks.count > 0 {
            try modelContext.delete(model: RecipeKeywordIndex.self, where: invalidLinksPredicate)
            try modelContext.save()
        }
    }
    
    
    public func validateKeywordToIndices() async throws {
        // current keywords - if there are bad indices, they should reference keywords that don't exist in the database

        var descriptor = FetchDescriptor<Keyword>()
        descriptor.propertiesToFetch = [\Keyword.uuid]
        let keywords = try modelContext.fetch(descriptor)
        let keywordIds = Set(keywords.map(\Keyword.uuid))
        
        let invalidLinksPredicate = #Predicate<RecipeKeywordIndex> { idx in
            return keywordIds.contains(idx.keywordID) == false
        }
        let invalidLinks = try  modelContext.fetch(FetchDescriptor(predicate: invalidLinksPredicate))
        log.debug("There are \(invalidLinks.count) invalid keyword-recipe links. Removing invalid indices.")
        if invalidLinks.count > 0 {
            try modelContext.delete(model: RecipeKeywordIndex.self, where: invalidLinksPredicate)
            try modelContext.save()
        }
    }
    
    public func createMissingIndices() async throws {
        let descr = FetchDescriptor<Recipe>()
        let recipes = try modelContext.fetch(descr)
        for recipe in recipes {
            let rID = recipe.uuid
            let predicate = #Predicate<RecipeKeywordIndex> { idx in
                return idx.recipeID == rID
            }
            if try modelContext.fetchCount(FetchDescriptor(predicate: predicate)) == 0 {
                for keyword in recipe.keywords ?? [] {
                    let kID = keyword.uuid
                    let index = RecipeKeywordIndex(recipeID: rID, keywordID: kID)
                    modelContext.insert(index)
                }
                if modelContext.hasChanges {
                    try modelContext.save()
                }
            }
        }
        
    }
    
    // MARK: - Search -
    
    public func recipeSearch(_ searchText: String) async throws -> [RecipeSendable] {
        let predicate = #Predicate<Recipe> { r in
            return r.label.localizedStandardContains(searchText)
        }
        let recipes = try modelContext.fetch(
            FetchDescriptor(predicate: predicate,
                            sortBy: [.init(\Recipe.timestamp, order: .reverse)])
        )
        
        return recipes.map({ RecipeSendable(recipe: $0) })
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
        
        
        var descriptor = FetchDescriptor(
            predicate: indexPredicate
        )
        descriptor.propertiesToFetch = [\RecipeKeywordIndex.recipeID]
        let indices = try modelContext.fetch(descriptor)
        
        let grouped = Dictionary(grouping: indices, by: \.recipeID)

        let requiredCount = keywordIDs.count

        let filteredRecipeIDs: Set<UUID> = Set(
            grouped.compactMap { (recipeID, matches) in
                let uniqueMatches = Set(matches.map(\.keywordID))
                return uniqueMatches.count == requiredCount ? recipeID : nil
            }
        )
        
        var predicate: Predicate<Recipe>?
        if let searchText {
            predicate = #Predicate<Recipe> { r in
                return filteredRecipeIDs.contains(r.uuid) && r.label.localizedStandardContains(searchText)
            }
        }
        else {
            predicate = #Predicate<Recipe> { r in
                return filteredRecipeIDs.contains(r.uuid)
            }
        }
        let recipes = try modelContext.fetch(
            FetchDescriptor(
                predicate: predicate!,
                sortBy: [SortDescriptor<Recipe>(\Recipe.timestamp, order: .reverse)]
            )
        )
        return recipes.map({ RecipeSendable(recipe: $0) })
    }
    
    // MARK: - Fetch Recipe's Keywords -
    
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
    
    // MARK: - Deletion -
    
    public func deleteRecipes(uuids: Set<UUID>) throws {
        
        let recipeRemoval = #Predicate<Recipe> { r in
            return uuids.contains(r.uuid)
        }
        let indexRemoval = #Predicate<RecipeKeywordIndex> { idx in
            return uuids.contains(idx.recipeID)
        }
        try modelContext.delete(model: Recipe.self, where: recipeRemoval)
        try modelContext.delete(model: RecipeKeywordIndex.self, where: indexRemoval)
        
        try modelContext.save()
    }
    
    public func deleteKeywords(uuids: Set<UUID>) throws {
        
        let indexRemoval = #Predicate<RecipeKeywordIndex> { idx in
            return uuids.contains(idx.keywordID)
        }
        let keyRemoval = #Predicate<Keyword> { key in
            return uuids.contains(key.uuid)
        }
        try modelContext.delete(model: Keyword.self, where: keyRemoval)
        try modelContext.delete(model: RecipeKeywordIndex.self, where: indexRemoval)
        
        try modelContext.save()
    }
    
    public func delete(recipeID: PersistentIdentifier) throws {
        if let recipe = try Recipe.fetch(recipeID: recipeID, modelContext: modelContext) {
            let recipeUUID = recipe.uuid
            
            let indexPredicate = #Predicate<RecipeKeywordIndex> { idx in
                return idx.recipeID == recipeUUID
            }
            try modelContext.delete(model: RecipeKeywordIndex.self, where: indexPredicate)
            modelContext.delete(recipe)
            
            try modelContext.save()
        }
    }
    
    public func delete(_ recipe: RecipeSendable) throws {
        try delete(recipeID: recipe.persistentModelID)
    }
    
    public func delete(keywordID: PersistentIdentifier) throws {
        if let keyword = try Keyword.fetch(keywordID: keywordID, modelContext: modelContext) {
            let keywordUUID = keyword.uuid
            
            let indexPredicate = #Predicate<RecipeKeywordIndex> { idx in
                return idx.keywordID == keywordUUID
            }
            try modelContext.delete(model: RecipeKeywordIndex.self, where: indexPredicate)
            modelContext.delete(keyword)
            
            try modelContext.save()
        }
    }
    
    public func delete(_ keyword: KeywordSendable) throws {
        try delete(keywordID: keyword.persistentModelID)
    }
  
    // MARK: - Test Data -
    
    /// Creates default recipes and assigns them to random keywords.
    public func createDefaultRecipes() async throws {
        let labels: [String] = ["Fiery Vindaloo Chili Recipe • 4★ • 2 hrs 15 min", "Spring Onion and Cheese Potato Cake, Two Ways Recipe", "Couscous Risotto with Chicken and Spinach | America\'s Test Kitchen", "Mustard-Braised Pork Recipe", "Test Recipe", "Irish Stew Recipe", "Braised Chicken With Rosemary and Crispy Artichokes Recipe", "Classic Pavlova | OpenStove", "Homemade Almond Cookies | OpenStove", "One-Pot Chicken and Lentils  Recipe", "Parmesan Garlic Butter Crusted Halibut", "Flourless Chocolate Wave Cake", "Classic Pavlova", "Homemade Pound Cake with Almonds", "Carrot, White Bean, and Ginger Soup – Rancho Gordo", "French Macarons", "Dan Dan Noodles Recipe", "Broccoli and Potato Soup Recipe", "Alexandra Stafford\'s Slow Cooker Gigante Beans – Rancho Gordo", "Asha\'s Hearty Lentil & Mushroom Soup – Rancho Gordo", "French Lentil Soup with Leeks and Lemon – Rancho Gordo", "Spicy Caramelized Leeks with Fresh Lemon - Alison Roman", "Spicy Peanut and Pumpkin Soup Recipe (with Video)", "Chicken and Sausage Gumbo Recipe", "Chicken And Wild Rice With Fennel  Recipe", "Pasta Pesto Soup With Turkey and Spinach Recipe", "Sheet-Pan Scallion Shrimp With Crispy Rice Recipe", "Green Bagna Cauda With Tiny White Beans", "Green Goddess Roasted Chicken Recipe", "Chili Beans", "Olive Oil-Roasted Chicken & Chickpeas", "Polenta With Fresh Corn", "Spiced, Butter-Roasted Carrots With Walnuts", "Saland-e Nakhod (Chickpea Yogurt Stew) Recipe", "Chickpea Vegetable Soup With Parmesan, Rosemary and Lemon Recipe", "Almost Cassoulet", "Buttered Tomato Soup with Lentils & Fennel", "Spicy Pork Soup With Pasta & Parmesan", "Slow Cooker Cilantro-Lime Chicken and Rice Recipe", "Air-Fryer Spicy Chicken Wings Recipe", "Chicken Tikka Masala Recipe (with Video)", "Warming Tomato and Pinto Bean Soup Recipe", "Spiced Zucchini Soup - Alison Roman", "One-Pot French Onion Rigatoni Recipe", "Macaroni and Peas Recipe", "Chili Of Champions", "Slow Cooker Chicken Diavolo With Orzo Recipe", "Creamy Orzo, Butter Beans and Greens Recipe", "Creamy Lasagna Soup Recipe", "Roasted Cauliflower and Garlic Soup Recipe", "Crispy Coconut Salmon Recipe", "Creamy Chickpea Spinach Masala With Tadka Recipe (with Video)", "Baked Potato Soup Recipe", "Potato Soup Recipe", "Todo Plans", "One-Pot Beans, Greens and Grains Recipe", "Berbere Meatballs Recipe", "Lemony Chicken-Feta Meatball Soup With Spinach Recipe", "Roasted Broccoli and Whipped Tofu With Chile Crisp Crunch Recipe", "Honey Garlic Shrimp Recipe", "One-Pot Roman Chicken Cacciatore With Potatoes Recipe", "Crustless Zucchini and Feta Quiche Recipe", "Best Edible Cookie Dough Recipe", "Okra Gumbo", "PEPPERPOT", "Cheesy Cauliflower Nests Recipe", "Crustless Egg and Cheese Quiche Recipe", "Brussels Sprouts Buried in Cream Recipe", "Roasted Spiced Squash With Whipped Feta and Pistachios Recipe", "Sautéed Chicken à la Ronsard", "Soupe Bonne Femme — French Cooking Academy", "St. Louis Gooey Butter Cake", "Gooey Butter Cake", "Rosemary White Bean Soup", "Haricots Verts with Shallots, Capers, Preserved Lemon"]
        let descriptor = FetchDescriptor<Keyword>()
        let keywords = try modelContext.fetch(descriptor)
        
        var count = 1
        for label in labels {
            if count % 6 == 0 {
                try modelContext.save()
                await Task.yield()
            }
            let recipe = Recipe()
            recipe.label = label
            modelContext.insert(recipe)
            let randomNumber = Int.random(in: 0..<4)
            // associate these recipes with some random keywords
            for _ in 0 ..< randomNumber {
                if let randomKeyword1 = keywords.randomElement() {
                    recipe.keywords?.append(randomKeyword1)
                    
                    let index = RecipeKeywordIndex(recipeID: recipe.uuid, keywordID: randomKeyword1.uuid)
                    modelContext.insert(index)
                }
            }
            count += 1
        }
        try modelContext.save()
        
    }
    

}
