//
//  FetchTask.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 8/23/23.
//

import Foundation

struct FetchTask {
    var people: [Person]
    var transactions: [Transaction]
    var foundShare: Bool
    init(people: [Person], transactions: [Transaction], foundShare: Bool) {
        self.people = people
        self.transactions = transactions
        self.foundShare = foundShare
    }
    init() {
        self.people = []
        self.transactions = []
        self.foundShare = false
    }
}
