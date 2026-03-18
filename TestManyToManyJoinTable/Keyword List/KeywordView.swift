//
//  KeywordView.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftUI
import Foundation

struct KeywordView: View {
    @Bindable var keyword: Keyword
    
    var body: some View {
        VStack {
            TextField("Keyword Label", text: $keyword.label)
        }
    }
}

