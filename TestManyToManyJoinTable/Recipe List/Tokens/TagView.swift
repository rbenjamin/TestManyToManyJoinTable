//
//  TagView.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//



import SwiftUI

struct TagView: View {
    let token: SearchTokenValue
//    let label: String
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    let label: String
    var icon: Image?
    var color: Color?
    
    
    init(token: SearchTokenValue,
         cornerRadius: CGFloat,
         backgroundColor: Color = Color.accentColor,
         foregroundColor: Color = Color.white) {
       
        self.token = token
        self.label = token.label
        if let userIcon = token.userIcon {
            self.icon = userIcon
        }
        if let color = token.tokenColor {
            self.color = color
        }
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        HStack {
            #if os(iOS)
            if let icon {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(foregroundColor)
                    .frame(width: 22, height: 22)
            }
            #else
            if let icon {
                icon
                    .renderingMode(.template)
                    .imageScale(.small)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(foregroundColor)
            }
            #endif
            Text(label)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(foregroundColor)
        .frame(minWidth: 40)
        #if os(iOS)
        .frame(height: 22)
        #endif
        #if os(macOS)
        .frame(height: 20)
        #endif // os(macOS)
        #if os(iOS)
        .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
        #else
        .padding(EdgeInsets(top: 2, leading: 3, bottom: 2, trailing: 3))
        #endif
        .dynamicTypeSize(.xSmall ... .xxLarge)

        .background {
            (color ?? backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
