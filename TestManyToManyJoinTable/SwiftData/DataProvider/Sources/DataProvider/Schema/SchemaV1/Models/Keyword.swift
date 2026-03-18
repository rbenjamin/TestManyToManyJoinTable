//
//  Keyword.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftData
import Foundation

extension SchemaV1 {
    
    @Model
    public final class Keyword {
        public var label: String = ""
        public var timestamp: Date = Date()
        public var uuid: UUID = UUID()
        
        @Relationship(deleteRule: .nullify)
        public var recipes: [Recipe]? = []
        
        public init() {
            
        }
    }
}
