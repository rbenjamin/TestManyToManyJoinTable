//
//  RecipeKeywordIndexSendable.swift
//  DataProvider
//
//  Created by Ben Davis on 3/18/26.
//

import Foundation
import SwiftData

public struct RecipeKeywordIndexSendable: Codable, Sendable, Equatable, Comparable, Identifiable, Hashable {
    public let recipeID: UUID
    public let keywordID: UUID
    
    public let persistentModelID: PersistentIdentifier
    public let uuid: UUID
    public let timestamp: Date
    
    public var id: UUID {
        return uuid
    }
    
    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
    public init(index: RecipeKeywordIndex) {
        self.recipeID = index.recipeID
        self.keywordID = index.keywordID
        self.persistentModelID = index.persistentModelID
        self.uuid = index.uuid
        self.timestamp = index.timestamp
    }
}
