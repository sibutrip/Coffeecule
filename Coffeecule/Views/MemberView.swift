//
//  MemberView.swift
//  Coffeecule
//
//  Created by Zoe Cutler on 9/7/23.
//

import SwiftUI

#warning("Move to user model or wherever")
enum Icon: String {
    case espresso, latte, mug, disposable
    
    var image: String {
        self.rawValue
    }
    
    var imageBackground: String {
        self.rawValue + ".background"
    }
    
    var selectedImage: String {
        self.rawValue + ".selected"
    }
    
    var selectedImageBackground: String {
        self.rawValue + ".selected.background"
    }
    
    var isBuyingBadgeImage: String {
        self.rawValue + ".moneybadge"
    }
    
    var offsetPercentage: (Double, Double) {
        switch self {
        case .espresso:
            return (-0.07, 0.1)
        case .latte:
            return (-0.06, 0.2)
        case .mug:
            return (-0.06, 0.25)
        case .disposable:
            return (0, 0.2)
        }
    }
    
    var maxWidthPercentage: CGFloat {
        switch self {
        case .espresso:
            return 0.406
        case .latte:
            return 0.611
        case .mug:
            return 0.576
        case .disposable:
            return 0.481
        }
    }
}

#warning("Move to user model or wherever")
enum UserColor: String {
    case purple, teal, orange, pink
    
    var colorName: String {
        "user." + self.rawValue
    }
}

struct MemberView: View {
    var name: String
    var icon: Icon
    var color: UserColor
    var isSelected: Bool
    var isBuying: Bool
    
    @State private var zstackSize = CGSize.zero
    
    var body: some View {
        ChildSizeReader(size: $zstackSize) {
            ZStack {
                if isSelected {
                    Image(icon.selectedImageBackground)
                        .resizable()
                        .scaledToFit()
                    Image(icon.selectedImage)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(color.colorName))
                    
                    if isBuying {
                        Image(icon.isBuyingBadgeImage)
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    Image(icon.imageBackground)
                        .resizable()
                        .scaledToFit()
                    Image(icon.image)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(color.colorName))
                }
                
                Text(name)
                    .multilineTextAlignment(.center)
                    .font(.title.weight(.semibold))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .offset(x: icon.offsetPercentage.0 * zstackSize.width / 2, y: icon.offsetPercentage.1 * zstackSize.height / 2)
                    .frame(maxWidth: icon.maxWidthPercentage * zstackSize.width)
            }
        }
    }
}

struct MemberView_Previews: PreviewProvider {
    static var previews: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
            MemberView(name: "Zoe", icon: .latte, color: .purple, isSelected: false, isBuying: false)
            MemberView(name: "Tomothy Barbados", icon: .espresso, color: .orange, isSelected: true, isBuying: false)
            MemberView(name: "Cory", icon: .disposable, color: .teal, isSelected: true, isBuying: true)
            MemberView(name: "Kiana", icon: .mug, color: .pink, isSelected: false, isBuying: false)
            MemberView(name: "Telayne3334", icon: .disposable, color: .purple, isSelected: false, isBuying: false)
            MemberView(name: "Nick", icon: .espresso, color: .teal, isSelected: false, isBuying: false)
        }
    }
}
