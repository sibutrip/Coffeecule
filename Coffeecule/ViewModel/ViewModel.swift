//
//  ViewModel.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit
//import UIKit
import SwiftUI

@MainActor
class ViewModel: ObservableObject {
    
    let repository = Repository.shared
    let personService = PersonService()
    let transactionService = TransactionService()
    
    enum State: String, Equatable, LocalizedError {
        case loading
        case loaded
        case noPermission = "app does not have permission to use your iCloud"
        case nameFieldEmpty = "name field is empty"
        case nameAlreadyExists = "name already exists in this coffeecule"
        case noShareFound = "could not find cule. make sure you open an invite the owner has shared"
        case noSharedContainerFound = "internal error: could not find shared data"
        case culeAlreadyExists = "cannot create cule. you already have one"
    }
    
    @Published public var participantName: String = ""
    @Published var state: State = .loading {
        didSet {
            print(self.state)
        }
    }
    @Published var relationships: [Relationships] = []
    @Published var currentBuyer = Person()
    @Published var displayedDebts: [Person:Int] = [:]
    @Published var hasShare = false {
        didSet {
            print("has share is \(hasShare)")
        }
    }
    
    init() {
        Task {
            do {
                try await self.initialize()
            } catch {
                print(error)
            }
        }
    }
}

