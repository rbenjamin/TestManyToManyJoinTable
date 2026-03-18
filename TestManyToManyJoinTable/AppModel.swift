//
//  AppModel.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//
import SwiftUI
import SwiftData


@Observable final class AppModel {
    var recipes: [RecipeSendable] = []
    var keywords: [KeywordSendable] = []
    var searchController: TokenSearchBarUIController = .init(searchText: "", tokens: [])
    var filteredTokens: [SearchTokenValue] = []
    var allTokens: [SearchTokenValue] = []
    
    var tokenListVisible: Bool = false
    
    var searchText: String {
        searchController.searchText
    }
    
    var searchTokens: String {
        searchController.tokens
    }
    
    @ObservationIgnored let log = Logger(subsystem: "TestManyToManyJoinTable", category: "AppModel")
    
    func performSearch(
        searchText: String,
        tokens: Set<SearchTokenValue>,
        container: ModelContainer,
    ) async {
        let index = searchText.firstIndex(of: "#")
        guard index != nil else {
            try? await Task.sleep(nanoseconds: 100_000_000)
            let searchResults: [RecipeSendable]? = try await Task.detached { [searchText, tokens, container] in
                return self.search(searchText: searchText, tokens: tokens, container: container)
            }.value
            if let searchResults {
                withAnimation {
                    recipes = searchResults
                }
            }
            
            return
        }
        withAnimation(.spring) {
            tokenListVisible = true
        }
        let endIndex = searchText.endIndex
        guard let index,
              index < endIndex else {
            return
        }
        let letterIndex = searchText.index(after: index)
        let subword = searchText[letterIndex...].lowercased()
         
         
        guard !subword.isEmpty else {
             withAnimation(.spring) {
                 filteredTokens = allTokens
             }
             return
        }
        
        if filteredTokens.count == 1 &&
            searchText.count > 1 &&
            searchText[searchText.index(before: endIndex)].isWhitespace {
                 
            withAnimation(.spring) {
                searchController.tokens.insert(
                    filteredTokens[0]
                )
                filteredTokens = allTokens
                searchController.searchText = ""
                searchController.showTokenList = false
            }
        }
        let filtered = allTokens.filter({ tkn in
            if case .keyword(let keyword) = tkn {
                return keyword.lowercasedLabel.hasPrefix(subword)
            }
        })
        withAnimation(.spring) {
            filteredTokens = filtered
        }


    }
    
    private nonisolated func search(
         searchText: String,
         tokens: Set<SearchTokenValue>,
         container: ModelContainer,
    ) async -> [RecipeSendable]? {
        let handler = DataHandler(modelContainer: container)
        let tokensIsEmpty = tokens.isEmpty
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespaces)
        // no tokens or tags (just sort)
        if tokensIsEmpty && trimmedSearchText.isEmpty {
            return recipes.sorted()
        }
        
        // No tags being filtered -- just a text search
        if tokensIsEmpty {
            return handler.recipeSearch(searchText)
        }
        
        var keywordIDs = Set<PersistentIdentifier>()
        
        for token in tokens {
            if case .keyword(let key) = token {
                keywordIDs.insert(key.persistentModelID)
            }
        }
        // search text is empty -- just grab matching recipes for selected keywords
        if trimmedSearchText.isEmpty {
            let results = handler.recipesForKeywords(keywordIDs: keywordIDs, searchText: nil)
            // Return results
            return Array(results).sorted()
        }

        /// User is searching via keywords/tags *AND* search text
        let results = handler.recipesForKeywords(keywordIDs: keywordIDs, searchText: trimmedSearchText)
        return Array(results).sorted()
    }

    
    func fetchAllRecipes(container: ModelContainer) async throws {

        let recipes: [RecipeSendable]? = try await Task.detached { [container] in
            
            let handler = DataHandler(modelContainer: container)
            let recipes = try await handler.fetchRecipes(
                descriptor: FetchDescriptor<Recipe>(
                    sortBy: [SortDescriptor(\Recipe.timestamp)]
                )
            )
            return recipes
        }.value
        
        withAnimation(.spring) {
            self.recipes = recipes
        }
    }
    
    func fetchAllKeywords(container: ModelContainer) async throws {

        let keywords: [KeywordSendable]? = try await Task.detached { [container] in
            
            let handler = DataHandler(modelContainer: container)
            let keywords = try await handler.fetchKeywords(
                descriptor: FetchDescriptor<Keyword>(
                    sortBy: [SortDescriptor(\Keyword.timestamp)]
                )
            )
            return keywords
        }.value
        
        withAnimation(.spring) {
            self.keywords = keywords
        }
    }
}
