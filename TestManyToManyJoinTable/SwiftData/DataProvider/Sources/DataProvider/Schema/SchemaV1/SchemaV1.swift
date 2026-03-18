//
//  SchemaV1.swift
//  DataProvider
//
//  Created by Ben Davis on 3/18/26.
//

import SwiftData

public enum SchemaV1: VersionedSchema {
  public static var versionIdentifier: Schema.Version {
    .init(1, 0, 0)
  }

  public static var models: [any PersistentModel.Type] {
      [
        Recipe.self,
        Keyword.self,
        RecipeKeywordIndex.self,
      ]
  }
}
