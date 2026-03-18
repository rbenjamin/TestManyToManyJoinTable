//
//  RecipeKeywordIndex.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//
import Foundation
import SwiftData

extension SchemaV1 {
    
    @Model
    public final class RecipeKeywordIndex {
        
        public var recipeID: UUID = UUID()
        
        public var keywordID: UUID = UUID()
        
        public var uuid: UUID = UUID()
        
        public var timestamp: Date = Date()
        
        public init(recipeID: UUID, keywordID: UUID) {
            self.recipeID = recipeID
            self.keywordID = keywordID
        }
    }
}
