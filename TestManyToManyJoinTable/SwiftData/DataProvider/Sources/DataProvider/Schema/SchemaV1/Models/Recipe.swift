//
//  Recipe.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import Foundation
import SwiftData

extension SchemaV1 {
    
    @Model
    public final class Recipe {
        public var timestamp: Date = Date()
        public var uuid: UUID = UUID()
        public var label: String = ""
        
        @Relationship(deleteRule: .nullify, inverse: \Keyword.recipes)
        public var keywords: [Keyword]? = []

        public init() {
        }
    }
}
