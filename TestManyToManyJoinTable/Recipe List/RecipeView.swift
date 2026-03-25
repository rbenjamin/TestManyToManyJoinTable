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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext
    @Bindable var recipe: Recipe
    let container: ModelContainer
    @State private var recipeKeywords: [KeywordSendable] = []
    @FocusState private var textFocus: Bool
    @Query(Keyword.allKeywordsDescriptor) var allKeywords: [Keyword]
    @State private var relationships: Set<Keyword> = []
    @State private var modified: Set<Keyword> = []
    @State private var reloadRecipeKeywordsTaskID: UUID = UUID()
    
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
                    ForEach(recipeKeywords,
                            id: \.uuid) { keyword in
                        TagView(label: keyword.label)
                    }
                }
            }
            Text("Pick Keywords:")
                .font(.system(.title))
            Divider()
            ScrollView {
                LazyVStack {
                    keywordPicker
                }
            }
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .onDisappear() {
            textFocus = false
            saveContext()
        }
        .task(id: reloadRecipeKeywordsTaskID) {

            do {
                let words = try await self.recipeKeywords(
                    for: recipe.uuid,
                    container: container
                )
                withAnimation {
                    recipeKeywords = words
                    relationships = Set(recipe.keywords ?? [])
                }
                

            }
            catch let error {
                log.error("[task()]: Failed to retrieve keywords with error: \(error.localizedDescription)")
            }
        }
        .onChange(of: relationships) { _, newValue in
            for keyword in allKeywords {
                if newValue.contains(keyword), modified.contains(keyword) {
                    RecipeKeywordIndex.validateExistingRelationshipValues(
                        keyword: keyword,
                        fromRecipe: recipe,
                        modelContext: modelContext
                    )
                    //                    validateExistingRelationshipValues(keyword: keyword)
                } else if !newValue.contains(keyword),
                          modified.contains(keyword) {
                    //                    removeExistingRelationshipValues(keyword: keyword)
                    RecipeKeywordIndex.removeExistingRelationshipValues(
                        keyword: keyword,
                        fromRecipe: recipe,
                        modelContext: modelContext
                    )
                }
            }
        }
    }
    
    func keywordRow(for keyword: Keyword) -> some View {
        Button {
            reloadRecipeKeywordsTaskID = UUID()
            if relationships.contains(keyword) {
                relationships.remove(keyword)
                modified.insert(keyword)
            } else {
                modified.insert(keyword)
                relationships.insert(keyword)
            }
        } label: {
            Text(keyword.label)
            
            Spacer()
            
            if relationships.contains(keyword) {
                Image(systemName: "checkmark")
                    .imageScale(.medium)
                    .foregroundStyle(Color.accentColor)
                    .transition(.scale)
            }
        }
    }
    
    var keywordPicker: some View {
        ForEach(allKeywords, id: \.uuid) { keyword in
            HStack(spacing: 4) {
                keywordRow(for: keyword)
            }
            .frame(minHeight: 24)
            .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .background {
                    Capsule().fill(colorScheme == .light ? Color.white : Color.black)
            }
            if keyword.uuid != allKeywords.last?.uuid {
                Divider()
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
    
    
    nonisolated func recipeKeywords(for recipeID: UUID, container: ModelContainer) async throws -> [KeywordSendable] {
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
