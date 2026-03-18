//
//  TagView.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//



import SwiftUI

struct TagView: View {
//    let token: SearchTokenValue
    let label: String
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    var icon: Image?
    var color: Color?
    
    
    init(label: String,
         cornerRadius: CGFloat = 12.0,
         backgroundColor: Color = Color.accentColor,
         foregroundColor: Color = Color.white) {
       
        self.label = label
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        HStack {
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

#Preview {
    TagView(label: "Veggies", cornerRadius: 12.0, backgroundColor: Color.accentColor, foregroundColor: Color.white)
}
