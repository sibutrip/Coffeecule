//
//  AppAccess.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/28/23.
//

import Foundation

class AppAccess: ObservableObject {
    @Published var accessedFromShare = false
    init(accessedFromShare: Bool) {
        self.accessedFromShare = accessedFromShare
        print("FDsnfuidsfoids")
    }
}
