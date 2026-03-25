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
            .onDelete { indexSet in
                Task {
                    await delete(with: indexSet)
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
                print("fetching all keywords")
                do {
                    try await appModel.fetchAllKeywords(container: container)
                }
                catch let error {
                    log.error("Failed to fetch all recipes with error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func delete(with indexSet: IndexSet) async {
        var ids: Set<UUID> = []
        for index in indexSet {
            ids.insert(appModel.keywords[index].uuid)
        }
        do {
            let handler = DataHandler(modelContainer: container)
            try await handler.deleteKeywords(uuids: ids)
        }
        catch let error {
            log.error("[delete(with:)]: Failed to delete recipes [count: \(ids.count)]. Error: \(error.localizedDescription)")
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
