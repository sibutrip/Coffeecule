//
//  RelationshipWebDetail.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/14/23.
//

import SwiftUI

struct RelationshipWebDetail: View {
    let relationship: Relationship
    var name: String { relationship.name }
    var person: Person {
        relationship.person
    }
    var icon: MugIcon {
        person.mugIcon
    }
    var userColor: UserColor {
        person.userColor
    }
    var isSelected: Bool {
        relationship.isPresent
    }
    @State private var textSize: CGSize = .zero
    var body: some View {
        HStack {
            ZStack {
                Image(isSelected ? icon.selectedImageBackground : icon.imageBackground)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color("user.background"))
                Image(isSelected ? icon.selectedImage : icon.image)
                    .resizable()
                    .frame(width: textSize.height, height: textSize.height)
                    .foregroundColor(Color(userColor.colorName))
            }
            ChildSizeReader(size: $textSize) {
                Text(name)
                    .fontWeight(isSelected ? .black : .regular)
                    .font(.title2)
//                    .padding(.vertical)
                    .foregroundStyle(Color(person.userColor.colorName))
            }
        }
    }
}

#Preview {
    RelationshipWebDetail(relationship: Relationship(Person()))
}
