//
//  DataProvider.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftData

public final class DataProvider: Sendable {
    public static let shared = DataProvider()
    
    public let sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        
        let modelConfiguration: ModelConfiguration = .init("TestManyToManyJoinTable", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: .identifier("com.pinwheeldevinc.testing.TestManyToManyJoinTable"), cloudKitDatabase: .private("iCloud.com.pinwheeldevinc.testing.TestManyToManyJoinTable"))

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            Logger(subsystem: Bundle.main.bundleIdentifier!, category: "DataProvider").error("Could not create ModelContainer: \(error.localizedDescription)")

            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    func previewContainer() -> ModelContainer {
      let schema = Schema(CurrentScheme.models)
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
      do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
      } catch {
        fatalError("Could not create ModelContainer: \(error)")
      }
    }
}
