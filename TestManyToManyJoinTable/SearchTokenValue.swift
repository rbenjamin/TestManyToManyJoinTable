//
//  SearchTokenValue.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//



#if os(iOS)
import UIKit
#endif

import SwiftUI

enum SearchTokenValue: Sendable, Identifiable, Equatable, Hashable {
    case keyword(keyword: KeywordSendable)
//    case specialCategory(category: SpecialSearchFieldTokens)
    
    var id: String {
        if case .keyword(let keyword) = self {
            return keyword.uuid.uuidString
        }
        return "UISEARCHTOKEN-FAILURE <SearchTokenValue.id>"
    }
    
    
 
    var tokenColor: Color? {
        return nil
    }
    
    #if os(iOS)
    @MainActor
    var token: UISearchToken {
        if case .keyword(let keyword) = self {
            let token = UISearchToken(icon: nil, text: keyword.label)
            
            token.representedObject = self
            return token
        }
        return UISearchToken(icon: nil, text: "UISEARCHTOKEN-FAILURE <SearchTokenValue.token>")
    }
    #endif // os(iOS)
    
    var lowercasedLabel: String {
        if case .keyword(let keyword) = self {
            return keyword.lowercasedLabel
        }
        return "UISEARCHTOKEN-FAILURE <SearchTokenValue.lowercasedLabel>"
    }
    var label: String {
        if case .keyword(let keyword) = self {
            return keyword.label
        }
        return "UISEARCHTOKEN-FAILURE <SearchTokenValue.label>"
    }
}



