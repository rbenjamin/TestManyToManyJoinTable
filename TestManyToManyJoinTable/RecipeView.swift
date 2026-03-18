//
//  RecipeView.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftUI
import SwiftData
import DataProvider
import OSLog

struct RecipeView: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var recipe: Recipe
    let container: ModelContainer
    @State private var keywords: [KeywordSendable] = []
    @FocusState private var textFocus: Bool
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "RecipeView")
    init(recipe: Recipe, container: ModelContainer) {
        self.recipe = recipe
        self.container = container
    }
    
    var body: some View {
        VStack {
            TextField("Title", text: $recipe.label)
                .focused($textFocus)
                .onChange(of: textFocus) { _, newValue in
                    if newValue == false {
                        saveContext()
                    }
                }
            
            GroupBox {
                WrappingHStack {
                    ForEach(keywords, id: \.uuid) { keyword in
                        TagView(label: keyword.label)
                    }
                }
            }
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .onDisappear() {
            textFocus = false
            saveContext()
        }
        .task {
            do {
                let words = try await self.keywords(for: recipe.uuid, container: container)
                withAnimation {
                    keywords = words
                }
            }
            catch let error {
                log.error("[task()]: Failed to retrieve keywords with error: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveContext() {
        if modelContext.hasChanges {
            do {
                try modelContext.save()
            }
            catch let error {
                log.error("[saveContext()]: Failed to save: \(error)")
            }
        }
    }

    
    nonisolated func keywords(for recipeID: UUID, container: ModelContainer) async throws -> [KeywordSendable] {
        let handler = DataHandler(modelContainer: container)
        return try await handler.keywordsForRecipe(recipeID: recipeID)
    }
}


#Preview {
    let container = DataProvider.previewContainer()
    let r = Recipe()
    container.mainContext.insert(r)
    
    return RecipeView(recipe: r, container: container)
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}
