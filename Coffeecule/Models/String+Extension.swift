//
//  String+Extension.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import Foundation

extension String {
    var userColor: UserColor {
        if self == "purple" {
            return .purple
        } else if self == "teal" {
            return .teal
        } else if self == "orange" {
            return .orange
        } else if self == "pink" {
            return .teal
        } else {
            return .purple
        }
    }
    
    var mugIcon: MugIcon {
        if self == "espresso" {
            return .espresso
        } else if self == "latte" {
            return .latte
        } else if self == "mug" {
            return .mug
        } else if self == "disposable" {
            return .disposable
        } else {
            return .mug
        }
    }
}
