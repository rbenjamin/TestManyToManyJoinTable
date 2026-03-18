//
//  AppModel.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//
import SwiftUI
import SwiftData
import DataProvider
import OSLog

enum RecipeListRoute: Hashable, Codable {
    case recipeDetails(recipeUUID: UUID)
}
enum KeywordListRoute: Hashable, Codable {
    case keywordRoute(keywordUUID: UUID)
}

@Observable final class AppModel {
    var recipes: [RecipeSendable] = []
    var keywords: [KeywordSendable] = []
    var searchController: TokenSearchBarUIController = .init(searchText: "", tokens: [])
    var filteredTokens: [SearchTokenValue] = []
    var allTokens: [SearchTokenValue] = []
    var recipePath: NavigationPath = .init()
    var keywordPath: NavigationPath = .init()
    var tokenListVisible: Bool = false
    
    var searchText: String {
        searchController.searchText
    }
    
    var searchTokens: Set<SearchTokenValue> {
        searchController.tokens
    }
    
    @ObservationIgnored let log = Logger(subsystem: "TestManyToManyJoinTable", category: "AppModel")
    
    func navigateToRecipe(route: RecipeListRoute) {
        recipePath.append(route)
    }

    func navigateToKeyword(route: KeywordListRoute) {
        keywordPath.append(route)
    }

    
    func performSearch(
        searchText: String,
        tokens: Set<SearchTokenValue>,
        container: ModelContainer,
    ) async {
        let index = searchText.firstIndex(of: "#")
        guard index != nil else {
            try? await Task.sleep(nanoseconds: 100_000_000)
            do {
                let searchResults = try await self.search(searchText: searchText, tokens: tokens, container: container)

                if let searchResults {
                    withAnimation {
                        recipes = searchResults
                    }
                }
            }
            catch let error {
                #if DEBUG
                fatalError("[performSearch(searchText: tokens: container:)]: Failed to perform search with error: \(error)")
                #else
                log.error("[performSearch(searchText: tokens: container:)]: Failed to perform search with error: \(error.localizedDescription)")
                #endif
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
            return false
        })
        withAnimation(.spring) {
            filteredTokens = filtered
        }


    }
    
    private func search(
         searchText: String,
         tokens: Set<SearchTokenValue>,
         container: ModelContainer,
    ) async throws -> [RecipeSendable]? {
        let tokensIsEmpty = tokens.isEmpty
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespaces)
        // no tokens or tags (just sort)
        if tokensIsEmpty && trimmedSearchText.isEmpty {
            return recipes.sorted()
        }
        
        // No tags being filtered -- just a text search
        if tokensIsEmpty {
//            return handler.recipeSearch(searchText)
            return try await Task.detached { [container, searchText] in
                let handler = DataHandler(modelContainer: container)
                return try await handler.recipeSearch(searchText)
            }.value
        }
        
        var keywordIDs = Set<UUID>()
        
        for token in tokens {
            if case .keyword(let key) = token {
                keywordIDs.insert(key.uuid)
            }
        }
        // search text is empty -- just grab matching recipes for selected keywords
        if trimmedSearchText.isEmpty {
            
            return try await Task.detached { [container] in
                let handler = DataHandler(modelContainer: container)
                let results = try await handler.recipesForKeywords(keywordIDs: keywordIDs, searchText: nil)
                return Array(results).sorted()
            }.value
        }

        /// User is searching via keywords/tags *AND* search text
        return try await Task.detached { [container, keywordIDs, trimmedSearchText] in
            let handler = DataHandler(modelContainer: container)
            let results = try await handler.recipesForKeywords(keywordIDs: keywordIDs, searchText: trimmedSearchText)
            return Array(results).sorted()
        }.value
    }

    
    func fetchAllRecipes(container: ModelContainer) async throws {

        if let recipes: [RecipeSendable]? = (try await Task.detached { [container] in
            
            let handler = DataHandler(modelContainer: container)
            let recipes = try await handler.fetchRecipes(
                descriptor: FetchDescriptor<Recipe>(
                    sortBy: [SortDescriptor(\Recipe.timestamp)]
                )
            )
            return recipes
        }.value) {
            
            withAnimation(.spring) {
                self.recipes = recipes ?? []
            }

        }
    }
    
    func fetchAllKeywords(container: ModelContainer) async throws {

        if let keywords: [KeywordSendable]? = (try await Task.detached { [container] in
            
            let handler = DataHandler(modelContainer: container)
            let keywords = try await handler.fetchKeywords(
                descriptor: FetchDescriptor<Keyword>(
                    sortBy: [SortDescriptor(\Keyword.timestamp)]
                )
            )
            return keywords
        }.value) {
            let searchTokens = keywords?.compactMap({ SearchTokenValue.keyword(keyword: $0) })
            withAnimation(.spring) {
                self.keywords = keywords ?? []
                self.allTokens = searchTokens ?? []
                
            }
        }
    }
}
