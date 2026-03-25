//
//  AppModel.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//
import SwiftUI
import SwiftData
import DataProvider
import CoreData
import OSLog

enum RecipeListRoute: Hashable, Codable {
    case recipeDetails(recipeUUID: UUID)
}
enum KeywordListRoute: Hashable, Codable {
    case keywordRoute(keywordUUID: UUID)
}

@Observable final class AppModel {
    @ObservationIgnored let log = Logger(subsystem: "TestManyToManyJoinTable", category: "AppModel")
    @ObservationIgnored @AppStorage("dateLastOpened") var dateLastOpened: Date?
    @ObservationIgnored @AppStorage("lastIndexValidationDate") var lastIndexValidation: Date?

    
    var recipes: [RecipeSendable] = []
    var keywords: [KeywordSendable] = []
    var searchController: TokenSearchBarUIController = .init(searchText: "", tokens: [])
    var filteredTokens: [SearchTokenValue] = []
    var allTokens: [SearchTokenValue] = []
    var recipePath: NavigationPath = .init()
    var keywordPath: NavigationPath = .init()
    var tokenListVisible: Bool = false
    var reloadRecipes: Bool = false
    var reloadKeywords: Bool = false
    var lastVisibleID: RecipeIndex?
    var isSearching: Bool = false
    var showProgress: Bool = false
    @ObservationIgnored var recipesOffset: Int = 0
    @ObservationIgnored let pageSize: Int = 18
    @ObservationIgnored var reachedRecipesEnd: Bool = false
    @ObservationIgnored var isLoadingRecipes: Bool = false
    var cloudKitSetupFinished: Bool = false
    var cloudKitTouchDate: Date?
    var cloudKitTask: Task<Void, Never>?
    
    @ObservationIgnored private var quietPeriodDelay: Double {
        if dateLastOpened != nil {
            return 4
        } else {
            return 12
        }
    }
    
    @ObservationIgnored private var ckDidFinishDelay: Double {
        if dateLastOpened != nil {
            return 3
        } else {
            return 10
        }
    }
    
    var searchText: String {
        searchController.searchText
    }
    
    var searchTokens: Set<SearchTokenValue> {
        searchController.tokens
    }
    
    
    func navigateToRecipe(route: RecipeListRoute) {
        recipePath.append(route)
    }
    
    func navigateToKeyword(route: KeywordListRoute) {
        keywordPath.append(route)
    }
    
    func ckNotificationEventRecieved(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
            as? NSPersistentCloudKitContainer.Event else { return }

        switch event.type {
            case .setup: log.debug("CKEvent: Setup")
            case .import: log.debug("CKEvent: Import")
            case .export: log.debug("CKEvent: Export")
            @unknown default: log.debug("CKEvent: UNKNOWN")
        }

        // Record CloudKit activity
        cloudKitTouchDate = Date()
        if cloudKitSetupFinished == false {
            withAnimation(.spring) {
                showProgress = true
            }
        }
        // Cancel any pending stability detection
         cloudKitTask?.cancel()

         cloudKitTask = Task { [weak self] in
            guard let self else { return }

            // Wait for quiet period
            try? await Task.sleep(for: .seconds(self.quietPeriodDelay))

            // If no newer activity happened
            guard let last = self.cloudKitTouchDate,
                  Date().timeIntervalSince(last) > self.ckDidFinishDelay else {
                return
            }

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.log.debug("CloudKit appears stable")

                self.cloudKitSetupFinished = true
                
                withAnimation(.spring) {
                    self.showProgress = false
                }
                if event.type != .export {
                    reloadRecipes.toggle()
                    
                    reloadKeywords.toggle()
                }
            }
        }
    }
    
    // MARK: - Recipe Search
    
    /// Checks the search parameters to determine whether to execute the search or present the tag picker.
    /// - Parameters:
    ///   - searchText: Query
    ///   - tokens: Selected tokens (those present in the text field)
    ///   - container: ModelContainer
    func performSearch(
        searchText: String,
        tokens: Set<SearchTokenValue>,
        container: ModelContainer,
    ) async {
        // check whether the user has started filtering for a tag.
        let index = searchText.firstIndex(of: "#")
        guard index != nil else {
            await basicSearch(searchText: searchText, tokens: tokens, container: container)
            return
        }
        
        // Since searchText contains a "#", show the token list.
        withAnimation(.spring) {
            tokenListVisible = true
        }
        // ensure we can grab the word after the "#" symbol.
        let endIndex = searchText.endIndex
        guard let index,
              index < endIndex else {
            return
        }
        let letterIndex = searchText.index(after: index)
        let subword = searchText[letterIndex...].lowercased()
        
        // No subword yet (or the user has backspaced) - show all available tokens.
        guard !subword.isEmpty else {
            withAnimation(.spring) {
                filteredTokens = allTokens
            }
            return
        }
        
        // Only one available token -- use it, as long as the user has finished the word (check for white space)
        if filteredTokens.count == 1 &&
            searchText.count > 1 &&
            searchText[
                searchText.index(before: endIndex)
            ].isWhitespace {
            
            withAnimation(.spring) {
                searchController.tokens.insert(
                    filteredTokens[0]
                )
                filteredTokens = allTokens
                searchController.searchText = ""
                searchController.showTokenList = false
            }
        }
        // There are still tokens that could be filtered. Filter the tokens based on the tag search ("#").
        let filtered = allTokens.filter({ tkn in
            if case .keyword(let keyword) = tkn {
                return keyword.lowercasedLabel.hasPrefix(subword)
            }
            return false
        })
        // Update the UI
        withAnimation(.spring) {
            filteredTokens = filtered
        }
    }
    
    @inline(__always)
    private func basicSearch(
        searchText: String,
        tokens: Set<SearchTokenValue>,
        container: ModelContainer
    ) async {
        // perform a regular search -- the user isn't tag filtering.
        try? await Task.sleep(nanoseconds: 100_000_000)
        do {
            let searchResults = try await self.search(searchText: searchText, tokens: tokens, container: container)
            
            if let searchResults {
                withAnimation(.spring) {
                    recipes = searchResults.sorted()
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
    }
    
    
    /// Private search function. Fulfills the actual search.
    /// - Parameters:
    ///   - searchText: Search Text
    ///   - tokens: User-selected tokens
    ///   - container: ModelContainer
    /// - Returns: Optional array of RecipSendable structs.
    private func search(
        searchText: String,
        tokens: Set<SearchTokenValue>,
        container: ModelContainer,
    ) async throws -> [RecipeSendable]? {
        
        let tokensIsEmpty = tokens.isEmpty
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespaces)
        // no tokens or tags (just sort)
        if tokensIsEmpty && trimmedSearchText.isEmpty {
            return try await Task.detached { [container] in
                let handler = DataHandler(modelContainer: container)
                return try await handler.fetchRecipes(
                    descriptor: FetchDescriptor<Recipe>(
                        sortBy: [SortDescriptor(\Recipe.timestamp)]
                    )
                )
            }.value
        }
        
        // No tags being filtered -- just a text search
        if tokensIsEmpty {
            return try await Task.detached { [container, searchText] in
                let handler = DataHandler(modelContainer: container)
                return try await handler.recipeSearch(searchText)
            }.value
        }
        
        // tags *are* being filtered, so extract the keyword id from the search tokens.
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
    
    
    // MARK: - Recip List Paging
    /// Rather than seperating first and next page fetch, which would cause recipes (an observed property) to animate the removal, then the insertion, we combine the functions.  To reset the offset and refetch existing recipes, set shouldRestart to true.
    func fetchRecipesPage(
        container: ModelContainer,
        shouldRestart: Bool,
//        pageSize: Int?,
        animated: Bool
    ) async throws {
        if shouldRestart {
            recipesOffset = 0
            reachedRecipesEnd = false
        }
//        var size = pageSize
//        if size != nil {
//            size! += 1
//        }

        if isSearching {
            await performSearch(searchText: self.searchText, tokens: self.searchTokens, container: container)
        } else {
            
            var results: [RecipeSendable] = shouldRestart ? [] : recipes
            
            guard isLoadingRecipes == false,
                  reachedRecipesEnd == false else { return }
            
            isLoadingRecipes = true
            let offset = self.recipesOffset
            let pageSize = self.pageSize
            let fetchedValues = try await Task.detached { [container, offset, pageSize] in
                let handler = DataHandler(modelContainer: container)
                var descriptor = FetchDescriptor<Recipe>()
                descriptor.fetchLimit = pageSize
                descriptor.fetchOffset = offset
                
                return try await handler.fetchRecipes(descriptor: descriptor)
            }.value
            if fetchedValues.count < pageSize { reachedRecipesEnd = true }

            results += fetchedValues
            if animated {
                withAnimation(.spring) {
                    recipes = results
                    recipesOffset += fetchedValues.count
                }
            } else {
                recipes = results
                recipesOffset += fetchedValues.count
            }
            
            log.debug("[fetchRecipesPage(container: shouldRestart: pageSize: animated:)]: recipes.count: \(self.recipes.count)")
            isLoadingRecipes = false

        }
    }
    
    
    // MARK: - Keyword Fetch
    
    /// Fetches all keywords
    /// - Parameter container: Model Container
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
    
    func createFakeRecipes(container: ModelContainer) async throws {
        try await Task.detached { [container] in
            let handler = DataHandler(modelContainer: container)
            try await handler.createDefaultRecipes()
        }
    }
}
