//
//  RecipeKeywordIndex.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//
import Foundation
import SwiftData


@Model
final class RecipeKeywordIndex {

    @Attribute(.indexed)
    var recipeID: PersistentIdentifier

    @Attribute(.indexed)
    var keywordID: PersistentIdentifier
    
    var uuid: UUID = UUID()
    
    var timestamp: Date = Date()

    init(recipeID: PersistentIdentifier, keywordID: PersistentIdentifier) {
        self.recipeID = recipeID
        self.keywordID = keywordID
    }
}

struct RecipeKeywordIndexSendable: Codable, Sendable, Equatable, Comparable, Identifiable, Hashable {
    let recipeID: PersistentIdentifier
    let keywordID: PersistentIdentifier
    
    let persistentModelID: PersistentIdentifier
    let uuid: UUID
    let timestamp: Date
    
    public var id: UUID {
        return uuid
    }
    
    init(index: RecipeKeywordIndex) {
        self.recipeID = index.recipeID
        self.keywordID = index.keywordID
        self.persistentModelID = index.persistentModelID
        self.uuid = index.uuid
        self.timestamp = index.timestamp
    }
}
