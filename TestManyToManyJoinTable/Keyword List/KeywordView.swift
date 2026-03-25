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
    
    var body: some View {
        VStack {
            TextField("Keyword Label", text: $keyword.label)
                .focused($textFocus)
                .onChange(of: textFocus) { _, newValue in
                    if newValue == false {
                        saveContext()
                    }
                }
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .tabViewBottomAccessory(content: {
            Circle().fill(Color.red)
        })
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
}



#Preview {
    let container = DataProvider.previewContainer()
    let k = Keyword()
    container.mainContext.insert(k)
    
    return KeywordView(keyword: k)
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}
