//
//  ViewModel.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit
import UIKit
import SwiftUI

@MainActor
class ViewModel: ObservableObject {
    
    @AppStorage("hasCoffeecule") var hasCoffeecule = false
    
    let repository = Repository.shared
    let personService = PersonService()
    let transactionService = TransactionService()
    
    enum State: Equatable {
        case loading, loaded, noCoffeecule, noPermission, error
    }
    
    @Published public var participantName: String = ""
    @Published public var allRecords = [CKRecord]()
    @Published var state: State = .loading
    @Published var people: [Person] = []
    @Published var currentBuyer = Person(name: "nobody")
    @Published var displayedDebts: [Person:Int] = [:]
    
    init() {
        self.state = .loading
        Task {
            do {
                self.participantName = try await repository.fetchiCloudUserName()
            } catch {
                print(error)
            }
        }
        self.state = .loaded
    }
}

