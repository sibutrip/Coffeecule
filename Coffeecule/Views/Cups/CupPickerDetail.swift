//
//  CupPickerDetail.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import SwiftUI
import CloudKit

struct CupPickerDetail: View {
    let icon: MugIcon
    @Binding var selectedMugIcon: MugIcon
    @Binding var color: UserColor
    var isSelected: Bool {
        selectedMugIcon == icon
    }
    var body: some View {
        ZStack {
            if isSelected {
                Image(icon.selectedImageBackground)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color("user.background"))
                Image(icon.selectedImage)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(color.colorName))
            } else {
                Image(icon.imageBackground)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color("user.background"))
                Image(icon.image)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(color.colorName))
            }
        }
        .animation(.default, value: isSelected)
    }
}

#Preview {
    CupPickerDetail(icon: .disposable, selectedMugIcon: .constant(.mug), color: .constant(.orange))
}
