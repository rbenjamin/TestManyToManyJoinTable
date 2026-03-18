//
//  TestManyToManyJoinTableApp.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftUI
import SwiftData

@main
struct TestManyToManyJoinTableApp: App {
    let dataProvider = DataProvider.shared


    var body: some Scene {
        WindowGroup {
            ContentView(container: dataProvider.sharedModelContainer)
        }
        .modelContainer(dataProvider.sharedModelContainer)
    }
}
