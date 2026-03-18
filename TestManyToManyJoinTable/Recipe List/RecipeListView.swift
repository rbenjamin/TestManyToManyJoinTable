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


struct RecipeListView: View {
    @Environment(\.modelContext) var modelContext
    @State private var searchBarFocused: Bool = false
    
    @Bindable var appModel: AppModel
    let container: ModelContainer
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "RecipeListView")
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        List {
            if appModel.recipes.isEmpty {
                Text("Tap \(Image(systemName: "plus")) to create a new recipe.")
            }
            ForEach(appModel.recipes, id: \.id) { recipe in
                row(for: recipe)
            }
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color(uiColor: UIColor.systemGroupedBackground)
                .ignoresSafeArea()
        }
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
        .onAppear {
            initialTask()
        }
        .onChange(of: appModel.searchText) { _, newValue in
            searchTask?.cancel()
            searchTask = Task {
                await searchTextChanged(newValue)
            }
        }
        .onChange(of: appModel.searchController.focused) { _, newValue in
            searchControllerFocusChanged(newValue)
        }
        .onChange(of: appModel.searchController.showTokenList) { _, newValue in
            withAnimation(.spring) {
                appModel.tokenListVisible = newValue
            }
        }
    }
    
    // MARK: - Subviews -
    
    func row(for recipe: RecipeSendable) -> some View {
        Button {
            appModel.recipePath.append(
                RecipeListRoute.recipeDetails(
                    recipeUUID: recipe.uuid
                )
            )
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(recipe.label)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        
                    Text(recipe.keywordsLabel)
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
            .foregroundStyle(Color.primary)
        }
    }
    
    @ViewBuilder
    var searchBarView: some View {
        if appModel.searchController.focused {
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
    var tokenFlowOverlay: some View {
        if appModel.tokenListVisible {
            TokenFlowOverlay(filteredTokens: $appModel.filteredTokens, visible: $appModel.tokenListVisible, focused: $searchBarFocused) { token in
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
    
    var toolbarContent: some ToolbarContent {
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
    
    // MARK: - Functions -
    
    func initialTask() {
        Task {
            do {
                try await appModel.fetchAllRecipes(container: container)
            }
            catch let error {
                log.error("Failed to fetch all recipes with error: \(error.localizedDescription)")
            }
        }
    }
    
    func searchToggled() {
        withAnimation {
            appModel.searchController.focused.toggle()
        }
    }
    
    func searchControllerFocusChanged(_ newValue: Bool) {
        withAnimation(.spring) {
            searchBarFocused = newValue
        }
        
        if newValue == false && appModel.searchText.isEmpty {
            Task {
                do {
                    try await appModel.fetchAllRecipes(container: container)
                }
                catch let error {
                    #if DEBUG
                    fatalError("[body().onChange(of: appModel.searchController.focused)]: Failed with error: \(error.localizedDescription)")
                    #else
                    log.error("[body().onChange(of: appModel.searchController.focused)]: Failed with error: \(error.localizedDescription)")
                    #endif
                }
            }
        }
    }
    
    @MainActor
    private func tokenButtonPressed(_ token: SearchTokenValue) async {
        
        let searchText = appModel.searchController.searchText
        
        if !appModel.searchController.tokens.contains(token) {
            appModel.searchController.tokens.insert(token)
        }
        appModel.filteredTokens = appModel.allTokens
        
        withAnimation {
            appModel.searchController.showTokenList = false
        }
        try? await Task.sleep(for: .seconds(0.1))
        if let index = searchText.firstIndex(of: "#") {
            let removedPound = searchText[..<index]
            appModel.searchController.searchText = String(removedPound)
        }
    }
    
    func searchTextChanged(_ query: String) async {
        if query.isEmpty {
            do {
                try await appModel.fetchAllRecipes(container: container)
            }
            catch let error {
                log.error("[searchTextChanged(_:)]: Failed to fetch recipes with error: \(error.localizedDescription)")
            }
        } else {
            await appModel.performSearch(searchText: query, tokens: appModel.searchTokens, container: container)
        }
    }
    
    func addRecipe() {
        do {
            let r = Recipe()
            modelContext.insert(r)
            try modelContext.save()
            
            appModel.recipePath.append(
                RecipeListRoute.recipeDetails(recipeUUID: r.uuid)
            )
            Task {
                do {
                    try await appModel.fetchAllRecipes(container: container)
                }
                catch let error {
                    log.error("Failed to fetch all recipes with error: \(error.localizedDescription)")
                }
            }
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
