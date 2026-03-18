//
//  KeywordListView.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//


import Foundation
import SwiftUI
import SwiftData
import OSLog

struct KeywordListView: View {
    @Environment(\.modelContext) var modelContext
    
    @Bindable var appModel: AppModel
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "KeywordListView")
    
    
    var body: some View {
        List {
            ForEach(appModel.keywords, id: \.id) { keyword in
                NavigationLink(value: keyword) {
                    VStack(alignment: .leading) {
                        Text(keyword.label)
                        
                    }
                }
            }
        }
        .toolbarRole(.navigationStack)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Keyword",
                       systemImage: "plus",
                       action: addKeyword)
                .labelStyle(.iconOnly)
                .buttonStyle(.glassProminent)
            }
        }
    }
    
    func addKeyword() {
        do {
            let k = Keyword()
            modelContext.insert(k)
            try modelContext.save()
        }
        catch let error {
            log.error("Failed to insert recipe with error: \(error.localizedDescription)")
        }
    }
    
}
