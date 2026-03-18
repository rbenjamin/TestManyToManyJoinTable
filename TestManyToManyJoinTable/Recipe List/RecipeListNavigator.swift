//
//  RecipeListNavigator.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import Foundation
import SwiftUI
import SwiftData
import OSLog

struct RecipeListNavigator: View {
    @Environment(\.modelContext) var modelContext
    let appModel: AppModel
    let container: ModelContainer

    var body: some View {
        NavigationStack {
            RecipeListView(appModel: appModel, container: container)
                .navigationDestination(for: RecipeSendable.self) { recipe in
                    // fetch the real recipe
                    recipeView(for: recipe)
                }
        }
    }
    
    @ViewBuilder
    func recipeView(for sendable: RecipeSendable) -> some View {
        if let recipe = Recipe.fetch(
            recipeID: sendable.persistentModelID,
            modelContext: modelContext
        ) {
            RecipeView(recipe: recipe)
        }
        else {
            ContentUnavailableView("Cannot load recipe", image: "x.circle")
        }
    }
}
