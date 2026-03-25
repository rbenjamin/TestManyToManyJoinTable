//
//  ModelContext+Extended.swift
//  DataProvider
//
//  Created by Ben Davis on 3/25/26.
//


import SwiftData
import Foundation

public extension ModelContext {
  func existingModel<T>(for objectID: PersistentIdentifier)
    throws -> T? where T: PersistentModel {
    if let registered: T = registeredModel(for: objectID) {
        return registered
    }
        
    let fetchDescriptor = FetchDescriptor<T>(
        predicate: #Predicate<T> {
        $0.persistentModelID == objectID
    })
    
    return try fetch(fetchDescriptor).first
  }
}
