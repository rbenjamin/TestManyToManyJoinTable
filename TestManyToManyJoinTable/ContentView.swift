//
//  ContentView.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftUI
import SwiftData
import OSLog

enum TabSelection: String, Hashable, RawRepresentable, Identifiable, CaseIterable {
    case recipes
    case keywords
}



struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tabSelection: TabSelection = .recipes
    @State private var model: AppModel = .init()
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "ContentView")
    let container: ModelContainer

    var body: some View {
        TabView(selection: $tabSelection) {
            
            Tab(value: TabSelection.recipes) {
                RecipeListNavigator(appModel: model, container: container)
            }
            
            Tab(value: TabSelection.keywords) {
                KeywordListNavigator(appModel: model)
            }
        }
        .task {
            do {
                try await model.fetchAllRecipes(container: container)
                try await model.fetchAllKeywords(container: container)
            }
            catch let error {
                log.error("Failed to fetch either keywords or recipes. Error Received: \(error.localizedDescription)")
            }
        }
    }

    private func addRecipe() {
        withAnimation {
            let newItem = Recipe(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteRecipes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(recipes[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
