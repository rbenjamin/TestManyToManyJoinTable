// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftData
import CloudKit
import Foundation
import OSLog

public final class DataProvider: Sendable {
    public static let shared = DataProvider()
    
    /// Set your own cloud kit database here (in addition to the setup in `Signing & Capabilities`, or remove the `cloudKitDatabase:` argument in `sharedModelContainer` and use a local database.
    private let database: ModelConfiguration.CloudKitDatabase = .private("com.yoururl.yourapp")
    
    public let sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration: ModelConfiguration = .init("TestManyToManyJoinTable", schema: schema, allowsSave: true, cloudKitDatabase: database)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            Logger(subsystem: Bundle.main.bundleIdentifier!, category: "DataProvider").error("Could not create ModelContainer: \(error.localizedDescription)")

            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    public static func previewContainer() -> ModelContainer {
      let schema = Schema(CurrentScheme.models)
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
      do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
      } catch {
        fatalError("Could not create ModelContainer: \(error)")
      }
    }
}
