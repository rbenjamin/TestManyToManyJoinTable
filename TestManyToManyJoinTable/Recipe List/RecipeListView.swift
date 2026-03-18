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

struct RecipeListView: View {
    @Environment(\.modelContext) var modelContext
    @State private var searchBarFocused: Bool = false
    
    @Bindable var appModel: AppModel
    let container: ModelContainer
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "RecipeListView")
    
    
    var body: some View {
        List {
            ForEach(appModel.recipes, id: \.id) { recipe in
                NavigationLink(value: recipe) {
                    VStack(alignment: .leading) {
                        Text(recipe.label)
                        Text(recipe.keywordsLabel)
                    }
                }
            }
        }
        .overlay {
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
        .safeAreaBar(edge: .bottom) {
            HStack {
                if appModel.searchController.focused {
                    Button("Done") {
                        searchController.focused = false
                    }
                    .buttonStyle(.glassProminent)
                    .transition(.asymmetric(insertion: .push(from: .leading), removal: .push(from: .trailing)))
                }
                
                TokenSearchBarUI(controller: appModel.searchController, toolbarBackground: UIColor.clear, toolbarForeground: UIColor.label)
            }
        }
        .toolbarRole(.navigationStack)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Recipe",
                       systemImage: "plus",
                       action: addRecipe)
                .labelStyle(.iconOnly)
                .buttonStyle(.glassProminent)
            }
        }
        .onChange(of: appModel.searchText) { _, newValue in
            searchTextChanged(newValue)
        }
        .onChange(of: appModel.searchController.focused) { _, newValue in
            withAnimation(.spring) {
                searchBarFocused = newValue
            }
            
            if newValue == false {
                appModel.fetchAllRecipes(container: container)
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
        if let index = appModel.searchText.firstIndex(of: "#") {
            let removedPound = appModel.searchText[..<index]
            appModel.searchController.searchText = String(removedPound)
        }
    }
    
    func searchTextChanged(_ query: String) {
        appModel.performSearch(searchText: query, tokens: appModel.searchTokens, container: container)
    }
    
    func addRecipe() {
        do {
            let r = Recipe()
            modelContext.insert(r)
            try modelContext.save()
        }
        catch let error {
            log.error("Failed to insert recipe with error: \(error.localizedDescription)")
        }
    }
    
}
