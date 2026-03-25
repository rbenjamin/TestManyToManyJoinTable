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
import CoreData
import Combine


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
        .onDisappear {
            model.dateLastOpened = Date()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
                .receive(on: RunLoop.main),
                   perform: { notification in
            // On new installs where the user already had a populated database, we need to reload the list after cloud kit and swift data setup is complete.
            model.ckNotificationEventRecieved(notification)
        })
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { notification in
            reloadOnSave(notification: notification)
        }
    }
    
    func objectNeedsReload(
        userInfo: [AnyHashable : Any],
        key: AnyHashable
    ) {
        
        if let recipeID = (userInfo[key] as? [PersistentIdentifier])?.first,
            let _ = try? Recipe.fetch(
                recipeID: recipeID,
                modelContext: modelContext
            ) {
            model.reloadRecipes.toggle()
        } else if let keywordID = (userInfo[key] as? [PersistentIdentifier])?.first, let _ = try? Keyword.fetch(keywordID: keywordID, modelContext: modelContext) {
            model.reloadKeywords.toggle()
        }
    }
    
    func reloadOnSave(notification: Notification) {
        if let userInfo = notification.userInfo {
            for key in userInfo.keys {
                guard let keyString = key as? String,
                      let realKey = ModelContext.NotificationKey.init(rawValue: keyString) else {
                    continue
                }
                if case .deletedIdentifiers = realKey {
                    objectNeedsReload(userInfo: userInfo,
                                      key: key)
                } else if case .insertedIdentifiers = realKey {
                    objectNeedsReload(userInfo: userInfo,
                                      key: key)
                } else if case .updatedIdentifiers = realKey {
                    objectNeedsReload(userInfo: userInfo,
                                      key: key)
                }
            }
        }
    }
    
}

#Preview {
    let container = DataProvider.previewContainer()
    
    ContentView(container: container)
        .modelContainer(container)
}
