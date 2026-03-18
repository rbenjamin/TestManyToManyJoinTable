//
//  KeywordSendable.swift
//  DataProvider
//
//  Created by Ben Davis on 3/18/26.
//
import Foundation
import SwiftData

public struct KeywordSendable: Codable, Sendable, Equatable, Comparable, Identifiable, Hashable {
    public let timestamp: Date
    public let uuid: UUID
    public let label: String
    public let lowercasedLabel: String
    public let recipes: [PersistentIdentifier]
    public let persistentModelID: PersistentIdentifier
    
    public var id: UUID {
        return uuid
    }
    
    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.persistentModelID == rhs.persistentModelID &&
            lhs.label == rhs.label
    }

    public init(keyword: Keyword) {
        self.timestamp = keyword.timestamp
        self.uuid = keyword.uuid
        self.label = keyword.label
        self.lowercasedLabel = keyword.label.lowercased()
        self.persistentModelID = keyword.persistentModelID
        self.recipes = keyword.recipes?.compactMap(\.persistentModelID) ?? []
    }
}
