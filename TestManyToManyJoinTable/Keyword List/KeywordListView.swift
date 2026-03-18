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
import DataProvider


struct KeywordListView: View {
    @Environment(\.modelContext) var modelContext
    
    @Bindable var appModel: AppModel
    let container: ModelContainer
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "KeywordListView")
    
    init(appModel: AppModel, container: ModelContainer) {
        self.appModel = appModel
        self.container = container
    }
    
    var body: some View {
        List {
            if appModel.keywords.isEmpty {
                Text("Tap \(Image(systemName: "plus")) to create a new keyword.")
            }
            ForEach(appModel.keywords, id: \.id) { keyword in
                Button {
                    appModel.keywordPath.append(
                        KeywordListRoute.keywordRoute(keywordUUID: keyword.uuid)
                    )
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(keyword.label)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Spacer()
                            Image(systemName: "chevron.right")
                            Spacer()
                        }
                    }
                    .foregroundStyle(Color.primary)
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
        .onAppear {
            Task {
                do {
                    try await appModel.fetchAllKeywords(container: container)
                }
                catch let error {
                    log.error("Failed to fetch all recipes with error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func addKeyword() {
        do {
            let k = Keyword()
            modelContext.insert(k)
            try modelContext.save()
            
            appModel.keywordPath.append(
                KeywordListRoute.keywordRoute(keywordUUID: k.uuid)
            )
            Task {
                do {
                    try await appModel.fetchAllKeywords(container: container)
                }
                catch let error {
                    log.error("Cannot fetch all keywords: \(error.localizedDescription)")
                }
            }
        }
        catch let error {
            log.error("Failed to insert recipe with error: \(error.localizedDescription)")
        }
    }
    
}

#Preview {
    let container = DataProvider.previewContainer()
    
    KeywordListView(appModel: .init(), container: container)
        .modelContainer(container)
        .environment(\.modelContext, container.mainContext)
}
