//
//  TokenSearchBarUIController.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//

import SwiftData
import SwiftUI
import UIKit
import OSLog


@Observable
final class TokenSearchBarUIController {
    
    var searchText: String
//    var tokens: [SearchTokenValue]
    var tokens: Set<SearchTokenValue>
    var showTokenList: Bool = false
    var focused: Bool = false
    var selectedTokensReset: Bool = false
    var returnKeyPressed: Bool = false
    var prompt: NSAttributedString?
    
    @ObservationIgnored var isUpdating: Bool = false
    @ObservationIgnored var parentShouldUpdateView: Bool = false
    @ObservationIgnored var viewIsDisappearing: Bool = false
    
    init(searchText: String, tokens: Set<SearchTokenValue>) {
        self.searchText = searchText
        self.tokens = tokens
        
    }
}

@MainActor
struct TokenSearchBarUI: UIViewRepresentable {
    
    typealias UIViewType = UISearchTextField
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let haptic = UISelectionFeedbackGenerator()
    let toolbarBackground: UIColor
    let toolbarForeground: UIColor

    let controller: TokenSearchBarUIController
    let log = Logger(subsystem: "TestManyToManyJoinTable", category: "TokenSearchBarUI")
    
    init(controller: TokenSearchBarUIController, toolbarBackground: UIColor, toolbarForeground: UIColor) {
        self.controller = controller
        self.toolbarBackground = toolbarBackground
        self.toolbarForeground = toolbarForeground
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator {
            return controller.isUpdating
        } searchBarShouldBeginEditing: { _ in
            return true
        } searchBarDidBeginEditing: { _ in
            controller.focused = true
        } searchTextChanged: { searchField, searchText in
        
            guard let searchText else { return }
            
            if controller.searchText != searchText {
                self.controller.searchText = searchText
            }
            
            let fieldTokens: Set<SearchTokenValue> = Set(searchField.tokens.compactMap({
                return $0.representedObject as? SearchTokenValue
            }))
            
            if !searchText.hasPrefix("#") {
                self.controller.showTokenList = false
                self.controller.selectedTokensReset.toggle()
            } else {
                self.controller.showTokenList = true
                self.controller.focused = true

            }
            
            if  self.controller.tokens != fieldTokens {
                self.controller.tokens = fieldTokens
            }
            
        } textFieldShouldClear: { textField in
            controller.selectedTokensReset.toggle()
            haptic.selectionChanged()
            return true
        } returnKeyPressed: {
            controller.returnKeyPressed.toggle()
        }

    }
    
    func makeUIView(context: Context) -> UISearchTextField {

        // Search Bar Config
        let searchBar = UISearchTextField(frame: .zero, primaryAction: .init(handler: { _ in
            self.controller.focused = false
        }))
        searchBar.text = controller.searchText
        
        searchBar.delegate = context.coordinator
        searchBar.placeholder = nil
        
        // Search Text Field Config
        searchBar.textColor = toolbarForeground
        searchBar.keyboardType = .twitter
        searchBar.attributedPlaceholder = self.controller.prompt
        
        if controller.tokens.isEmpty == false {
            searchBar.tokens = controller.tokens.map({ $0.token })
            
        }
        searchBar.tokenBackgroundColor = UIColor(Color.accentColor)
        searchBar.delegate = context.coordinator
        searchBar.minimumContentSizeCategory = .extraSmall
        searchBar.maximumContentSizeCategory = .extraExtraExtraLarge
   
        searchBar.addTarget(context.coordinator, action: #selector(Coordinator.searchTextChanged(sender:)), for: .editingChanged)
      
        /// In iOS 26, the search bar is on the bottom of the view (rather than at the top) -- so we place the done button in alignment with sort and text field. See `RecipeListView.searchBar`
        if #unavailable(iOS 26) {
            searchBar.inputAccessoryView = {
                let bar = UIToolbar()
                
                //            if #unavailable(iOS 26) {
                let doneButton = UIBarButtonItem(systemItem: .done,
                                                 primaryAction: .init(handler: { _ in
                    controller.focused = false
                }))
                
                bar.items = [doneButton, UIBarButtonItem(systemItem: .flexibleSpace)]
                let compactHeight: CGFloat = 32
                let regularHeight: CGFloat = 44
                
                bar.frame.size.height = verticalSizeClass == .compact ? compactHeight : regularHeight
                log.debug("bar setup: frame.size.height: \(bar.frame.size.height)")
                return bar
            }()
        }

        return searchBar

    }
    
    func updateUIView(_ searchBar: UISearchTextField, context: Context) {
            searchBar.attributedPlaceholder = self.controller.prompt
        
        if searchBar.text != controller.searchText {
            controller.isUpdating = true
            log.debug("updating selectedTextRange: searchBar.text: \(searchBar.text ?? "<nil>") controller.searchText: \(controller.searchText)")
            
            searchBar.text = controller.searchText
            let endOfText = searchBar.endOfDocument
            if let range = searchBar.textRange(
                from: endOfText,
                to: endOfText
            ) {
                searchBar.selectedTextRange = range
            }
            controller.isUpdating = false
        }
        
        if controller.tokens.isEmpty == false {
            controller.isUpdating = true
            let tokens = controller.tokens.map({ $0.token })
            
            searchBar.tokens = tokens
            
            controller.isUpdating = false
        }
        
        if controller.focused && !searchBar.isFirstResponder {
            DispatchQueue.main.async {
                searchBar.becomeFirstResponder()
            }
        }
        else if !controller.focused && searchBar.isFirstResponder {
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
        
//        searchBar.sizeToFit()
    }
    
    final class Coordinator: NSObject, UISearchTextFieldDelegate {
        let parentIsUpdating: () -> Bool
        let searchBarShouldBeginEditing: ((UITextField) -> Bool)
        let searchBarDidBeginEditing: ((UITextField) -> Void)
        let searchTextChanged: (UISearchTextField, String?) -> Void
        let textFieldShouldClear: (UITextField) -> Bool
        let returnKeyPressed: () -> Void

        init(parentIsUpdating: @escaping () -> Bool,
             searchBarShouldBeginEditing: @escaping (UITextField) -> Bool,
             searchBarDidBeginEditing: @escaping (UITextField) -> Void,
             searchTextChanged: @escaping (UISearchTextField, String?) -> Void,
             textFieldShouldClear: @escaping (UITextField) -> Bool,
             returnKeyPressed: @escaping () -> Void) {
            
            self.parentIsUpdating = parentIsUpdating
            self.searchBarShouldBeginEditing = searchBarShouldBeginEditing
            self.searchBarDidBeginEditing = searchBarDidBeginEditing
            self.searchTextChanged = searchTextChanged
            self.textFieldShouldClear = textFieldShouldClear
            self.returnKeyPressed = returnKeyPressed
            
        }
        
        deinit {
            print("💥 TokenSearchBarUI Coordinator deinit")
        }
        
        @objc
        func searchTextChanged(sender: UISearchTextField) {
            guard parentIsUpdating() == false else { return }
            searchTextChanged(sender, sender.text)
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            return searchBarShouldBeginEditing(textField)

        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            searchBarDidBeginEditing(textField)
        }
        
//        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//            guard parentIsUpdating() == false else { return }
//            
//            return searchTextChanged(textField, range, string)
//        }
        
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            return textFieldShouldClear(textField)
            
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            returnKeyPressed()
            return true
        }
        
        
        /*
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBarDidBeginEditing(searchBar)
        }
        
        func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
            return searchBarShouldBeginEditing(searchBar)
        }
         
        */
        
 
    }
}

