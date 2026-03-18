//
//  KeywordListNavigator.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import Foundation
import SwiftUI
import SwiftData
import OSLog

struct KeywordListNavigator: View {
    @Environment(\.modelContext) var modelContext
    let appModel: AppModel
    
    var body: some View {
        NavigationStack {
            KeywordListView(appModel: appModel)
                .navigationDestination(for: KeywordSendable.self) { recipe in
                    // fetch the real recipe
                    keywordView(for: recipe)
                }
        }
    }
    
    @ViewBuilder
    func keywordView(for sendable: KeywordSendable) -> some View {
        if let keyword = Keyword.fetch(
            recipeID: sendable.persistentModelID,
            modelContext: modelContext
        ) {
            KeywordView(keyword: keyword)
        }
        else {
            ContentUnavailableView("Cannot load keyword", image: "x.circle")
        }
    }
}
