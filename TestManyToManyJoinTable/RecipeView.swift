//
//  RecipeView.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftUI

struct RecipeView: View {
    @Bindable var recipe: Recipe
    
    var body: some View {
        VStack {
            TextField("Title", text: $recipe.label)
        }
    }
}
