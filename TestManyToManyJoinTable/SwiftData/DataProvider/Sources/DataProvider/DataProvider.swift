// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftData
import CloudKit
import Foundation
import OSLog

public final class DataProvider: Sendable {
    public static let shared = DataProvider()
    
    public let sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration: ModelConfiguration = .init("TestManyToManyJoinTable", schema: schema, allowsSave: true, cloudKitDatabase: .private("iCloud.com.pinwheeldevinc.testing.TestManyToManyJoinTable"))

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
