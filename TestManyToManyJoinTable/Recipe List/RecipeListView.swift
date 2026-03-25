//
//  RecipeListViw.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import Foundation
import SwiftUI
import SwiftData
import OSLog
import DataProvider

struct RecipeIndex: Sendable {
    let index: Int
    let uuid: UUID
    init(index: Int, uuid: UUID) {
        self.index = index
        self.uuid = uuid
    }
}

struct RecipeListView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var appModel: AppModel
    let container: ModelContainer

    @State private var searchBarFocused: Bool = false
    @State private var onAppearTaskID = UUID()
    private let log = Logger(subsystem: "TestManyToManyJoinTable", category: "RecipeListView")
    @State private var searchTask: Task<Void, Never>?
    @State private var lastFetch: Date?
    let listSpacing = ListSectionSpacing.custom(0)
    @State private var pushedRecipe: RecipeSendable?
    
   
    var body: some View {
        scrollView
        .background(backgroundView)
        .overlay {
            tokenFlowOverlay
        }
        .safeAreaBar(edge: .bottom) {
            searchBarView
        }
        .toolbarRole(.navigationStack)
        .toolbar {
            toolbarContent
        }
        .onChange(of: appModel.searchController.tokens, { _, newValue in
            Task {
                await self.tokensChanged(newTokens: newValue)
            }
        })
        .onChange(of: appModel.reloadRecipes) {
            lastFetch = nil
            onAppearTaskID = UUID()
        }
        .onChange(of: appModel.searchController.showTokenList) { _, newValue in
            withAnimation(.spring) {
                appModel.tokenListVisible = newValue
            }
        }
    }
    
    var scrollView: some View {
        ScrollViewReader { proxy in
            List {
                listBodyContents
            }
            
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: onAppearTaskID) {
                await initialTask(proxy: proxy)
            }
            .onChange(of: appModel.searchController.focused) { _, newValue in
                searchControllerFocusChanged(newValue)
            }
            .onChange(of: appModel.searchController.searchText, { _, newValue in
                Task {
                    await searchTextChanged(newValue)
                }
            })
        }
    }
    
    @ViewBuilder
    var listBodyContents: some View {
        emptyListView
        ForEach(appModel.recipes.enumerated(), id: \.element.uuid) { (index, recipe) in
            row(for: recipe, index: index)
        }
        .onDelete { indexSet in
            Task {
                await delete(with: indexSet)
            }
        }
        .scrollTargetLayout()
            
        
        Section {
            lastRowBody
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listSectionSpacing(listSpacing)

    }
    
    // MARK: - Subviews -
    @ViewBuilder
    var emptyListView: some View {
        if appModel.recipes.isEmpty {
            Text("Tap \(Image(systemName: "plus")) to create a new recipe.")
        }
    }
    
    var backgroundView: some View {
        Color(uiColor: UIColor.systemGroupedBackground)
            .ignoresSafeArea()
    }
    
    var lastRowBody: some View {
        HStack {
            Spacer()
            if appModel.reachedRecipesEnd == false && appModel.isSearching == false {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .transition(.scale)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
        }
        .frame(minHeight: 44)
        .onAppear {
            if appModel.isSearching == false {
                lastRowOnAppear()
            }
        }
    }

    @ViewBuilder
    private var searchBarView: some View {
        if searchBarFocused {
            HStack {
                Button("Done") {
                    appModel.searchController.focused = false
                }
                .buttonStyle(.glassProminent)
                
                TokenSearchBarUI(
                    controller: appModel.searchController,
                    toolbarBackground: UIColor.clear,
                    toolbarForeground: UIColor.label
                )
            }
            .frame(maxHeight: 44)
            .padding([.leading, .trailing, .bottom], 6)
            .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))

        }
    }
    
    @ViewBuilder
    private var tokenFlowOverlay: some View {
        if appModel.tokenListVisible {
            TokenFlowOverlay(
                filteredTokens: $appModel.filteredTokens,
                visible: $appModel.tokenListVisible,
                focused: $searchBarFocused
            ) { token in
                Task {
                    await tokenButtonPressed(token)
                }
            } filterCancelled: {
                if appModel.searchController.searchText.hasPrefix("#") {
                    appModel.searchController.searchText = ""
                }
                appModel.searchController.focused = false
                appModel.searchController.showTokenList = false
                
            }
            .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button("Create Default", systemImage: "plus.square.dashed") {
                Task {
                    do {
                        try await appModel.createFakeRecipes(container: container)
                    }
                    catch let error {
                        log.error("Failed to create fake recipes with error: \(error.localizedDescription)")
                    }
                }
            }
            .disabled(true)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Search",
                   systemImage: "magnifyingglass",
                   action: searchToggled)
                .labelStyle(.iconOnly)
                .buttonStyle(.glassProminent)

            Button("New Recipe",
                   systemImage: "plus",
                   action: addRecipe)
            .labelStyle(.iconOnly)
            .buttonStyle(.glassProminent)
        }
    }
    
    private func rowBody(title: String, keywords: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    
                Text(keywords)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Spacer()
                Image(systemName: "chevron.right")
                Spacer()
            }
        }
    }
    
    private func rowAction(index: Int, uuid: UUID) async {
        let wasFocused = searchBarFocused
        withAnimation {
            appModel.searchController.focused = false
        }
        if wasFocused {
            try? await Task.sleep(for: .seconds(0.10))
        }
        self.pushedRecipe = appModel.recipes[index]
        appModel.lastVisibleID = .init(index: index, uuid: uuid)
        appModel.recipePath.append(
            RecipeListRoute.recipeDetails(
                recipeUUID: uuid
            )
        )
    }
    
    private func row(for recipe: RecipeSendable, index: Int) -> some View {
        Button {
            Task {
                await rowAction(index: index, uuid: recipe.uuid)
            }
        } label: {
            rowBody(title: recipe.label,
                    keywords: recipe.keywordsLabel)
            .foregroundStyle(Color.primary)
        }
    }
    
  
    
    // MARK: - Functions -
    
    func rowOnAppear(recipe: RecipeSendable, index: Int) {
        if let lastVisibleID = appModel.lastVisibleID,
            lastVisibleID.index < index {
            appModel.lastVisibleID = .init(index: index,
                                           uuid: recipe.uuid)
        } else if appModel.lastVisibleID == nil,
                    index >= appModel.pageSize {
            appModel.lastVisibleID = .init(index: index,
                                           uuid: recipe.uuid)
        }
        
        Task {
            do {
                log.debug("index: \(index) recipe: \(recipe.label)")
                try await recipeIsInEndRange(recipe: recipe)
            }
            catch let error {
                log.error("[recipeIsInEndRange(recipe:)]: Error received fetching the next page: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func initialFetch(proxy: ScrollViewProxy? = nil, animated: Bool = false) async throws {
        try await appModel.fetchRecipesPage(
            container: container,
            shouldRestart: true,
            animated: animated,
        )
        pushedRecipe = nil
        appModel.lastVisibleID = nil
    }
    
    func validateIndices() async {
        
            let container = self.container
            Task.detached { [container, log] in
                let handler = DataHandler(modelContainer: container)
                do {
                    try await handler.validateRecipeToIndices()
                    try await handler.validateKeywordToIndices()

                }
                catch let error {
                    log.error("Failed to validate indices with error: \(error.localizedDescription)")
                }
            }
        
    }
    
    private func initialTask(proxy: ScrollViewProxy) async {
        
        if appModel.dateLastOpened != nil {
            if appModel.lastIndexValidation == nil || (appModel.lastIndexValidation?.distance(to: Date()) ?? 0) > 43_200 {
                await self.validateIndices()
                    let container = container
                    
                    Task.detached { [container] in
                            
                        let handler = DataHandler(modelContainer: container)
                        try await handler.createMissingIndices()
                       
                    }
                
                appModel.lastIndexValidation = Date()
            }
        }

        if lastFetch == nil || (lastFetch!.distance(to: Date()) > 6) {
            
            do {
                try await initialFetch(proxy: proxy)
                try await appModel.fetchAllKeywords(container: container)
            }
            catch let error {
                log.error("Failed to fetch all recipes with error: \(error.localizedDescription)")
            }
            self.lastFetch = Date()
        }
    }
    
    private func lastRowOnAppear() {
        Task {
            try? await Task.sleep(for: .seconds(0.4))
            let currentIndex = appModel.recipes.endIndex - 1
            guard currentIndex >= appModel.pageSize-1, !appModel.recipes.isEmpty else { return }
            let lastRecipe = appModel.recipes[currentIndex]
            
            appModel.lastVisibleID = .init(
                index: currentIndex,
                uuid: lastRecipe.uuid
            )
            guard appModel.isLoadingRecipes == false else { return }
            guard appModel.reachedRecipesEnd == false else { return }

            do {
                log.debug("reached last row body! Index: \(currentIndex) recipe: \(lastRecipe.label)")
                try await recipeIsInEndRange(recipe: lastRecipe)
            }
            catch let error {
                log.error("[recipeIsInEndRange(recipe:)]: Error received fetching the next page: \(error.localizedDescription)")
            }
        }
    }
    
    private func searchToggled() {
        withAnimation {
            appModel.searchController.focused.toggle()
        }
    }
    
    
    private func delete(with indexSet: IndexSet) async {
        var ids: Set<UUID> = []
        for index in indexSet {
            ids.insert(appModel.recipes[index].uuid)
        }
        do {
            let handler = DataHandler(modelContainer: container)
            try await handler.deleteRecipes(uuids: ids)
        }
        catch let error {
            log.error("[delete(with:)]: Failed to delete recipes [count: \(ids.count)]. Error: \(error.localizedDescription)")
        }
    }
    
    
    private func recipeIsInEndRange(recipe: RecipeSendable) async throws {
        
        if appModel.reachedRecipesEnd == false && appModel.recipes[
            (appModel.recipes.maxOffsetUpTo(offset: 5)...)
        ].contains(recipe) {
            try await appModel.fetchRecipesPage(
                container: container,
                shouldRestart: false,
                animated: false
            )

        } else if appModel.reachedRecipesEnd == false && appModel.recipes.last?.persistentModelID == recipe.persistentModelID {
            try await appModel.fetchRecipesPage(
                container: container,
                shouldRestart: false,
                animated: false
            )
        }
    }
    
    private func searchControllerFocusChanged(_ newValue: Bool) {
        if newValue == true {
            appModel.isSearching = true
        } else if newValue == false && appModel.searchText.isEmpty && appModel.searchTokens.isEmpty {
            appModel.isSearching = false
        }
        withAnimation(.spring) {
            searchBarFocused = newValue
        }
    }
    
    @MainActor
    private func tokenButtonPressed(_ token: SearchTokenValue) async {
        
        let searchText = appModel.searchController.searchText
        if !appModel.searchController.tokens.contains(token) {
            appModel.searchController.tokens.insert(token)
        }
        try? await Task.sleep(for: .seconds(0.1))

        if let index = searchText.firstIndex(of: "#") {
            let removedPound = searchText[..<index]
            appModel.searchController.searchText = String(removedPound)
        }
        
        appModel.filteredTokens = appModel.allTokens
        
        withAnimation {
            appModel.searchController.showTokenList = false
        }
        
        await appModel.performSearch(
            searchText: appModel.searchText,
            tokens: appModel.searchTokens,
            container: container
        )
    }
    
    private func tokensChanged(newTokens: Set<SearchTokenValue>) async {
        print("tokensChanged - performing search.")
        await appModel.performSearch(
            searchText: appModel.searchText,
            tokens: newTokens,
            container: container
        )
    }
    
    private func searchTextChanged(_ query: String) async {
        if query.isEmpty && appModel.searchTokens.isEmpty {
            appModel.isSearching = false
            do {
                try await initialFetch()
            }
            catch let error {
                log.error("[searchTextChanged(_:)]: Failed to fetch recipes with error: \(error.localizedDescription)")
            }
        } else {
            appModel.isSearching = true
            await appModel.performSearch(
                searchText: query,
                tokens: appModel.searchTokens,
                container: container
            )
        }
    }
    
    private func addRecipe() {
        do {
            let r = Recipe()
            modelContext.insert(r)
            try modelContext.save()
            
            appModel.lastVisibleID = .init(
                index: appModel.recipes.endIndex,
                uuid: r.uuid
            )
            
            appModel.recipePath.append(
                RecipeListRoute.recipeDetails(recipeUUID: r.uuid)
            )
        }
        catch let error {
            log.error("Failed to insert recipe with error: \(error.localizedDescription)")
        }
    }
    
}


#Preview {
    let container = DataProvider.previewContainer()
    
    RecipeListView(appModel: .init(), container: container)
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}
