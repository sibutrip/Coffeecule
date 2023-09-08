//
//  UserColor.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import Foundation

enum UserColor: String, CaseIterable {
    case purple, teal, orange, pink
    
    var colorName: String {
        "user." + self.rawValue
    }
}
