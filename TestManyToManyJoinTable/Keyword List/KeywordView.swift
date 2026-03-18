//
//  KeywordView.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftUI
import SwiftData
import Foundation
import DataProvider
import OSLog

struct KeywordView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Bindable var keyword: Keyword
    @FocusState private var textFocus: Bool
    
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "KeywordView")
    init(keyword: Keyword) {
        self.keyword = keyword
    }
    
    @Query(FetchDescriptor<Recipe>()) var recipes: [Recipe]
    @State private var relationships: Set<Recipe> = []
    @State private var modified: Set<Recipe> = []
    
    var body: some View {
        VStack {
            TextField("Keyword Label", text: $keyword.label)
                .focused($textFocus)
                .onChange(of: textFocus) { _, newValue in
                    if newValue == false {
                        saveContext()
                    }
                }
            Divider()
            GroupBox("Recipes:") {
                recipePicker
            }
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .tabViewBottomAccessory(content: {
            Circle().fill(Color.red)
        })
        .task {
            relationships = Set(keyword.recipes ?? [])
        }
        .onDisappear() {
            textFocus = false
            saveContext()
        }
        .onChange(of: relationships) { _, newValue in
            for recipe in recipes {
                if newValue.contains(recipe), modified.contains(recipe) {
                    validateExistingRelationshipValues(recipe: recipe)
                } else if !newValue.contains(recipe),
                          modified.contains(recipe) {
                    removeExistingRelationshipValues(recipe: recipe)
                }
            }
            saveContext()
        }
    }
    
    var recipePicker: some View {
        ForEach(recipes, id: \.uuid) { recipe in
            HStack(spacing: 4) {
                Button(recipe.label) {
                    if relationships.contains(recipe) {
                        relationships.remove(recipe)
                        modified.insert(recipe)
                    } else {
                        modified.insert(recipe)
                        relationships.insert(recipe)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                if relationships.contains(recipe) {
                    Image(systemName: "checkmark")
                        .imageScale(.medium)
                        .foregroundStyle(Color.accentColor)
                        .transition(.scale)
                }
            }
            .frame(minHeight: 24)
            .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .background {
                Capsule().fill(colorScheme == .light ? Color.white : Color.black)
            }
            if recipe.uuid != recipes.last?.uuid {
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
                log.error("[onDissapear()]: Failed to save: \(error)")
            }
        }
    }
    
    private func removeExistingRelationshipValues(recipe: Recipe) {
        if let firstIndex = keyword.recipes?.firstIndex(of: recipe) {
            keyword.recipes?.remove(at: firstIndex)
        }
        if let firstIndex = recipe.keywords?.firstIndex(of: keyword) {
            recipe.keywords?.remove(at: firstIndex)
        }
        let recipeUUID = recipe.uuid
        let keywordUUID = keyword.uuid
        let predicate = #Predicate<RecipeKeywordIndex> { idx in
            return idx.recipeID == recipeUUID &&
                idx.keywordID == keywordUUID
        }
        do {
            let existing:[RecipeKeywordIndex] = try modelContext.fetch(
                FetchDescriptor<RecipeKeywordIndex>(predicate: predicate)
            )
            if !existing.isEmpty {
                for existing in existing {
                    modelContext.delete(existing)
                }
            }
        }
        catch let error {
            print("Failed to fetch RecipeKeywordIndex with error: \(error.localizedDescription)")
        }

    }
    
    private func validateExistingRelationshipValues(recipe: Recipe) {
        recipe.keywords?.append(keyword)
        let recipeUUID = recipe.uuid
        let keywordUUID = keyword.uuid
        
        let predicate = #Predicate<RecipeKeywordIndex> { idx in
            return idx.recipeID == recipeUUID &&
                idx.keywordID == keywordUUID
        }
        do {
            let existing:[RecipeKeywordIndex] = try modelContext.fetch(
                FetchDescriptor<RecipeKeywordIndex>(predicate: predicate)
            )
            
            if existing.isEmpty {
                let newIndex = RecipeKeywordIndex(recipeID: recipeUUID, keywordID: keywordUUID)
                modelContext.insert(newIndex)
            }
        }
        catch let error {
            print("Failed to fetch RecipeKeywordIndex with error: \(error.localizedDescription)")
        }
    }
}



#Preview {
    let container = DataProvider.previewContainer()
    let k = Keyword()
    container.mainContext.insert(k)
    
    return KeywordView(keyword: k)
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}
