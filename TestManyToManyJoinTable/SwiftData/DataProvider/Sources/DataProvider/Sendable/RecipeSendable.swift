//
//  RecipeSendable.swift
//  DataProvider
//
//  Created by Ben Davis on 3/18/26.
//

import Foundation
import SwiftData


public struct RecipeSendable: Codable, Sendable, Equatable, Comparable, Identifiable, Hashable {
    public let timestamp: Date
    public let uuid: UUID
    public let label: String
    public let keywords: [PersistentIdentifier]
    public let keywordsLabel: String
    public let persistentModelID: PersistentIdentifier
    
    public var id: UUID {
        return uuid
    }
    
    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.persistentModelID == rhs.persistentModelID &&
            lhs.label == rhs.label &&
            lhs.keywordsLabel == rhs.keywordsLabel
    }
    
    public init(recipe: Recipe) {
        self.timestamp = recipe.timestamp
        self.uuid = recipe.uuid
        self.label = recipe.label
        self.persistentModelID = recipe.persistentModelID
        let words = recipe.keywords
        
        self.keywords = words?.compactMap(\.persistentModelID) ?? []
        self.keywordsLabel = words?.compactMap(\.label).joined(separator: ", ") ?? ""
    }
}
