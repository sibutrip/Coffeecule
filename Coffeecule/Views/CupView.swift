//
//  CupSelectionView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import SwiftUI
import CloudKit

struct CupSelectionView: View {
    let person: Person
    var name: String {
        person.name
    }
    @Binding var icon: MugIcon
    @Binding var color: UserColor
    @State private var zstackSize: CGSize = .zero
    var body: some View {
        ChildSizeReader(size: $zstackSize) {
            ZStack {
                Image(icon.selectedImageBackground)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color("user.background"))
                Image(icon.selectedImage)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(color.colorName))
                
                Text(name)
                    .multilineTextAlignment(.center)
                    .font(.title.weight(.semibold))
                    .foregroundColor(Color("background"))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .offset(x: icon.offsetPercentage.0 * zstackSize.width / 2, y: icon.offsetPercentage.1 * zstackSize.height / 2)
                    .frame(maxWidth: icon.maxWidthPercentage * zstackSize.width)
            }
        }
    }
}

#Preview {
    CupSelectionView(person: Person(name: "cory", associatedRecord: CKRecord(recordType: "test")), icon: .constant(.mug), color: .constant(.purple))
}
