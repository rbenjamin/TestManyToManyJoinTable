//
//  TokenFlowOverlay.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//



import SwiftUI
#if os(iOS)
import UIKit
#endif
import UserInterfaceExtensions
import Pow

struct TokenFlowOverlay: View {
    @Environment(\.verticalSizeClass) var verticalSize
    
    @Binding private var filteredTokens: [SearchTokenValue]
    @Binding private var visible: Bool
    #if os(iOS)
    @Binding var focused: Bool
    #else
    @FocusState.Binding var focused: Bool
    #endif
    let tokenButtonPressed: (_ token: SearchTokenValue) -> Void
    let filterCancelled: () -> Void
    
    #if os(iOS)
    init(filteredTokens: Binding<[SearchTokenValue]>,
         visible: Binding<Bool>,
         focused: Binding<Bool>,
 
         tokenButtonPressed: @escaping (_ token: SearchTokenValue) -> Void,
         filterCancelled: @escaping () -> Void) {
        _filteredTokens = filteredTokens
        _visible = visible
        self.tokenButtonPressed = tokenButtonPressed
        self.filterCancelled = filterCancelled
        _focused = focused
    }
    #else
    init(filteredTokens: Binding<[SearchTokenValue]>,
         visible: Binding<Bool>,
         focused: FocusState<Bool>.Binding,
         tokenButtonPressed: @escaping (_ token: SearchTokenValue) -> Void,
         filterCancelled: @escaping () -> Void) {
        _filteredTokens = filteredTokens
        _visible = visible
        self.tokenButtonPressed = tokenButtonPressed
        self.filterCancelled = filterCancelled
        _focused = focused
    }
    #endif
    
    var horizontalFlowStack: some View {
        LazyVStack(alignment: .leading) {
            Divider()
            Text("User Tags")
                .font(.callout)
                .fontWeight(.semibold)
                .padding(.top, 2)
            Divider()
            self.userTagsFlow
            Divider()
        }
    }
    
    var userTagsFlow: some View {
        VStack {
//            HFlow(alignment: .top) {
            WrappingHStack(alignment: .top) {
                ForEach(self.filteredTokens, id: \.id) { token in
                    Button {
                        self.tokenButtonPressed(token)
                    } label: {
                        
                        TagView(label: token.label, cornerRadius: 12.0)
                     
                    }
                    .buttonStyle(.borderless)
                    #if os(macOS)
                    .pointerStyle(.link)
                    #endif
                    #if os(iOS)
                    .transition(.scale.combined(with:.opacity))
                    #else
                    .transition(.slide.combined(with: .opacity))
                    #endif
                    .accessibilityHint(Text("Filter search for recipes with the tag \(token.label)"))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    
    
    @ViewBuilder
    var newTokenView: some View {
        #if os(iOS)
        ScrollView(.vertical) {
            horizontalFlowStack
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .ignoresSafeArea()
        .background {
            Rectangle().fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
        .safeAreaPadding(EdgeInsets(top: 0, leading: 0, bottom: 44, trailing: 0))

        #else
        List {
            Section("User Tags") {
                self.userTagsFlow
                    .listRowSeparator(.hidden, edges: .all)
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            Rectangle().fill(.ultraThinMaterial)
        }
        #endif
    }

    var body: some View {
        self.newTokenView
        #if os(iOS)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}

#Preview {
    TokenFlowOverlay(filteredTokens: .constant([]), visible: .constant(true), focused: .constant(true)) { _ in
        
    } filterCancelled: {
        
    }

}
