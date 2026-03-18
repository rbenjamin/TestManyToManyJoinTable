//
//  Keyword+Extended.swift
//  DataProvider
//
//  Created by Ben Davis on 3/18/26.
//

import SwiftData
import Foundation



public extension Keyword {
    static func fetch(keywordID: PersistentIdentifier, modelContext: ModelContext) throws -> Keyword? {
        let predicate = #Predicate<Keyword> { k in
            return k.persistentModelID == keywordID
        }
        return try modelContext.fetch(FetchDescriptor<Keyword>(predicate: predicate)).first
    }
    
    static func fetch(keywordUUID: UUID, modelContext: ModelContext) throws -> Keyword? {
        let predicate = #Predicate<Keyword> { k in
            return k.uuid == keywordUUID
        }
        return try modelContext.fetch(FetchDescriptor<Keyword>(predicate: predicate)).first
    }
}

