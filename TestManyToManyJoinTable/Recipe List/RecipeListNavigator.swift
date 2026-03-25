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
import DataProvider

struct RecipeListNavigator: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var appModel: AppModel
    let container: ModelContainer
    

    var body: some View {
        NavigationStack(path: $appModel.recipePath) {
            RecipeListView(appModel: appModel, container: container)
                .navigationDestination(for: RecipeListRoute.self) { recipe in
                    // fetch the real recipe
                    recipeView(for: recipe)
                }
                .navigationTitle(Text(appModel.isSearching ? "Search Results" : "All Recipes"))
        }
        .tabBarMinimizeBehavior(.automatic)
    }
    
    @ViewBuilder
    func recipeView(for route: RecipeListRoute) -> some View {
        if case .recipeDetails(let recipeUUID) = route {
            if let recipe = try? Recipe.fetch(recipeUUID: recipeUUID,
                                              modelContext: modelContext) {
                RecipeView(recipe: recipe,
                           container: container)
            }
            else {
                ContentUnavailableView("Cannot load recipe",
                                       image: "x.circle")
            }
        }
        else {
            ContentUnavailableView("Cannot load route",
                                   image: "x.circle")
        }
    }
}

#Preview {
    let container = DataProvider.previewContainer()
    
    RecipeListNavigator(appModel: .init(), container: container)
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}
