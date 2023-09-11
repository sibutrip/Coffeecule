//
//  MugIcon.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import Foundation

enum MugIcon: String, CaseIterable {
    case mug, espresso, latte, disposable
    
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
    
    var emptyBadgeImage: String {
        self.rawValue + ".emptybadge"
    }
    
    var imageDescription: String {
        switch self {
        case .mug:
            return "Coffee mug."
        case .espresso:
            return "Espresso cup."
        case .latte:
            return "Latte mug."
        case .disposable:
            return "Paper cup."
        }
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
