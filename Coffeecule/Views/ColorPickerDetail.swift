//
//  ColorPickerDetail.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import SwiftUI

struct ColorPickerDetail: View {
    @Environment(\.colorScheme) var colorScheme
    let color: UserColor
    @Binding var selectedColor: UserColor
    var body: some View {
        Group {
            if selectedColor == color {
                Circle()
                    .foregroundColor(Color(color.colorName))
            } else {
                Circle()
                    .foregroundColor(Color(color.colorName))
                    .overlay {
                        Circle()
                            .foregroundStyle(colorScheme == .light ? .white : .black)
                            .padding(5)
                    }
            }
        }
    }
}

#Preview {
    ColorPickerDetail(color: .purple, selectedColor: .constant(.purple))
}
