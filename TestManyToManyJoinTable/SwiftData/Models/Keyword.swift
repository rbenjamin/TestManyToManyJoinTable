//
//  Keyword.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftData
import Foundation

@Model
final class Keyword {
    var label: String = ""
    var timestamp: Date = Date()
    var uuid: UUID = UUID()
    @Relationship(deleteRule: .nullify, inverse: \Recipe.keywords)
    var recipes: [Recipe]? = []
    
    init() {
        
    }
}

struct KeywordSendable: Codable, Sendable, Equatable, Comparable, Identifiable, Hashable {
    let timestamp: Date
    let uuid: UUID
    let label: String
    let lowercasedLabel: String
    let recipes: [PersistentIdentifier]
    let persistentModelID: PersistentIdentifier
    
    var id: UUID {
        return uuid
    }
    
    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }

    init(keyword: Keyword) {
        self.timestamp = keyword.timestamp
        self.uuid = keyword.uuid
        self.label = keyword.label
        self.lowercasedLabel = keyword.label.lowercased()
        self.persistentModelID = keyword.persistentModelID
        self.recipes = keyword.recipes?.compactMap(\.persistentModelID) ?? []
    }
}

extension Keyword {
    static func fetchKeyword(keywordID: PersistentIdentifier, modelContext: ModelContext) throws -> Keyword? {
        let predicate = #Predicate<Keyword> { k in
            return k.persistentModelID == keywordID
        }
        return try modelContext.fetch(FetchDescriptor<Keyword>(predicate: predicate)).first
    }
}
