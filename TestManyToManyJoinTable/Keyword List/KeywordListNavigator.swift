//
//  KeywordListNavigator.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import Foundation
import SwiftUI
import SwiftData
import DataProvider
import OSLog

struct KeywordListNavigator: View {
    @Environment(\.modelContext) var modelContext
    @Bindable var appModel: AppModel
    let container: ModelContainer
    
    init(appModel: AppModel, container: ModelContainer) {
        self.appModel = appModel
        self.container = container
    }
    
    var body: some View {
        NavigationStack(path: $appModel.keywordPath) {
            KeywordListView(appModel: appModel, container: container)
                .navigationDestination(for: KeywordListRoute.self) { recipe in
                    // fetch the real recipe
                    keywordView(for: recipe)
                }
                .navigationTitle(Text("All Tags"))
        }
        .tabBarMinimizeBehavior(.automatic)

    }
    
    @ViewBuilder
    func keywordView(for route: KeywordListRoute) -> some View {
        if case .keywordRoute(let keywordUUID) = route {
            if let keyword = try? Keyword.fetch(keywordUUID: keywordUUID, modelContext: modelContext) {
                KeywordView(keyword: keyword)
            } else {
                ContentUnavailableView("Cannot load recipe",
                                       image: "x.circle")
            }
        } else {
            ContentUnavailableView("Cannot load route",
                                   image: "x.circle")
        }
    }
}

#Preview {
    let container = DataProvider.previewContainer()
    
    KeywordListNavigator(appModel: .init(), container: container)
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}
