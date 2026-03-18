//
//  ContentView.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftUI
import SwiftData
import OSLog
import DataProvider

enum TabSelection: String, Hashable, RawRepresentable, Identifiable, CaseIterable {
    case recipes
    case keywords
    
    public var id: String {
        return self.rawValue
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tabSelection: TabSelection = .recipes
    @State private var model: AppModel = .init()
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "ContentView")
    let container: ModelContainer
    
    init(container: ModelContainer) {
        self.container = container
    }

    var body: some View {
        TabView(selection: $tabSelection) {
            
            Tab("Recipes",
                systemImage: "fork.knife",
                value: TabSelection.recipes) {
                
                RecipeListNavigator(appModel: model,
                                    container: container)
            }
            
            Tab("Keywords",
                systemImage: "tag",
                value: TabSelection.keywords) {
                
                KeywordListNavigator(appModel: model,
                                     container: container)
            }
        }
    }
    
}

#Preview {
    let container = DataProvider.previewContainer()
    
    ContentView(container: container)
        .modelContainer(container)
}
